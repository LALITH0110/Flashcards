import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String username;
  final String accessToken;
  final DateTime tokenExpiry;

  User({
    required this.username,
    required this.accessToken,
    required this.tokenExpiry,
  });

  bool get isTokenExpired => DateTime.now().isAfter(tokenExpiry);

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', user.username);
    await prefs.setString('access_token', user.accessToken);
    await prefs.setString('token_expiry', user.tokenExpiry.toIso8601String());
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final accessToken = prefs.getString('access_token');
    final tokenExpiryStr = prefs.getString('token_expiry');

    if (username == null || accessToken == null || tokenExpiryStr == null) {
      return null;
    }

    return User(
      username: username,
      accessToken: accessToken,
      tokenExpiry: DateTime.parse(tokenExpiryStr),
    );
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('access_token');
    await prefs.remove('token_expiry');
  }
} 