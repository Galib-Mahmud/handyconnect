// lib/core/endpoint/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../route/route_name.dart';
import '../local_storage/user_info.dart';
import 'api_endpoint.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({required this.baseUrl, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // ─── Default headers (no auth) ────────────────────────────────────
  final Map<String, String> _defaultHeaders = {
    "Accept": "application/json",
    "Content-Type": "application/json",
  };

  // ─── URL Builder ──────────────────────────────────────────────────
  String _buildUrl(String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }

  // ─── Auth Header ──────────────────────────────────────────────────
  // Reads token from in-memory cache — SYNCHRONOUS, zero async gap.
  // UserInfo.init() in main() guarantees the cache is populated before
  // any controller's onInit() fires.
  Map<String, String> _authHeaders() {
    final token = UserInfo.getAccessTokenSync();
    return {
      ..._defaultHeaders,
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  bool _isAuthEndpoint(String endpoint) {
    return endpoint.contains('/auth/login/') ||
           endpoint.contains('/auth/refresh/') ||
           endpoint.contains('/auth/google/') ||
           endpoint.contains('/auth/apple/') ||
           endpoint.contains('/auth/register/') ||
           endpoint.contains('/auth/verify-otp/');
  }

  // ─── Token Refresh on 401 ─────────────────────────────────────────
  static Completer<bool>? _refreshCompleter;

  static Future<bool> refreshToken({
    http.Client? client,
    String baseUrl = ApiEndpoint.baseUrl,
  }) async {
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    final httpClient = client ?? http.Client();
    try {
      final refresh = UserInfo.getRefreshTokenSync();
      if (refresh == null || refresh.isEmpty) {
        print('⚠️ [AUTH REFRESH] No refresh token found');
        await _onSessionExpired();
        completer.complete(false);
        _refreshCompleter = null;
        return false;
      }

      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final refreshUrl = Uri.parse('$base/auth/refresh/');
      print('🔄 [AUTH REFRESH] Calling $refreshUrl ...');

      final res = await httpClient.post(
        refreshUrl,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({'refresh': refresh}),
      );

      print('🔄 [AUTH REFRESH] Status: ${res.statusCode}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final newAccess = data['access']?.toString();
        final newRefresh = data['refresh']?.toString();

        if (newAccess != null && newAccess.isNotEmpty) {
          await UserInfo.setAccessToken(newAccess);
        }
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await UserInfo.setRefreshToken(newRefresh);
        }
        print('✅ [AUTH REFRESH] Success — access and refresh tokens rotated');
        completer.complete(true);
        _refreshCompleter = null;
        return true;
      } else {
        print('❌ [AUTH REFRESH] Refresh failed: ${res.body}');
        await _onSessionExpired();
        completer.complete(false);
        _refreshCompleter = null;
        return false;
      }
    } catch (e) {
      print('❌ [AUTH REFRESH] Exception during refresh: $e');
      await _onSessionExpired();
      completer.complete(false);
      _refreshCompleter = null;
      return false;
    }
  }

  static Future<void> _onSessionExpired() async {
    await UserInfo.clearAll();
    try {
      if (Get.currentRoute != RouteName.signin) {
        Get.offAllNamed(RouteName.signin);
        Get.snackbar(
          'Session Expired',
          'Your session has expired. Please sign in again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFEF5350),
          colorText: Colors.white,
        );
      }
    } catch (_) {}
  }

  // ─── GET ──────────────────────────────────────────────────────────
  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? headers,
        bool requiresAuth = true,
        Map<String, String?>? queryParameters,
      }) async {
    final url = Uri.parse(_buildUrl(endpoint));
    final baseHeaders = requiresAuth ? _authHeaders() : {..._defaultHeaders};
    final mergedHeaders = {...baseHeaders, ...?headers};
    _logRequest("GET", url, mergedHeaders, null);
    final response = await _httpClient.get(url, headers: mergedHeaders);

    if (response.statusCode == 401 && requiresAuth && !_isAuthEndpoint(endpoint)) {
      final refreshed = await refreshToken(client: _httpClient, baseUrl: baseUrl);
      if (refreshed) {
        final newHeaders = {..._authHeaders(), ...?headers};
        _logRequest("GET (RETRY)", url, newHeaders, null);
        final retryResponse = await _httpClient.get(url, headers: newHeaders);
        return _handleResponse(retryResponse, url, method: "GET");
      }
    }

    return _handleResponse(response, url, method: "GET");
  }

  // ─── POST ─────────────────────────────────────────────────────────
  Future<dynamic> post(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
        bool requiresAuth = true,
      }) async {
    final url = Uri.parse(_buildUrl(endpoint));
    final baseHeaders = requiresAuth ? _authHeaders() : {..._defaultHeaders};
    final mergedHeaders = {...baseHeaders, ...?headers};
    final encodedBody = body != null ? jsonEncode(body) : null;
    _logRequest("POST", url, mergedHeaders, body);
    final response = await _httpClient.post(url, headers: mergedHeaders, body: encodedBody);

    if (response.statusCode == 401 && requiresAuth && !_isAuthEndpoint(endpoint)) {
      final refreshed = await refreshToken(client: _httpClient, baseUrl: baseUrl);
      if (refreshed) {
        final newHeaders = {..._authHeaders(), ...?headers};
        _logRequest("POST (RETRY)", url, newHeaders, body);
        final retryResponse = await _httpClient.post(url, headers: newHeaders, body: encodedBody);
        return _handleResponse(retryResponse, url, method: "POST");
      }
    }

    return _handleResponse(response, url, method: "POST");
  }

  // ─── PUT ──────────────────────────────────────────────────────────
  Future<dynamic> put(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
        bool requiresAuth = true,
      }) async {
    final url = Uri.parse(_buildUrl(endpoint));
    final baseHeaders = requiresAuth ? _authHeaders() : {..._defaultHeaders};
    final mergedHeaders = {...baseHeaders, ...?headers};
    final encodedBody = body != null ? jsonEncode(body) : null;
    _logRequest("PUT", url, mergedHeaders, body);
    final response = await _httpClient.put(url, headers: mergedHeaders, body: encodedBody);

    if (response.statusCode == 401 && requiresAuth && !_isAuthEndpoint(endpoint)) {
      final refreshed = await refreshToken(client: _httpClient, baseUrl: baseUrl);
      if (refreshed) {
        final newHeaders = {..._authHeaders(), ...?headers};
        _logRequest("PUT (RETRY)", url, newHeaders, body);
        final retryResponse = await _httpClient.put(url, headers: newHeaders, body: encodedBody);
        return _handleResponse(retryResponse, url, method: "PUT");
      }
    }

    return _handleResponse(response, url, method: "PUT");
  }

  // ─── PATCH ────────────────────────────────────────────────────────
  Future<dynamic> patch(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
        bool requiresAuth = true,
      }) async {
    final url = Uri.parse(_buildUrl(endpoint));
    final baseHeaders = requiresAuth ? _authHeaders() : {..._defaultHeaders};
    final mergedHeaders = {...baseHeaders, ...?headers};
    final encodedBody = body != null ? jsonEncode(body) : null;
    _logRequest("PATCH", url, mergedHeaders, body);
    final response = await _httpClient.patch(url, headers: mergedHeaders, body: encodedBody);

    if (response.statusCode == 401 && requiresAuth && !_isAuthEndpoint(endpoint)) {
      final refreshed = await refreshToken(client: _httpClient, baseUrl: baseUrl);
      if (refreshed) {
        final newHeaders = {..._authHeaders(), ...?headers};
        _logRequest("PATCH (RETRY)", url, newHeaders, body);
        final retryResponse = await _httpClient.patch(url, headers: newHeaders, body: encodedBody);
        return _handleResponse(retryResponse, url, method: "PATCH");
      }
    }

    return _handleResponse(response, url, method: "PATCH");
  }

  // ─── DELETE ───────────────────────────────────────────────────────
  Future<dynamic> delete(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
        bool requiresAuth = true,
      }) async {
    final url = Uri.parse(_buildUrl(endpoint));
    final baseHeaders = requiresAuth ? _authHeaders() : {..._defaultHeaders};
    final mergedHeaders = {...baseHeaders, ...?headers};
    final encodedBody = body != null ? jsonEncode(body) : null;
    _logRequest("DELETE", url, mergedHeaders, body);
    final response = await _httpClient.delete(url, headers: mergedHeaders, body: encodedBody);

    if (response.statusCode == 401 && requiresAuth && !_isAuthEndpoint(endpoint)) {
      final refreshed = await refreshToken(client: _httpClient, baseUrl: baseUrl);
      if (refreshed) {
        final newHeaders = {..._authHeaders(), ...?headers};
        _logRequest("DELETE (RETRY)", url, newHeaders, body);
        final retryResponse = await _httpClient.delete(url, headers: newHeaders, body: encodedBody);
        return _handleResponse(retryResponse, url, method: "DELETE");
      }
    }

    return _handleResponse(response, url, method: "DELETE");
  }

  // ─── MULTIPART ────────────────────────────────────────────────────
  Future<dynamic> multipart(
      String endpoint, {
        required String method,
        Map<String, String>? fields,
        Map<String, File>? files,
        bool requiresAuth = true,
      }) async {
    final url = Uri.parse(_buildUrl(endpoint));
    final token = requiresAuth ? UserInfo.getAccessTokenSync() : null;
    final request = http.MultipartRequest(method, url);
    if (token != null && token.isNotEmpty) {
      request.headers["Authorization"] = "Bearer $token";
    }
    request.headers["Accept"] = "application/json";
    if (fields != null) request.fields.addAll(fields);
    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value.path));
      }
    }
    print("🌐 [$method MULTIPART] URL: $url");
    print("📋 Fields: $fields");
    print("📎 Files: ${files?.keys.toList()}");
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401 && requiresAuth && !_isAuthEndpoint(endpoint)) {
      final refreshed = await refreshToken(client: _httpClient, baseUrl: baseUrl);
      if (refreshed) {
        return multipart(
          endpoint,
          method: method,
          fields: fields,
          files: files,
          requiresAuth: requiresAuth,
        );
      }
    }

    return _handleResponse(response, url, method: "$method MULTIPART");
  }

  // ─── Response Handler ─────────────────────────────────────────────
  dynamic _handleResponse(http.Response response, Uri url,
      {required String method}) {
    print("📩 [$method] Status: ${response.statusCode}");
    print("📩 [$method] Body: ${response.body}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw HttpException(
          message: "Invalid JSON format",
          statusCode: response.statusCode,
          uri: url,
          body: response.body,
        );
      }
    }

    String errorMessage = "Request failed";
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map<String, dynamic>) {
        if (errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'].toString();
        } else if (errorBody.containsKey('error')) {
          errorMessage = errorBody['error'].toString();
        } else {
          errorMessage = errorBody.entries.map((e) {
            final val = e.value;
            if (val is List) return "${e.key}: ${val.join(', ')}";
            return "${e.key}: $val";
          }).join(" | ");
        }
      }
    } catch (_) {
      errorMessage =
      response.body.isNotEmpty ? response.body : "Request failed";
    }

    switch (response.statusCode) {
      case 400:
        throw HttpException(
            message: errorMessage,
            statusCode: 400,
            uri: url,
            body: response.body);
      case 401:
        throw UnauthorizedException(uri: url, body: response.body);
      case 403:
        throw ForbiddenException(uri: url, body: response.body);
      case 404:
        throw NotFoundException(uri: url, body: response.body);
      case 409:
        throw ConflictException(uri: url, body: response.body, message: errorMessage);
      case 429:
        throw ThrottleException(uri: url, body: response.body, message: errorMessage);
      case 500:
      case 502:
      case 503:
        throw ServerException(uri: url, body: response.body);
      default:
        throw HttpException(
            message: errorMessage,
            statusCode: response.statusCode,
            uri: url,
            body: response.body);
    }
  }

  // ─── Logger ───────────────────────────────────────────────────────
  void _logRequest(String method, Uri url, Map<String, String> headers,
      dynamic body) {
    print("─────────────────────────────────────");
    print("🌐 [$method] $url");
    print("📋 Headers: $headers");
    if (body != null) print("📦 Body: $body");
    print("─────────────────────────────────────");
  }
}

