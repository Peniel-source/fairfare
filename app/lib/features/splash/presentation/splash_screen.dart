// Animated splash, the first screen after the native launch screen.
//
// The FairFare logo is revealed through a growing circle and eases up to
// size, a soft shimmer passes over it and the tagline settles in, over warm
// light drifting in from the corners. The motion borrows ideas from Pixel
// Perfect's web blocks (mask reveal, shimmer, animated background), rebuilt
// in Flutter.
//
// It plays once (no repeat), then goes wherever authRedirect sends the
// passenger: Landing, Verify Email or Corridors. With reduced motion turned
// on it shows the final frame and moves on after a short pause.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../router.dart';
import '../../auth/presentation/auth_providers.dart';

/// Length of the whole splash animation.
const kSplashDuration = Duration(milliseconds: 2400);

/// How long the final frame stays when animations are turned off.
const kSplashReducedMotionHold = Duration(milliseconds: 600);

/// How long to wait for the auth state after the animation before moving on
/// anyway; the router then redirects once the auth state arrives.
const kSplashAuthTimeout = Duration(seconds: 3);

/// The FairFare logo (moto illustration with the wordmark).
const kLogoAsset = 'assets/images/welcome_moto.png';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kSplashDuration,
  );

  bool _started = false;

  /// The animation has played (or the reduced motion hold has passed).
  bool _played = false;
  bool _left = false;
  Timer? _holdTimer;
  Timer? _authTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _holdTimer = Timer(kSplashReducedMotionHold, _onPlayed);
    } else {
      _controller.forward().whenComplete(_onPlayed);
    }
  }

  void _onPlayed() {
    _played = true;
    _maybeLeave();
  }

  void _maybeLeave() {
    if (_left || !mounted || !_played) return;
    final auth = ref.read(authStateProvider);
    if (auth.isLoading && !auth.hasValue) {
      // Wait for the auth listener in build, but not forever.
      _authTimer ??= Timer(kSplashAuthTimeout, _leave);
      return;
    }
    _leave();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    context.go(authRedirect(ref.read(authStateProvider), '/') ?? '/');
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _authTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, _) => _maybeLeave());

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = theme.extension<AppPalette>()?.accent ?? AppColors.orange;

    return Scaffold(
      body: Semantics(
        label: 'FairFare. Fair moto fares in Kigali',
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _Glow(t: t, primary: scheme.primary, accent: accent),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Logo(t: t),
                        const SizedBox(height: AppSpacing.xl),
                        _Tagline(t: t),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// [curve] over the part of the animation between [begin] and [end].
double _phase(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) => Interval(begin, end, curve: curve).transform(t);

/// Two soft pools of warm light that drift in from the corners.
class _Glow extends StatelessWidget {
  const _Glow({required this.t, required this.primary, required this.accent});

  final double t;
  final Color primary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final drift = _phase(t, 0, 1);

    Widget pool(Alignment from, Alignment to, Color color, double alpha) {
      return Align(
        alignment: Alignment.lerp(from, to, drift)!,
        child: FractionallySizedBox(
          widthFactor: 1.3,
          heightFactor: 0.7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: alpha * drift),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        pool(
          const Alignment(-1.6, -1.4),
          const Alignment(-0.9, -0.8),
          accent,
          0.22,
        ),
        pool(
          const Alignment(1.6, 1.4),
          const Alignment(0.9, 0.8),
          primary,
          0.14,
        ),
      ],
    );
  }
}

/// The FairFare logo, revealed through a growing circle (it is a round
/// illustration), easing up to full size, then a soft shimmer passes over it.
class _Logo extends StatelessWidget {
  const _Logo({required this.t});

  final double t;

  static const double size = 240;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reveal = _phase(t, 0, 0.5, Curves.easeInOutCubic);
    final settle = _phase(t, 0, 0.6);
    final shimmer = _phase(t, 0.55, 0.9, Curves.easeInOut);
    final center = -1.6 + 3.2 * shimmer;

    return Opacity(
      opacity: _phase(t, 0, 0.3),
      child: Transform.scale(
        scale: 0.92 + 0.08 * settle,
        child: ClipPath(
          clipper: _CircleReveal(reveal),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(center - 0.5, -0.4),
              end: Alignment(center + 0.5, 0.4),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(
                  alpha: shimmer > 0 && shimmer < 1 ? 0.35 : 0,
                ),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(bounds),
            // The logo has a cream background; the rounded tile keeps it
            // tidy on the dark theme too.
            child: Container(
              width: size,
              height: size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(size * 0.16),
              ),
              child: Image.asset(
                kLogoAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A circle from the center that grows to cover the whole box at 1.
class _CircleReveal extends CustomClipper<Path> {
  _CircleReveal(this.value);

  final double value;

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    // Half the diagonal reaches the corners.
    final full = size.longestSide * 0.75;
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: full * value));
  }

  @override
  bool shouldReclip(_CircleReveal old) => old.value != value;
}

class _Tagline extends StatelessWidget {
  const _Tagline({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final value = _phase(t, 0.62, 0.92);
    final style = AppTypography.eyebrow(context);

    return Opacity(
      opacity: value,
      child: Text(
        'FAIR MOTO FARES · KIGALI',
        style: style.copyWith(
          letterSpacing: (style.letterSpacing ?? 1.2) + 2 * (1 - value),
        ),
      ),
    );
  }
}
