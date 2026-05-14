import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import 'cubit/forgot_password_cubit.dart';
import 'cubit/forgot_password_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset hasła')),
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.errorMessage != null) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          } else if (state.infoMessage != null) {
            messenger.clearSnackBars();
            messenger.showSnackBar(SnackBar(content: Text(state.infoMessage!)));
          }
        },
        builder: (context, state) {
          final loading = state.status == ForgotPasswordStatus.loading;
          final done = state.status == ForgotPasswordStatus.success;
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Wyślemy link resetu na podany adres (Firebase Auth).',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !loading && !done,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(context, loading, done),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading || done
                      ? null
                      : () => _submit(context, loading, done),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Wyślij link'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Wróć do logowania'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit(BuildContext context, bool loading, bool done) {
    if (loading || done) return;
    context.read<ForgotPasswordCubit>().submit(_email.text);
  }
}
