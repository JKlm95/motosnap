import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rejestracja')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text(
            'Formularz rejestracji — miejsce pod Firebase Auth.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enabled: false,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Hasło'),
            obscureText: true,
            enabled: false,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: null, child: const Text('Utwórz konto')),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Mam już konto'),
          ),
        ],
      ),
    );
  }
}
