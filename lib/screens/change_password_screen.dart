import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/firebase_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseService _fb = FirebaseService();
  
  bool _obscureText = true;
  bool _isLoading = false;
  bool _needsReauth = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 8) {
      _showError(l10n.min8Chars);
      return;
    }

    if (newPassword != confirmPassword) {
      _showError(l10n.passwordsMatch); // Wait, this logic is a bit inverted in the message, but matches current behavior
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _fb.updatePassword(newPassword);
      if (mounted) {
        _showSuccess(l10n.passwordSetSuccess);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(() {
          _needsReauth = true;
          _isLoading = false;
        });
        _showError(l10n.requiresRecentLoginError);
      } else {
        _showError('Error: ${e.message}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error inesperado: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reauthWithGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await _fb.reauthenticateWithGoogle();
      setState(() {
        _needsReauth = false;
        _isLoading = false;
      });
      _showSuccess(l10n.identityVerified);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al verificar: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNewPassword = !_fb.hasPasswordProvider;

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
          isNewPassword ? l10n.createPassword : l10n.changePassword,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(isNewPassword ? Icons.add_moderator_rounded : Icons.lock_reset_rounded, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNewPassword ? l10n.enableEmailAccess : l10n.updateSecurity,
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isNewPassword 
                            ? l10n.enableEmailAccessDesc
                            : l10n.changePasswordDesc,
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle(context, isNewPassword ? l10n.createPassword : l10n.changePassword),
            const SizedBox(height: 16),
            
            _buildPasswordField(
              context,
              controller: _newPasswordController,
              label: l10n.password,
              hint: l10n.min8Chars,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              context,
              controller: _confirmPasswordController,
              label: l10n.password,
              hint: l10n.passwordsMatch,
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle(context, l10n.passwordRequirements),
            const SizedBox(height: 12),
            _buildRequirementItem(context, l10n.min8Chars, _newPasswordController.text.length >= 8),
            _buildRequirementItem(context, l10n.passwordsMatch, _newPasswordController.text == _confirmPasswordController.text && _newPasswordController.text.isNotEmpty),
            
            const SizedBox(height: 48),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_needsReauth)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _reauthWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                  label: Text(l10n.verifyWithGoogleFirst, style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black12)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _handleUpdate,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    isNewPassword ? l10n.createPassword : l10n.saveChanges,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscureText,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 14),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(BuildContext context, String text, bool met) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: met ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: met ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
