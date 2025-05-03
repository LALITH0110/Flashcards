import 'package:flutter/material.dart';
import 'models/user.dart';
import 'views/login_screen.dart';
import 'views/game_list_screen.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Battleships',
    home: AuthWrapper(),
  ));
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: User.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null || user.isTokenExpired) {
          return const LoginScreen();
        }

        return const GameListScreen();
      },
    );
  }
}
