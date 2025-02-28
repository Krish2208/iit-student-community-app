import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Settings Tab'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<AuthService>().signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}