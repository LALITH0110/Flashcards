import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://battleships-app.onrender.com';
  static final HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  static final _client = IOClient(_httpClient);

  static Future<User> login(String username, String password) async {
    try {
      debugPrint('Attempting to login user: $username');
      final response = await _client.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw 'Connection timed out. Please try again.';
        },
      );

      debugPrint('Server response status: ${response.statusCode}');
      debugPrint('Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User(
          username: username,
          accessToken: data['access_token'],
          tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
        );
        await User.saveUser(user);
        return user;
      } else {
        final error = json.decode(response.body);
        throw error['message'] ?? 'Invalid username or password';
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: ${e.toString()}');
      throw 'Unable to connect to server. Please check your internet connection and try again.';
    } on HttpException catch (e) {
      debugPrint('HttpException: ${e.toString()}');
      throw 'Unable to connect to server. Please try again later.';
    } on FormatException catch (e) {
      debugPrint('FormatException: ${e.toString()}');
      throw 'Invalid response from server. Please try again later.';
    } catch (e) {
      debugPrint('Unexpected error: ${e.toString()}');
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  static Future<User> register(String username, String password) async {
    try {
      debugPrint('Attempting to register user: $username');
      final response = await _client.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw 'Connection timed out. Please try again.';
        },
      );

      debugPrint('Server response status: ${response.statusCode}');
      debugPrint('Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User(
          username: username,
          accessToken: data['access_token'],
          tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
        );
        await User.saveUser(user);
        return user;
      } else {
        final error = json.decode(response.body);
        throw error['message'] ?? 'Registration failed. Please try again.';
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: ${e.toString()}');
      throw 'Unable to connect to server. Please check your internet connection and try again.';
    } on HttpException catch (e) {
      debugPrint('HttpException: ${e.toString()}');
      throw 'Unable to connect to server. Please try again later.';
    } on FormatException catch (e) {
      debugPrint('FormatException: ${e.toString()}');
      throw 'Invalid response from server. Please try again later.';
    } catch (e) {
      debugPrint('Unexpected error: ${e.toString()}');
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  static Future<void> logout() async {
    await User.clearUser();
  }
} 