// ─── Exceptions ───────────────────────────────────────────────────
class HttpException implements Exception {
  final String message;
  final int statusCode;
  final Uri uri;
  final String? body;

  const HttpException({
    required this.message,
    required this.statusCode,
    required this.uri,
    this.body,
  });

  @override
  String toString() => "HttpException [$statusCode]: $message | URL: $uri";
}

class UnauthorizedException extends HttpException {
  UnauthorizedException({required Uri uri, String? body})
      : super(
      message: "Unauthorized. Please log in again.",
      statusCode: 401,
      uri: uri,
      body: body);
}

class ForbiddenException extends HttpException {
  ForbiddenException({required Uri uri, String? body})
      : super(
      message: "Access denied.",
      statusCode: 403,
      uri: uri,
      body: body);
}

class ConflictException extends HttpException {
  ConflictException({required Uri uri, String? body, String message = "Conflict / in-flight operation."})
      : super(
      message: message,
      statusCode: 409,
      uri: uri,
      body: body);
}

class ThrottleException extends HttpException {
  ThrottleException({required Uri uri, String? body, String message = "Too many requests. Please try again later."})
      : super(
      message: message,
      statusCode: 429,
      uri: uri,
      body: body);
}

class NotFoundException extends HttpException {
  NotFoundException({required Uri uri, String? body})
      : super(
      message: "Resource not found.",
      statusCode: 404,
      uri: uri,
      body: body);
}

class ServerException extends HttpException {
  ServerException({required Uri uri, String? body})
      : super(
      message: "Server error. Please try again later.",
      statusCode: 500,
      uri: uri,
      body: body);
}