import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create your account')),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Kitchen Diary uses Google sign-in only.'),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Continue with Google')),
          ]),
        )),
      );
}
