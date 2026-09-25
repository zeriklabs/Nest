import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? oobCode;

  const ResetPasswordScreen({super.key, this.oobCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _effectiveCode;
  String? _userEmail;
  bool _isVerifyingCode = true;
  bool _isCodeValid = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _effectiveCode = widget.oobCode;
    if (_effectiveCode != null && _effectiveCode!.isNotEmpty) {
      _verifyResetCode(_effectiveCode!);
    } else {
      setState(() {
        _isVerifyingCode = false;
        _isCodeValid = false;
      });
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyResetCode(String code) async {
    setState(() {
      _isVerifyingCode = true;
      _errorMessage = null;
    });

    try {
      final email = await _auth.verifyPasswordResetCode(code);
      if (mounted) {
        setState(() {
          _userEmail = email;
          _effectiveCode = code;
          _isCodeValid = true;
          _isVerifyingCode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCodeValid = false;
          _isVerifyingCode = false;
          _errorMessage = 'El código de restablecimiento no es válido o ha caducado.';
        });
      }
    }
  }

  Future<void> _handleConfirmReset() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 8) {
      _showSnackBar('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Las contraseñas no coinciden.');
      return;
    }

    if (_effectiveCode == null || _effectiveCode!.isEmpty) {
      _showSnackBar('Código de restablecimiento no encontrado.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.confirmPasswordReset(
        code: _effectiveCode!,
        newPassword: newPassword,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.message ?? 'Error al restablecer la contraseña.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error inesperado: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0F12) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16181E) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(15)
                        : colorScheme.outlineVariant.withAlpha(60),
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: _isSuccess
                    ? _buildSuccessView(context, isDark, colorScheme)
                    : _buildFormView(context, isDark, colorScheme, l10n),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    AppLocalizations? l10n,
  ) {
    final passLengthMet = _newPasswordController.text.length >= 8;
    final passMatchMet =
        _newPasswordController.text == _confirmPasswordController.text &&
            _newPasswordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo & Header
        Center(
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withAlpha(50),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Restablecer Contraseña',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _userEmail != null
                    ? 'Escribe tu nueva contraseña para $_userEmail'
                    : 'Ingresa tu nueva contraseña para acceder a tu cuenta de Nest',
                style: TextStyle(
                  fontSize: 13,
                  color: (isDark ? Colors.white : Colors.black).withAlpha(140),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        if (_isVerifyingCode) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando enlace de restablecimiento...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ] else if (!_isCodeValid) ...[
          // Manual Code or Invalid Code State
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage ?? 'Código de restablecimiento no válido.',
                    style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ingresa el código que recibiste en tu correo electrónico:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black).withAlpha(180),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _codeController,
            label: 'Código de verificación',
            icon: Icons.vpn_key_rounded,
            isDark: isDark,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final code = _codeController.text.trim();
                if (code.isNotEmpty) {
                  _verifyResetCode(code);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Verificar Código'),
            ),
          ),
        ] else ...[
          // Valid Code Form
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'Nueva contraseña',
            hint: 'Mínimo 8 caracteres',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmar contraseña',
            hint: 'Repite la contraseña',
            icon: Icons.lock_clock_outlined,
            isDark: isDark,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 24),

          // Requirements checklist
          _buildRequirementRow('Mínimo 8 caracteres', passLengthMet, colorScheme, isDark),
          const SizedBox(height: 6),
          _buildRequirementRow('Las contraseñas coinciden', passMatchMet, colorScheme, isDark),

          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleConfirmReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Text(
                      'Guardar Nueva Contraseña',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Text(
              'Volver al Inicio de Sesión',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.withAlpha(60), width: 2),
          ),
          child: const Icon(Icons.check_circle_rounded, size: 48, color: Colors.green),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Contraseña Actualizada!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Tu contraseña ha sido restablecida correctamente. Ya puedes acceder a Nest con tus nuevas credenciales.',
          style: TextStyle(
            fontSize: 14,
            color: (isDark ? Colors.white : Colors.black).withAlpha(150),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              'Iniciar Sesión en Nest',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withAlpha(60)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          icon: Icon(icon, color: colorScheme.primary, size: 20),
          labelText: label,
          labelStyle: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withAlpha(120),
            fontSize: 13,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withAlpha(60),
            fontSize: 13,
          ),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: (isDark ? Colors.white : Colors.black).withAlpha(100),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withAlpha(60)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: colorScheme.primary, size: 20),
          labelText: label,
          labelStyle: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withAlpha(120),
            fontSize: 13,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildRequirementRow(
    String text,
    bool met,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: met ? Colors.green : (isDark ? Colors.white : Colors.black).withAlpha(60),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: met
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white : Colors.black).withAlpha(120),
            fontWeight: met ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
