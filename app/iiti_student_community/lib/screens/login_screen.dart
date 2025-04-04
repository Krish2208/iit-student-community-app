import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iiti_student_community/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
              onPressed: () async {
                final authService = context.read<AuthService>();
                await authService.signInWithGoogle();
                // No need to navigate manually - the AuthWrapper will handle it
              },
            ),
          ],
        ),
      ),
    );
  }
}