import 'package:flutter/material.dart';
import '../widgets/nest_icon.dart';
import '../services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Hero(
              tag: 'app_logo',
              child: NestIcon(size: 130),
            ),
            const SizedBox(height: 30),
            Text(
              'Nest',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                letterSpacing: -2.0,
              ),
            ),
            const SizedBox(height: 60),
            IconButton.filledTonal(
              onPressed: _authenticate,
              icon: const Icon(Icons.lock_open_rounded, size: 32),
              style: IconButton.styleFrom(
                minimumSize: const Size(80, 80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pulsa para desbloquear',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
