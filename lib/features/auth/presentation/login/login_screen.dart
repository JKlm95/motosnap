import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import 'cubit/login_cubit.dart';
import 'cubit/login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logowanie')),
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final loading = state.status == LoginStatus.loading;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                'Zaloguj się, aby zapisywać skany w chmurze (Firestore + Storage).',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !loading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Hasło'),
                obscureText: true,
                enabled: !loading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(context, loading),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading ? null : () => _submit(context, loading),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Zaloguj'),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () => context.push(AppRoutes.forgotPassword),
                child: const Text('Zapomniałeś hasła?'),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () => context.push(AppRoutes.register),
                child: const Text('Załóż konto'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit(BuildContext context, bool loading) {
    if (loading) return;
    context.read<LoginCubit>().submit(
      email: _email.text,
      password: _password.text,
      onSuccessNavigate: () {
        if (!context.mounted) return;
        context.go(AppRoutes.scanRelative);
      },
    );
  }
}
