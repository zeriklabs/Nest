import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final group = dataService.groups.firstWhereOrNull((g) => g.id == widget.groupId);

    if (group == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.maybePop(context);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final bool isUserAdmin = group.admins.contains(dataService.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupSettings, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildGroupHeader(group, colorScheme, isDark),
          const SizedBox(height: 30),
          _buildSectionTitle(l10n.general),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: Text(l10n.groupName),
            subtitle: Text(group.name),
            trailing: isUserAdmin ? const Icon(Icons.chevron_right_rounded) : null,
            onTap: isUserAdmin ? () => _showRenameDialog(context, group, dataService) : null,
          ),
          ListTile(
            leading: Icon(Icons.palette_rounded, color: group.color),
            title: Text(l10n.groupColor),
            trailing: isUserAdmin ? const Icon(Icons.chevron_right_rounded) : null,
            onTap: isUserAdmin ? () => _showColorPickerDialog(context, group, dataService) : null,
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_rounded),
            title: Text(l10n.inviteCode),
            subtitle: Text(group.inviteCode),
            trailing: const Icon(Icons.copy_rounded, size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.codeCopied)),
              );
            },
          ),
          const Divider(),
          _buildSectionTitle('${l10n.members} (${group.members.length})'),
          ...group.members.map((member) {
            final bool isMemberAdmin = group.admins.contains(member);
            final bool isCurrentUser = member == dataService.userId;

            return FutureBuilder<Map<String, dynamic>?>(
              future: dataService.getUserProfile(member),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final String name = profile?['username'] ?? profile?['name'] ?? profile?['displayName'] ?? (isCurrentUser ? dataService.userName : 'Usuario');
                final String? alias = profile?['alias'] ?? (isCurrentUser ? dataService.userAlias : null);
                final String nestId = profile?['userIdentifier'] ?? (isCurrentUser && dataService.userIdentifier.isNotEmpty ? dataService.userIdentifier : 'N-${(member.hashCode).toString().padLeft(4, '0').substring(0, 4)}');

                final String firstLetter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Text(firstLetter, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                      if (isMemberAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Admin', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    (alias != null && alias.trim().isNotEmpty) ? '@$alias • $nestId' : nestId,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isUserAdmin && member != dataService.userId
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMemberAdmin)
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue, size: 20),
                                tooltip: l10n.makeAdmin,
                                onPressed: () => _promoteToAdmin(context, group, name, member, dataService),
                              ),
                            IconButton(
                              icon: const Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),
                              tooltip: l10n.removeFromGroup,
                              onPressed: () => _removeMember(context, group, name, member, dataService),
                            ),
                          ],
                        )
                      : null,
                );
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
            title: Text(l10n.leaveGroup, style: const TextStyle(color: Colors.red)),
            onTap: () => _showLeaveDialog(context, group, dataService),
          ),
          if (isUserAdmin)
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: Text(l10n.deleteGroup, style: const TextStyle(color: Colors.red)),
              onTap: () => _showDeleteDialog(context, group, dataService),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(Group group, ColorScheme colorScheme, bool isDark) {
    final groupColor = group.color;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: groupColor.withOpacity(0.1),
              backgroundImage: group.imagePath != null ? NetworkImage(group.imagePath!) : null,
              child: group.imagePath == null ? Icon(Icons.groups_rounded, size: 50, color: groupColor) : null,
            ),
            if (group.admins.contains(Provider.of<DataService>(context, listen: false).userId))
              GestureDetector(
                onTap: () => _updateGroupImage(context, group, Provider.of<DataService>(context, listen: false)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: groupColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF151515) : Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Group group, DataService dataService) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar grupo'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Nuevo nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                dataService.updateGroup(group.copyWith(name: controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context, Group group, DataService dataService) {
    final List<Color> availableColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona el color del grupo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: availableColors.length,
                itemBuilder: (context, index) {
                  final color = availableColors[index];
                  return GestureDetector(
                    onTap: () {
                      dataService.updateGroup(group.copyWith(color: color));
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: group.color == color ? Border.all(color: Colors.black, width: 3) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateGroupImage(BuildContext context, Group group, DataService dataService) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final fb = FirebaseService();
      final extension = image.path.split('.').last;
      final path = 'groups/${const Uuid().v4()}.$extension';
      
      // Show loading indicator or handle state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subiendo imagen...')),
      );

      final uploadedUrl = await fb.uploadFile(path, File(image.path));
      
      if (uploadedUrl != null) {
        dataService.updateGroup(group.copyWith(imagePath: uploadedUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen de grupo actualizada')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir la imagen')),
          );
        }
      }
    }
  }

  void _promoteToAdmin(BuildContext context, Group group, String name, String memberId, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombrar administrador'),
        content: Text('¿Quieres que $name sea también administrador de este grupo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              dataService.addAdminToGroup(group.id, memberId);
              Navigator.pop(context);
            },
            child: const Text('Nombrar Admin'),
          ),
        ],
      ),
    );
  }

  void _removeMember(BuildContext context, Group group, String name, String memberId, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text('¿Estás seguro de que quieres eliminar a $name del grupo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              dataService.leaveGroup(group.id, memberId);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, Group group, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text('¿Estás seguro de que quieres salir de este grupo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              dataService.leaveGroup(group.id, dataService.userId ?? '');
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Settings
              Navigator.pop(context); // Details
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Group group, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: const Text('¿Estás seguro de que quieres eliminar este grupo permanentemente? Todos los datos se perderán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              dataService.deleteGroup(group.id);
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Settings
              Navigator.pop(context); // Details
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
