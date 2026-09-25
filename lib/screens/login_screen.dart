import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../widgets/nest_icon.dart';
import '../widgets/user_avatar.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient gradient for large screens
            if (isLargeScreen)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        colorScheme.primary.withAlpha(25),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),

            // Main Content Area
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24.0 : 32.0,
                  vertical: 24.0,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 480 : double.infinity,
                  ),
                  decoration: isLargeScreen
                      ? BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(60),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        )
                      : null,
                  padding: EdgeInsets.all(isLargeScreen ? 36.0 : 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Hero(
                        tag: 'app_logo',
                        child: NestIcon(size: 120),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Nest',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.nestSlogan,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withAlpha(140),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Consumer<DataService>(
                        builder: (context, dataService, _) {
                          if (dataService.lastAccountEmail == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _LastAccountCard(
                              name: dataService.lastAccountName ?? 'Usuario',
                              email: dataService.lastAccountEmail!,
                              photoUrl: dataService.lastAccountPhoto,
                            ),
                          );
                        }
                      ),
                      Column(
                        children: [
                          _ActionButton(
                            label: l10n.loginToAccount,
                            icon: Icons.login_rounded,
                            onPressed: () {
                              Navigator.of(context).push(_createRoute(const _LoginFormScreen()));
                            },
                            isPrimary: true,
                          ),
                          const SizedBox(height: 14),
                          _ActionButton(
                            label: l10n.loginAsGuest,
                            icon: Icons.person_outline_rounded,
                            onPressed: () {
                              Navigator.of(context).push(_createRoute(const _GuestFormScreen()));
                            },
                            isPrimary: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Versión 6.0.0 (Colibrí)',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(70),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Language Switcher Shortcut
            const Positioned(
              top: 12,
              right: 16,
              child: _LanguageSelectorButton(),
            ),
          ],
        ),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

class _LoginFormScreen extends StatefulWidget {
  final String? initialEmail;
  const _LoginFormScreen({this.initialEmail});

  @override
  State<_LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<_LoginFormScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isEntering = false;
  String _loadingMessage = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTermsModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.termsConditions,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.localeName == 'es'
                    ? 'Al utilizar Nest y acceder mediante Google, aceptas nuestras políticas de uso responsable, privacidad y almacenamiento de datos sincronizados.'
                    : 'By using Nest and signing in with Google, you agree to our terms of service, privacy practices, and synchronized data storage.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    l10n.localeName == 'es' ? 'Entendido' : 'Got it',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emailController = TextEditingController(text: _emailController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.resetPassword,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enterEmailToReset,
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _LoginTextField(
                controller: emailController,
                hint: l10n.email,
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 32),
              _PrimaryButton(
                label: l10n.sendResetLink,
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  try {
                    await FirebaseService().sendPasswordResetEmail(email);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.resetEmailSent),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _startLogin(Future<void> Function() loginAction) async {
    setState(() {
      _isEntering = true;
      _loadingMessage = "Verificando credenciales...";
    });

    try {
      context.read<DataService>().setForceProfileCheck(true);
      await loginAction();
      if (mounted) {
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (mounted) {
        context.read<DataService>().setForceProfileCheck(false);
        setState(() => _isEntering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getAuthErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Correo electrónico o contraseña incorrectos. Por favor, verifica tus datos.';
        case 'invalid-email':
          return 'El formato del correo electrónico no es válido.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada por el administrador.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Inténtalo de nuevo más tarde.';
        case 'network-request-failed':
          return 'Error de conexión. Revisa tu acceso a internet.';
        default:
          return error.message ?? 'Error al iniciar sesión. Inténtalo nuevamente.';
      }
    }
    return error.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isEntering ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface.withAlpha(150), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: _LanguageSelectorButton(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isEntering 
          ? _EnteringNestView(message: _loadingMessage)
          : Center(
              key: const ValueKey('form'),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24.0 : 32.0,
                  vertical: 24.0,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 480 : double.infinity,
                  ),
                  decoration: isLargeScreen
                      ? BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(60),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        )
                      : null,
                  padding: EdgeInsets.all(isLargeScreen ? 36.0 : 0.0),
                  child: Column(
                    children: [
                      const Hero(
                        tag: 'app_logo',
                        child: NestIcon(size: 140),
                      ),
                      const SizedBox(height: 36),
                      _LoginTextField(
                        controller: _emailController,
                        hint: l10n.email,
                        icon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 12),
                      _LoginTextField(
                        controller: _passwordController,
                        hint: l10n.password,
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: !_isPasswordVisible,
                        onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordSheet(context),
                          child: Text(
                            l10n.forgotPassword,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PrimaryButton(
                        label: l10n.loginToNest,
                        onPressed: () {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();
                          if (email.isEmpty || password.isEmpty) return;
                          _startLogin(() => FirebaseService().loginWithEmail(email, password));
                        },
                      ),
                      const SizedBox(height: 16),
                      _SocialButton(
                        isLoading: false, 
                        onPressed: () => _startLogin(() async {
                          setState(() => _loadingMessage = "Conectando con Google...");
                          await FirebaseService().signInWithGoogle();
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Leyenda de aceptacion de Terminos y Condiciones con Google
                      GestureDetector(
                        onTap: () => _showTermsModal(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text.rich(
                            TextSpan(
                              text: l10n.localeName == 'es'
                                  ? 'Al continuar con Google, aceptas nuestros '
                                  : 'By continuing with Google, you agree to our ',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withAlpha(130),
                                height: 1.3,
                              ),
                              children: [
                                TextSpan(
                                  text: l10n.termsConditions,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                          },
                          child: Text(l10n.noAccountRegister, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _GuestFormScreen extends StatefulWidget {
  const _GuestFormScreen();

  @override
  State<_GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends State<_GuestFormScreen> {
  final _nameController = TextEditingController();
  bool _isEntering = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startGuestLogin() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isEntering = true);
    try {
      await FirebaseService().loginAnonymously();
      if (mounted) {
        context.read<DataService>().setUserName(name);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEntering = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isEntering ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface.withAlpha(150), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: _LanguageSelectorButton(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isEntering 
          ? const _EnteringNestView(message: "Preparando tu perfil...")
          : Center(
              key: const ValueKey('form'),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24.0 : 32.0,
                  vertical: 24.0,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 480 : double.infinity,
                  ),
                  decoration: isLargeScreen
                      ? BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(60),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        )
                      : null,
                  padding: EdgeInsets.all(isLargeScreen ? 36.0 : 0.0),
                  child: Column(
                    children: [
                      const Hero(tag: 'app_logo', child: NestIcon(size: 140)),
                      const SizedBox(height: 36),
                      _LoginTextField(
                        controller: _nameController,
                        hint: l10n.tellUsYourName,
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 24),
                      _PrimaryButton(
                        label: l10n.startNow,
                        onPressed: _startGuestLogin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _EnteringNestView extends StatelessWidget {
  final String message;
  const _EnteringNestView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NestIcon(size: 100),
          const SizedBox(height: 48),
          const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Botón / Atajo de Selección de Idioma
class _LanguageSelectorButton extends StatelessWidget {
  const _LanguageSelectorButton();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentLocale = dataService.appLocale.value;
    final isSpanish = currentLocale.languageCode == 'es';

    return PopupMenuButton<String>(
      tooltip: isSpanish ? 'Cambiar idioma' : 'Change language',
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      onSelected: (langCode) {
        dataService.appLocale.value = Locale(langCode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              isSpanish ? 'Español' : 'English',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colorScheme.onSurface.withAlpha(150),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'es',
          child: Row(
            children: [
              const Text('🇪🇸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                'Español',
                style: TextStyle(
                  fontWeight: isSpanish ? FontWeight.bold : FontWeight.normal,
                  color: isSpanish ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (isSpanish) ...[
                const Spacer(),
                Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              const Text('🇺🇸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                'English',
                style: TextStyle(
                  fontWeight: !isSpanish ? FontWeight.bold : FontWeight.normal,
                  color: !isSpanish ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (!isSpanish) ...[
                const Spacer(),
                Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Componentes Reutilizables
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? colorScheme.primary : colorScheme.surfaceContainerHigh,
        foregroundColor: isPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
        minimumSize: const Size(double.infinity, 60),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isPrimary ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  const _LoginTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(100), fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(30)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _PrimaryButton({
    required this.label, 
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)),
            )
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SocialButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: isLoading 
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png', 
                height: 20,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.continueWithGoogle,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
    );
  }
}

class _LastAccountCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;

  const _LastAccountCard({required this.name, required this.email, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => _LoginFormScreen(initialEmail: email),
        ));
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: name,
              photoUrl: photoUrl,
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(email, style: TextStyle(color: theme.hintColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
