// "Continue with Google" button for the login and register screens (D2).
//
// The sign in itself runs through AuthController, so any error shows in the
// screen's usual error message, and the router moves the passenger on once
// the auth state changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import 'auth_providers.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  // Only decides where the spinner goes: on this button, not on the email
  // form's button, while Google sign in runs.
  bool _running = false;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _running = true);
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    final loading = busy && _running;

    return Semantics(
      button: true,
      label: loading ? 'Continue with Google, loading' : null,
      excludeSemantics: loading,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.minTapTarget,
        child: OutlinedButton.icon(
          onPressed: busy ? null : _signIn,
          icon: loading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const _GoogleMark(),
          label: const Text(
            'Continue with Google',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// A plain "G" so the button reads as Google without bundling a logo asset.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        'G',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// "or" with a line on each side, between the email form and Google.
class AuthMethodDivider extends StatelessWidget {
  const AuthMethodDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('or', style: Theme.of(context).textTheme.bodySmall),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
