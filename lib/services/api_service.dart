import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.0.53:8081'; // Replace with your actual API URL
  static const String _userIdKey = 'current_user_id';
  static const String _authTokenKey = 'auth_token';
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // Get current user ID
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Set current user ID
  Future<void> setCurrentUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  // Save auth token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  // Remove auth token and user ID (for logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userIdKey);
  }

  // GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final stringQueryParameters = queryParams?.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: stringQueryParameters,
      );

      log('GET request to: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(_timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: body is Map || body is List ? jsonEncode(body) : body,
      ).timeout(_timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _getHeaders(),
      ).timeout(_timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // File upload with progress
  Future<dynamic> uploadFile(
      String endpoint, {
        required String filePath,
        String fileField = 'file',
        Map<String, String>? fields,
      }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$endpoint'),
      );

      final headers = await _getHeaders();
      request.headers.addAll(Map<String, String>.from(headers)
        ..remove('Content-Type'));

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        filePath,
        contentType: _getMediaType(filePath),
      ));

      // Add other fields if any
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Send the request
      final streamedResponse = await request.send().timeout(_timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // Helper to get media type from file path
  MediaType _getMediaType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = utf8.decode(response.bodyBytes);

    if (statusCode >= 200 && statusCode < 300) {
      if (responseBody.isEmpty) return null;
      return jsonDecode(responseBody);
    } else {
      final error = jsonDecode(responseBody);
      throw HttpException(
        error['message'] ?? 'Request failed with status: $statusCode',
        uri: response.request?.url,
      );
    }
  }

  // Get headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authorization token if available
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    return token != null;
  }

  // Handle errors
  void _handleError(dynamic error) {
    if (error is TimeoutException) {
      throw Exception('Request timed out. Please check your connection and try again.');
    } else if (error is SocketException) {
      throw Exception('No internet connection. Please check your network settings.');
    } else if (error is FormatException) {
      throw Exception('Invalid data format. Please try again later.');
    } else {
      throw error;
    }
  }
}
