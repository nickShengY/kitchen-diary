import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../main.dart' show firebaseInitialized;
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome to Kitchen Diary',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Sign in securely with your Google account.'),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Continue with Google',
                  isLoading: auth.isLoading,
                  onPressed: firebaseInitialized
                      ? () async {
                          if (await context
                                  .read<AuthProvider>()
                                  .signInWithGoogle() &&
                              context.mounted) context.go('/explore');
                        }
                      : null,
                ),
                if (!firebaseInitialized)
                  const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Firebase is not configured.')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
