import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../widgets/nest_icon.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import '../services/data_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDate;
  bool _isPasswordVisible = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      final alias = _usernameController.text.trim();
      if (alias.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor elige un alias')),
        );
        return;
      }

      if (alias.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El alias debe tener al menos 3 caracteres')),
        );
        return;
      }

      // Check alias availability
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final isAvailable = await FirebaseService().isAliasAvailable(alias);
        if (mounted) Navigator.pop(context); // Close loading

        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Este alias ya está en uso. Por favor elige otro.')),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
      }
    }

    if (_currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _completeRegistration() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final dob = _dobController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor rellena los campos obligatorios')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final firebaseService = FirebaseService();
      final userCredential = await firebaseService.registerWithEmail(email, password);
      
      if (userCredential.user != null) {
        // Guardar perfil en Firestore
        await firebaseService.saveUserProfile(userCredential.user!.uid, {
          'username': name, // Name goes to 'username' as requested
          'alias': username, // Handle goes to 'alias'
          'dob': _selectedDate != null ? _selectedDate!.toIso8601String() : dob,
          'email': email,
          'isGuest': false,
          'profileCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          final dataService = context.read<DataService>();
          dataService.setUserName(name);
          dataService.setUserAlias(username);
          if (_selectedDate != null) {
            dataService.setUserBirthday(_selectedDate!);
          }
          dataService.setProfileCompleted(true);
          
          Navigator.of(context).pop(); // Cerrar loading
          // Volvemos al inicio de la navegación y AppStartupGate hará el resto
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading
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
        case 'email-already-in-use':
          return 'Este correo electrónico ya está registrado. Inicia sesión o utiliza otro correo.';
        case 'invalid-email':
          return 'El formato del correo electrónico no es válido.';
        case 'weak-password':
          return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
        case 'operation-not-allowed':
          return 'El registro por correo electrónico no está habilitado actualmente.';
        case 'network-request-failed':
          return 'Error de conexión. Revisa tu acceso a internet.';
        default:
          return error.message ?? 'Error al crear la cuenta. Inténtalo nuevamente.';
      }
    }
    return error.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
          onPressed: _previousStep,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(
              child: Text(
                '${_currentStep + 1}/2',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progreso superior
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 2,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepOne(context),
                _buildStepTwo(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOne(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 520 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Hero(
                tag: 'app_logo',
                child: NestIcon(size: 60),
              ),
          const SizedBox(height: 32),
          Text(
            l10n.weWantToKnowYou,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.tellUsWhoYouAre,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withAlpha(150),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          _buildTextField(
            label: l10n.fullName,
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            hint: l10n.writeYourName,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Alias',
            controller: _usernameController,
            icon: Icons.alternate_email_rounded,
            hint: '@tu_alias',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: l10n.dob,
            controller: _dobController,
            icon: Icons.calendar_today_rounded,
            hint: l10n.selectDate,
            onTap: _selectDate,
          ),
          const SizedBox(height: 48),
          _buildPrimaryButton(
            label: l10n.continueLabel,
            onPressed: _nextStep,
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildStepTwo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 520 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded, color: colorScheme.primary, size: 32),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.accountSecurity,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.securityDesc,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withAlpha(150),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              _buildTextField(
                label: l10n.email,
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: 'tu@email.com',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: l10n.password,
                controller: _passwordController,
                icon: Icons.key_rounded,
                hint: 'Mínimo 8 caracteres',
                isPassword: true,
                obscureText: !_isPasswordVisible,
                onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              const SizedBox(height: 48),
              _buildPrimaryButton(
                label: l10n.finishRegistration,
                onPressed: _completeRegistration,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  l10n.termsAgreed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onTap: onTap,
          readOnly: onTap != null,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(80)),
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
