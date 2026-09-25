import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/data_service.dart';
import '../models/contact.dart';
import '../widgets/nest_icon.dart';
import 'qr_scanner_screen.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _searchUser(String val, String myNestId) async {
    final l10n = AppLocalizations.of(context)!;
    final cleanVal = val.trim().toUpperCase();
    if (cleanVal.isEmpty) return;
    
    if (cleanVal == myNestId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotAddSelf), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    try {
      final fb = FirebaseService();
      final userData = await fb.getUserByNestId(cleanVal);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          _foundUser = userData;
        });
        
        if (userData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userNotFound), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _addContact(Map<String, dynamic> userData) async {
    final l10n = AppLocalizations.of(context)!;
    final dataService = context.read<DataService>();
    
    // Check if already in contacts
    if (dataService.contacts.any((c) => c.id == userData['uid'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userAlreadyInContacts)),
      );
      return;
    }

    final newContact = Contact(
      id: userData['uid'],
      nestId: userData['userIdentifier'] ?? userData['useridentifier'] ?? '',
      name: userData['username'] ?? 'Usuario',
      alias: userData['alias'] ?? 'nest_user',
      photoUrl: userData['photoUrl'],
      addedAt: DateTime.now(),
    );

    await dataService.addContact(newContact);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addedToContacts(newContact.name))),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildFoundUserCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: _foundUser!['photoUrl'] != null 
              ? ClipOval(child: Image.network(_foundUser!['photoUrl'], fit: BoxFit.cover))
              : Icon(Icons.person, color: colorScheme.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            _foundUser!['username'] ?? 'Usuario',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '@${_foundUser!['alias'] ?? 'nest_user'}',
            style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addContact(_foundUser!),
            icon: const Icon(Icons.person_add_rounded),
            label: Text(l10n.addToMyContacts),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fb = FirebaseService();
    final String myNestId = fb.nestId;
    final String? userPhotoUrl = fb.userPhotoUrl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Usamos resizeToAvoidBottomInset: true para que el scroll funcione, 
      // pero simplificamos la UI para que sea más fluida.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.addFriend,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Input simplificado (menos capas de decoración)
                  TextField(
                    controller: _idController,
                    onSubmitted: (val) => _searchUser(val, myNestId),
                    decoration: InputDecoration(
                      hintText: l10n.nestIdHint,
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      prefixIcon: Icon(Icons.alternate_email_rounded, color: colorScheme.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        onPressed: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                          );
                          if (result != null && context.mounted) {
                            _idController.text = result;
                            _searchUser(result, myNestId);
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (_foundUser != null)
                    _buildFoundUserCard(colorScheme, isDark)
                  else
                    // QR Card simplificada
                    Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.01),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.myNestId.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // QR Code
                        RepaintBoundary(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: myNestId,
                                version: QrVersions.auto,
                                size: 180.0,
                                foregroundColor: colorScheme.primary,
                                gapless: false,
                                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: colorScheme.primary),
                                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: colorScheme.primary),
                              ),
                              // Profile Image with small Nest Badge
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: colorScheme.primaryContainer,
                                        backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                                        child: userPhotoUrl == null ? Icon(Icons.person, color: colorScheme.primary, size: 24) : null,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        child: const NestIcon(size: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Botón de ID estilo chip para copiar
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: myNestId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.idCopied), duration: const Duration(seconds: 1)),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  myNestId,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.copy_rounded, size: 16, color: colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón de acción fijo pero fuera del bottomNavigationBar para evitar lag de resize
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () => _searchUser(_idController.text, myNestId),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(l10n.searchUser, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
