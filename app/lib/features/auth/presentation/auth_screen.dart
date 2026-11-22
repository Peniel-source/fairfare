import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'auth_providers.dart';
import 'google_sign_in_button.dart';

enum EmailAuthMode { login, register, resetPassword }

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key, required this.mode});

  final EmailAuthMode mode;

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _displayName = TextEditingController();
  bool _resetSent = false;

  bool get _registering => widget.mode == EmailAuthMode.register;
  bool get _resetting => widget.mode == EmailAuthMode.resetPassword;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(authControllerProvider.notifier);
    final success = await switch (widget.mode) {
      EmailAuthMode.login => controller.signIn(_email.text, _password.text),
      EmailAuthMode.register => controller.register(
        _email.text,
        _password.text,
        _displayName.text,
      ),
      EmailAuthMode.resetPassword => controller.resetPassword(_email.text),
    };
    if (!mounted) return;
    if (success) {
      if (_resetting) {
        setState(() => _resetSent = true);
      } else {
        TextInput.finishAutofillContext();
      }
    }
  }

  void _navigate(String route) {
    ref.read(authControllerProvider.notifier).clearError();
    context.goNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authControllerProvider);
    final busy = action.isLoading;
    final title = switch (widget.mode) {
      EmailAuthMode.login => 'Welcome back',
      EmailAuthMode.register => 'Create your account',
      EmailAuthMode.resetPassword => 'Reset your password',
    };
    final subtitle = switch (widget.mode) {
      EmailAuthMode.login => 'Sign in to your FairFare account.',
      EmailAuthMode.register =>
        'Join other passengers sharing fares in Kigali.',
      EmailAuthMode.resetPassword =>
        'We’ll email you a link to choose a new password.',
    };
    final label = switch (widget.mode) {
      EmailAuthMode.login => 'Sign in',
      EmailAuthMode.register => 'Create account',
      EmailAuthMode.resetPassword => 'Send reset link',
    };

    return _AuthPage(
      title: title,
      subtitle: subtitle,
      onBack: busy ? null : () => _navigate(_resetting ? 'login' : 'landing'),
      children: [
        AppCard(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              onChanged: () {
                ref.read(authControllerProvider.notifier).clearError();
                if (_resetSent) setState(() => _resetSent = false);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_registering) ...[
                    TextFormField(
                      controller: _displayName,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.nickname],
                      maxLength: 80,
                      validator: Validators.displayName,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  TextFormField(
                    controller: _email,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: _resetting
                        ? TextInputAction.done
                        : TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    validator: Validators.email,
                    onFieldSubmitted: _resetting ? (_) => _submit() : null,
                  ),
                  if (!_resetting) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _PasswordField(
                      controller: _password,
                      enabled: !busy,
                      label: 'Password',
                      hint: _registering
                          ? 'At least 8 characters, a letter and a number'
                          : null,
                      autofillHint: _registering
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                      validator: _registering
                          ? Validators.password
                          : Validators.loginPassword,
                      textInputAction: _registering
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmitted: _registering ? null : (_) => _submit(),
                    ),
                  ],
                  if (_registering) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _PasswordField(
                      controller: _confirmation,
                      enabled: !busy,
                      label: 'Confirm password',
                      autofillHint: AutofillHints.newPassword,
                      validator: (value) =>
                          Validators.confirmPassword(value, _password.text),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (action.hasError) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _AuthFeedback(authErrorMessage(action.error!), error: true),
                  ],
                  if (_resetSent) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const _AuthFeedback(
                      'If an account exists for that email, a reset link has been sent. Check your inbox and spam folder.',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: label,
                    onPressed: _submit,
                    isLoading: busy,
                    expand: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_resetting) ...[
          const AuthMethodDivider(),
          const GoogleSignInButton(),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!_registering && !_resetting)
          AppButton(
            label: 'Forgot password?',
            onPressed: busy ? null : () => _navigate('resetPassword'),
            variant: AppButtonVariant.text,
          ),
        AppButton(
          label: _registering || _resetting
              ? 'Back to sign in'
              : 'Create account',
          onPressed: busy
              ? null
              : () => _navigate(
                  _registering || _resetting ? 'login' : 'register',
                ),
          variant: AppButtonVariant.text,
        ),
      ],
    );
  }
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  String? _message;

  Future<void> _resend() async {
    setState(() => _message = null);
    final sent = await ref
        .read(authControllerProvider.notifier)
        .resendVerification();
    if (mounted && sent) {
      setState(
        () => _message =
            'Verification email sent. Check your inbox and spam folder.',
      );
    }
  }

  Future<void> _check() async {
    setState(() => _message = null);
    final checked = await ref
        .read(authControllerProvider.notifier)
        .checkVerification();
    if (mounted && checked) {
      setState(
        () => _message = 'Your email is not verified yet. Open the link in your inbox, then check again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final action = ref.watch(authControllerProvider);
    final busy = action.isLoading;
    final text = Theme.of(context).textTheme;

    return _AuthPage(
      title: 'Verify your email',
      subtitle: 'Open the verification link in your inbox to continue.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Not verified yet',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
              if (action.hasError) ...[
                const SizedBox(height: AppSpacing.lg),
                _AuthFeedback(authErrorMessage(action.error!), error: true),
              ],
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _AuthFeedback(_message!),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'I’ve verified my email',
                onPressed: _check,
                isLoading: busy,
                expand: true,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Resend email',
                onPressed: busy ? null : _resend,
                variant: AppButtonVariant.secondary,
                expand: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Sign out',
          onPressed: busy
              ? null
              : () => ref.read(authControllerProvider.notifier).signOut(),
          variant: AppButtonVariant.text,
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.autofillHint,
    required this.validator,
    this.hint,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String autofillHint;
  final String? hint;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: _obscure,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [widget.autofillHint],
    textInputAction: widget.textInputAction,
    validator: widget.validator,
    onFieldSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      helperText: widget.hint,
      helperMaxLines: 2,
      errorMaxLines: 3,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: widget.enabled
            ? () => setState(() => _obscure = !_obscure)
            : null,
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}

class _AuthFeedback extends StatelessWidget {
  const _AuthFeedback(this.message, {this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: error ? Theme.of(context).colorScheme.error : null),
    ),
  );
}

class _AuthPage extends StatelessWidget {
  const _AuthPage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('FairFare'),
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
