import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final DatabaseService _db = DatabaseService();

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      return canAuthenticateWithBiometrics && availableBiometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return <BiometricType>[];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Por favor, autentícate para acceder a Nest',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows passcode fallback
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // Persistencia de ajustes
  Future<void> setEnabled(bool enabled) async {
    try {
      await _db.saveSetting('biometric_enabled', enabled.toString());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', enabled);
    } catch (_) {}
  }

  Future<bool> isEnabled() async {
    try {
      // Intentar SharedPreferences primero por velocidad
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('biometric_enabled')) {
        return prefs.getBool('biometric_enabled') ?? false;
      }
      
      // Fallback a Database
      final val = await _db.getSetting('biometric_enabled');
      final enabled = val == 'true';
      
      // Sincronizar con SharedPreferences para la próxima vez
      await prefs.setBool('biometric_enabled', enabled);
      return enabled;
    } catch (_) {
      return false;
    }
  }
}
