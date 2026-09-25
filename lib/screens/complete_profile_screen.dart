import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import '../widgets/nest_icon.dart';
import '../main.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String initialName;
  final String? initialEmail;
  const CompleteProfileScreen({super.key, required this.initialName, this.initialEmail});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final dataService = context.read<DataService>();
    _nameController.text = widget.initialName;
    _emailController.text = widget.initialEmail ?? 
                           (dataService.userEmail.isNotEmpty ? dataService.userEmail : FirebaseService().userEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final alias = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || alias.isEmpty || _selectedDate == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    if (alias.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El alias debe tener al menos 3 caracteres')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fb = FirebaseService();
      final dataService = context.read<DataService>();
      
      // Check alias availability
      final isAvailable = await fb.isAliasAvailable(alias, excludeUserId: fb.userId);
      if (!isAvailable) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este alias ya está en uso. Por favor elige otro.')),
          );
        }
        return;
      }
      
      await fb.saveUserProfile(fb.userId!, {
        'username': name, // Name goes to 'username' as requested
        'alias': alias, // Handle goes to 'alias'
        'email': email,
        'dob': _selectedDate!.toIso8601String(),
        'profileCompleted': true,
      });

      dataService.setUserName(name);
      dataService.setUserEmail(email);
      dataService.setUserBirthday(_selectedDate!);
      dataService.setUserAlias(alias);
      dataService.setProfileCompleted(true);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: NestIcon(size: 80)),
              const SizedBox(height: 32),
              Text(
                l10n.almostReady(widget.initialName.split(' ')[0]),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.missingDetails,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                label: l10n.fullName,
                controller: _nameController,
                icon: Icons.person_rounded,
                hint: l10n.writeYourName,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: l10n.email,
                controller: _emailController,
                icon: Icons.email_rounded,
                hint: 'tu@email.com',
                readOnly: _emailController.text.isNotEmpty && _emailController.text.contains('@'),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Alias',
                controller: _usernameController,
                icon: Icons.alternate_email_rounded,
                hint: 'ej: @nest_user',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: l10n.dob,
                controller: _dobController,
                icon: Icons.calendar_today_rounded,
                hint: l10n.selectDate,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.finish,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
