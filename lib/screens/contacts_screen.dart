import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import '../models/contact.dart';
import 'qr_scanner_screen.dart';
import 'add_reminder_screen.dart';
import 'note_editor_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showContactProfile(Contact contact) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              
              // Large Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2),
                ),
                child: contact.photoUrl != null 
                  ? ClipOval(child: Image.network(contact.photoUrl!, fit: BoxFit.cover))
                  : Icon(Icons.person, color: colorScheme.primary, size: 60),
              ),
              const SizedBox(height: 16),
              Text(
                contact.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                '@${contact.alias}',
                style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4), fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              // Social Options
              _buildProfileAction(
                icon: Icons.notifications_active_outlined,
                label: l10n.createJointReminder,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddReminderScreen(
                        initialSharedWith: [contact.name],
                      ),
                    ),
                  );
                },
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildProfileAction(
                icon: Icons.edit_note_rounded,
                label: l10n.createSharedNote,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorScreen(
                        initialSharedWith: [contact.name],
                      ),
                    ),
                  );
                },
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildProfileAction(
                icon: Icons.assignment_outlined,
                label: l10n.inviteToProject,
                onTap: () {
                  Navigator.pop(context);
                  _showProjectSelectionDialog(contact);
                },
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildProfileAction(
                icon: Icons.person_remove_outlined,
                label: l10n.deleteContact,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteContact(contact);
                },
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : colorScheme.primary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _confirmDeleteContact(Contact contact) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = context.read<DataService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: Text('¿Estás seguro de que quieres eliminar a ${contact.name} de tu lista de contactos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              dataService.removeContact(contact.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${contact.name} eliminado')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showProjectSelectionDialog(Contact contact) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = context.read<DataService>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final projects = dataService.projects.where((p) => !p.isArchived).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.selectProject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  l10n.noActiveProjects,
                  style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final bool alreadyMember = project.members.contains(contact.name); // Or use ID if available

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${project.members.length} miembros'),
                        trailing: alreadyMember 
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : Icon(Icons.add_circle_outline, color: colorScheme.primary),
                        onTap: alreadyMember ? null : () {
                          final updatedMembers = List<String>.from(project.members)..add(contact.name);
                          dataService.updateProject(project.copyWith(members: updatedMembers));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invitación enviada a ${contact.name}')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _searchUserById(String id) async {
    final fb = FirebaseService();
    final String cleanId = id.trim().toUpperCase();
    
    if (cleanId == fb.nestId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes agregarte a ti mismo')),
      );
      return;
    }
    
    // Mostramos un indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userData = await fb.getUserByNestId(cleanId);
      
      if (mounted) {
        Navigator.pop(context); // Quitar loading
        
        if (userData != null) {
          _showFoundUserProfile(userData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no encontrado')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e')),
        );
      }
    }
  }

  void _showFoundUserProfile(Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2),
              ),
              child: userData['photoUrl'] != null 
                ? ClipOval(child: Image.network(userData['photoUrl'], fit: BoxFit.cover))
                : Icon(Icons.person, color: colorScheme.primary, size: 60),
            ),
            const SizedBox(height: 16),
            Text(
              userData['username'] ?? 'Usuario',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '@${userData['alias'] ?? 'nest_user'}',
              style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4), fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final dataService = context.read<DataService>();
                  
                  if (dataService.contacts.any((c) => c.id == userData['uid'])) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Este usuario ya está en tus contactos')),
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

                  await dataService.sendFriendRequest(newContact);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Solicitud enviada a ${newContact.name}')),
                    );
                  }
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text("Añadir Contacto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dataService = context.watch<DataService>();

    final List<Contact> allContacts = dataService.contacts;

    final filteredContacts = allContacts.where((contact) {
      final name = contact.name.toLowerCase();
      final handle = contact.alias.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || handle.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.contacts,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: l10n.searchUsersHint,
                  hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner_rounded, color: colorScheme.primary),
                    onPressed: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                      );
                      if (result != null && context.mounted) {
                        _searchController.text = result;
                        setState(() => _searchQuery = result);
                        _searchUserById(result);
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  if (val.toUpperCase().startsWith('N-')) {
                    _searchUserById(val);
                  }
                },
              ),
            ),
          ),
          if (dataService.friendRequests.isNotEmpty && _searchQuery.isEmpty)
            _buildPendingRequestsSection(dataService),
          Expanded(
            child: _buildContactsList(filteredContacts, colorScheme, isDark, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection(DataService dataService) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SOLICITUDES PENDIENTES (${dataService.friendRequests.length})",
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...dataService.friendRequests.map((req) => _buildRequestTile(req, dataService, colorScheme, isDark)),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildRequestTile(dynamic req, DataService dataService, ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            backgroundImage: req.fromPhoto != null ? NetworkImage(req.fromPhoto!) : null,
            child: req.fromPhoto == null ? Icon(Icons.person, color: colorScheme.primary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.fromName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('@${req.fromAlias}', style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
              ],
            ),
          ),
          IconButton(
            onPressed: () => dataService.acceptFriendRequest(req),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: "Aceptar",
          ),
          IconButton(
            onPressed: () => dataService.rejectFriendRequest(req.id),
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            tooltip: "Rechazar",
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<Contact> filteredContacts, ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final bool looksLikeId = _searchQuery.toUpperCase().startsWith('N-');

    if (filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (looksLikeId) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_add_rounded, size: 48, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                "¿Añadir por ID: $_searchQuery?",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _searchUserById(_searchQuery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Buscar y Añadir"),
              ),
            ] else ...[
              Icon(Icons.person_search_rounded, size: 64, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
              const SizedBox(height: 16),
              Text(
                l10n.noResultsFound,
                style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredContacts.length + (looksLikeId ? 1 : 0),
      itemBuilder: (context, index) {
        if (looksLikeId && index == 0) {
          return _buildAddByIdTile(colorScheme, isDark);
        }
        final contact = filteredContacts[looksLikeId ? index - 1 : index];
        return _buildContactTile(contact, colorScheme, isDark);
      },
    );
  }

  Widget _buildAddByIdTile(ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: const Icon(Icons.person_add_rounded, color: Colors.white),
        ),
        title: Text(
          "Añadir por ID: $_searchQuery",
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("Toca para buscar este usuario"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _searchUserById(_searchQuery),
      ),
    );
  }

  Widget _buildContactTile(Contact contact, ColorScheme colorScheme, bool isDark) {
    // Para simplificar, asumimos que todos están 'En línea' o quitamos el estado por ahora
    const statusColor = Colors.green; 

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: contact.photoUrl != null 
                ? ClipOval(child: Image.network(contact.photoUrl!, fit: BoxFit.cover))
                : Icon(Icons.person, color: colorScheme.primary, size: 30),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF0A0A0A) : Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '@${contact.alias}',
          style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 13),
        ),
        onTap: () => _showContactProfile(contact),
      ),
    );
  }
}
