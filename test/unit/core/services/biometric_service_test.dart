import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/core/services/biometric_service.dart';

void main() {
  group('BiometricService', () {
    // -----------------------------------------------------------------------
    // NOTE: BiometricService wraps the `local_auth` platform plugin and
    // creates its own LocalAuthentication instance internally. Because the
    // dependency is not injected, we cannot mock it without modifying
    // production code (which we avoid here).
    //
    // In a test environment, the platform plugin is not available, so
    // canAuthenticate() and authenticate() will throw PlatformExceptions
    // internally, which the service catches and returns false.
    //
    // These tests verify:
    //   1. The service can be instantiated.
    //   2. canAuthenticate returns false when the plugin is unavailable.
    //   3. authenticate returns false when the plugin is unavailable.
    // -----------------------------------------------------------------------

    late BiometricService service;

    setUp(() {
      service = BiometricService();
    });

    test('can be instantiated', () {
      expect(service, isA<BiometricService>());
    });

    test(
      'canAuthenticate returns false when platform plugin is unavailable',
      () async {
        // In test environment, local_auth plugin is not registered, so
        // canCheckBiometrics and isDeviceSupported will throw. The service
        // catches the exception and returns false.
        final result = await service.canAuthenticate();
        expect(result, isFalse);
      },
    );

    test(
      'authenticate returns false when platform plugin is unavailable',
      () async {
        // In test environment, the platform plugin will throw. The service
        // catches the exception and returns false.
        final result = await service.authenticate();
        expect(result, isFalse);
      },
    );

    test('authenticate accepts a custom reason string', () async {
      // Verify the named parameter is accepted without error.
      // The actual platform call will fail, but the service catches it.
      final result = await service.authenticate(
        reason: 'Please confirm your identity',
      );
      expect(result, isFalse);
    });
  });
}
