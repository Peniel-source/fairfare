import 'package:fairfare/features/auth/domain/entities/auth_user.dart';
import 'package:fairfare/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const verified = AuthUser(
    id: 'u1',
    email: 'a@example.com',
    emailVerified: true,
  );
  const unverified = AuthUser(id: 'u2', email: 'b@example.com');

  group('authRedirect', () {
    test('stays put while auth state is still loading', () {
      expect(authRedirect(const AsyncLoading(), '/home/wallet'), isNull);
    });

    test('signed out: public routes allowed, private routes go to Landing', () {
      const out = AsyncData<AuthUser?>(null);
      for (final route in kPublicRoutes) {
        expect(authRedirect(out, route), isNull, reason: route);
      }
      expect(authRedirect(out, '/home/corridors'), '/');
      expect(authRedirect(out, '/profile'), '/');
      expect(authRedirect(out, kVerifyEmailRoute), '/');
    });

    test('signed in, unverified: held on Verify Email', () {
      const auth = AsyncData<AuthUser?>(unverified);
      expect(authRedirect(auth, '/home/corridors'), kVerifyEmailRoute);
      expect(authRedirect(auth, '/login'), kVerifyEmailRoute);
      expect(authRedirect(auth, kVerifyEmailRoute), isNull);
    });

    test(
      'signed in, verified: auth screens and Verify Email go to Corridors',
      () {
        const auth = AsyncData<AuthUser?>(verified);
        expect(authRedirect(auth, '/'), kHomeRoute);
        expect(authRedirect(auth, '/login'), kHomeRoute);
        expect(authRedirect(auth, '/register'), kHomeRoute);
        expect(authRedirect(auth, kVerifyEmailRoute), kHomeRoute);
      },
    );

    test('signed in, verified: private routes are allowed', () {
      const auth = AsyncData<AuthUser?>(verified);
      expect(authRedirect(auth, '/home/wallet'), isNull);
      expect(authRedirect(auth, '/profile'), isNull);
      expect(authRedirect(auth, '/reset-password'), isNull);
    });
  });
}
