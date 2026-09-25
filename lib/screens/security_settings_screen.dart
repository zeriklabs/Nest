import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'change_password_screen.dart';
import '../services/biometric_service.dart';
import '../services/firebase_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  final FirebaseService _fb = FirebaseService();
  bool _isBiometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _isDeviceSupported = false;
  bool _requireOnStartup = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isLoading = false;
    } else {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await _biometricService.isEnabled();
      final hasBiometrics = await _biometricService.canCheckBiometrics();
      final isSupported = await _biometricService.isDeviceSupported();
      
      if (mounted) {
        setState(() {
          _isBiometricEnabled = enabled;
          _canCheckBiometrics = hasBiometrics;
          _isDeviceSupported = isSupported;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    try {
      if (value) {
        final authenticated = await _biometricService.authenticate();
        if (authenticated && mounted) {
          await _biometricService.setEnabled(true);
          setState(() => _isBiometricEnabled = true);
        }
      } else {
        await _biometricService.setEnabled(false);
        if (mounted) {
          setState(() => _isBiometricEnabled = false);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.security,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;
          final double maxContentWidth = isWide ? 880 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32.0 : 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Icono Animado
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 1),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security_rounded,
                            size: isWide ? 80 : 70,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.securityTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWide ? 26 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(
                        l10n.securitySubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(160),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // Ajustes de contraseña
                    if (!_fb.isAnonymous)
                      _buildSection(
                        context,
                        title: l10n.access,
                        child: _buildSettingsTile(
                          context,
                          title: _fb.hasPasswordProvider ? l10n.changePassword : l10n.createPassword,
                          subtitle: _fb.hasPasswordProvider ? l10n.changePasswordDesc : l10n.enableEmailAccessDesc,
                          icon: _fb.hasPasswordProvider ? Icons.lock_reset_rounded : Icons.add_moderator_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                          ).then((_) => setState(() {})),
                        ),
                      ),
                    
                    if (!_fb.isAnonymous && !kIsWeb) const SizedBox(height: 24),
                    
                    // Bloqueo de dispositivo y biometría SOLO en dispositivos móviles (Android / iOS)
                    if (!kIsWeb)
                      _buildSection(
                        context,
                        title: _canCheckBiometrics ? l10n.biometrics : l10n.deviceLock,
                        child: Column(
                          children: [
                            _buildToggleTile(
                              context,
                              title: _canCheckBiometrics ? l10n.useBiometrics : l10n.deviceLock,
                              subtitle: _canCheckBiometrics ? l10n.useBiometricsDesc : l10n.deviceLockDesc,
                              icon: _canCheckBiometrics ? Icons.fingerprint_rounded : Icons.screen_lock_portrait_rounded,
                              value: _isBiometricEnabled,
                              onChanged: _isDeviceSupported ? _toggleBiometrics : (v) {},
                            ),
                            if (_isBiometricEnabled) ...[
                              Divider(height: 1, indent: 70, color: colorScheme.outlineVariant.withAlpha(51)),
                              _buildToggleTile(
                                context,
                                title: l10n.requireOnStartup,
                                subtitle: l10n.requireOnStartupDesc,
                                icon: Icons.timer_outlined,
                                value: _requireOnStartup,
                                onChanged: (value) => setState(() => _requireOnStartup = value),
                              ),
                            ],
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Información de Seguridad (Móvil vs Web)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.primary.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              kIsWeb ? Icons.verified_user_rounded : Icons.shield_outlined,
                              color: colorScheme.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kIsWeb ? 'Protección de Sesión Web' : 'Protección de Datos',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kIsWeb 
                                      ? 'Tu sesión en la web está cifrada y protegida mediante tokens OAuth 2.0 de Firebase Authentication. No almacenamos contraseñas en tu navegador.'
                                      : l10n.biometricPrivacyInfo,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withAlpha(150),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required Widget child, String? title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurface.withAlpha(127), fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withAlpha(76), size: 20),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurface.withAlpha(127), fontSize: 13),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}
