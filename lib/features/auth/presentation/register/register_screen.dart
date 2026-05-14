import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import 'cubit/register_cubit.dart';
import 'cubit/register_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
      appBar: AppBar(title: const Text('Rejestracja')),
      body: BlocConsumer<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final loading = state.status == RegisterStatus.loading;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                'Konto pozwala zsynchronizować metadane skanu i zdjęcie z Twoim UID.',
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
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  helperText: 'Minimum 6 znaków (wymóg Firebase).',
                ),
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
                    : const Text('Utwórz konto'),
              ),
              TextButton(
                onPressed: loading ? null : () => context.go(AppRoutes.login),
                child: const Text('Mam już konto'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit(BuildContext context, bool loading) {
    if (loading) return;
    context.read<RegisterCubit>().submit(
      email: _email.text,
      password: _password.text,
      onSuccessNavigate: () {
        if (!context.mounted) return;
        context.go(AppRoutes.scanRelative);
      },
    );
  }
}
