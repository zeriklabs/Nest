import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/group_post.dart';
import '../models/group_poll.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../services/data_service.dart';
import 'note_editor_screen.dart';
import 'reminder_details_screen.dart';
import 'group_settings_screen.dart';
import 'create_post_screen.dart';
import 'add_reminder_screen.dart';
import 'create_poll_screen.dart';

import '../models/group_comment.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettingsScreen(groupId: group.id),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGroupInfo(group, isDark, colorScheme),
          const Divider(height: 1),
          Expanded(
            child: _buildWall(group, dataService, isDark, colorScheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'group_details_fab',
        backgroundColor: group.color,
        onPressed: () => _showAddContentOptions(context, group),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupInfo(Group group, bool isDark, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final groupColor = group.color;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: groupColor.withOpacity(0.1),
            backgroundImage: group.imagePath != null ? NetworkImage(group.imagePath!) : null,
            child: group.imagePath == null ? Icon(Icons.groups_rounded, size: 40, color: groupColor) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.membersCount(group.members.length), 
                  style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
                const SizedBox(height: 4),
                Text(l10n.inviteCodeShort(group.inviteCode), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWall(Group group, DataService dataService, bool isDark, ColorScheme colorScheme) {
    List<Map<String, dynamic>> items = [];
    for (var post in group.posts) {
      items.add({'type': 'post', 'item': post, 'time': post.timestamp});
    }
    for (var poll in group.polls) {
      items.add({'type': 'poll', 'item': poll, 'time': poll.timestamp});
    }
    for (var note in group.sharedNotes) {
      items.add({'type': 'note', 'item': note, 'time': note.createdAt});
    }
    for (var reminder in group.sharedReminders) {
      items.add({'type': 'reminder', 'item': reminder, 'time': reminder.dateTime});
    }

    items.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    if (items.isEmpty && group.legacyPosts.isEmpty) return _buildEmptyState('No hay actividad aún');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (group.legacyPosts.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < items.length) {
          final data = items[index];
          return _buildWallItem(context, data, isDark, colorScheme, dataService, group);
        }
        return _buildLegacyPostsButton(context, group, isDark, colorScheme, dataService);
      },
    );
  }

  Widget _buildLegacyPostsButton(BuildContext context, Group group, bool isDark, ColorScheme colorScheme, DataService dataService) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Center(
        child: TextButton.icon(
          onPressed: () => _showLegacyPostsSheet(context, group, isDark, colorScheme, dataService),
          icon: const Icon(Icons.history_rounded),
          label: const Text('Ver publicaciones de la versión anterior'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: colorScheme.primary.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  void _showLegacyPostsSheet(BuildContext context, Group group, bool isDark, ColorScheme colorScheme, DataService dataService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: colorScheme.primary),
                  const SizedBox(width: 16),
                  const Text('Archivo de Mensajes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: group.legacyPosts.length,
                itemBuilder: (context, index) {
                  final post = group.legacyPosts[index];
                  return _buildWallItem(
                    context, 
                    {'type': 'post', 'item': post, 'time': post.timestamp}, 
                    isDark, 
                    colorScheme, 
                    dataService, 
                    group
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallItem(BuildContext context, Map<String, dynamic> data, bool isDark, ColorScheme colorScheme, DataService dataService, Group group) {
    final type = data['type'];
    final item = data['item'];
    final time = data['time'] as DateTime;

    String authorId = 'Anónimo';
    Map<String, List<String>> reactions = {};
    if (type == 'post') {
      final i = item as GroupPost; authorId = i.author; reactions = i.reactions;
    } else if (type == 'poll') {
      final i = item as GroupPoll; authorId = i.author; reactions = i.reactions;
    } else if (type == 'note') {
      final i = item as Note; authorId = i.author; reactions = i.reactions;
    } else if (type == 'reminder') {
      final i = item as Reminder; authorId = i.author; reactions = i.reactions;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => _handleItemTap(context, type, item),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Quien lo publica
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: dataService.getUserProfile(authorId),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final String name = profile?['username'] ?? profile?['name'] ?? profile?['displayName'] ?? (authorId == dataService.userId ? dataService.userName : 'Usuario');
                  
                  final bool isAdmin = group.admins.contains(dataService.userId);
                  final bool isAuthor = authorId == dataService.userId;
                  final bool canDelete = isAdmin || isAuthor;

                  final l10n = AppLocalizations.of(context)!;
                  String headerText = name;
                  if (type == 'note') headerText = l10n.sharedANote(name);
                  else if (type == 'reminder') headerText = l10n.addedAReminder(name);
                  else if (type == 'poll') headerText = l10n.startedAPoll(name);

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(headerText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(DateFormat('dd/MM HH:mm').format(time), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      if (canDelete)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey[400]),
                          onSelected: (val) {
                            if (val == 'delete') {
                              _showDeleteConfirmation(context, dataService, group.id, item.id, type);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  SizedBox(width: 10),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),

            _buildItemContent(context, type, item, isDark, colorScheme, dataService, group),

            // Resumen de reacciones si las hay
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 6,
                  children: reactions.entries.map((e) {
                    final isUserReaction = e.value.contains(dataService.userId);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUserReaction ? colorScheme.primary.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isUserReaction ? colorScheme.primary.withOpacity(0.3) : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text('${e.value.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUserReaction ? colorScheme.primary : null)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Pie: Tipo de publicación y Acciones sociales
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Etiqueta de tipo abajo
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getIconForType(type), size: 12, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _getTypeLabel(type), 
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary, letterSpacing: 0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildSocialActions(context, group.id, type, item, dataService, isDark, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialActions(BuildContext context, String groupId, String type, dynamic item, DataService dataService, bool isDark, ColorScheme colorScheme) {
    List<GroupComment> comments = [];
    String itemId = '';
    Map<String, List<String>> reactions = {};

    if (type == 'post') {
      final i = item as GroupPost; comments = i.comments; itemId = i.id; reactions = i.reactions;
    } else if (type == 'poll') {
      final i = item as GroupPoll; comments = i.comments; itemId = i.id; reactions = i.reactions;
    } else if (type == 'note') {
      final i = item as Note; comments = i.comments; itemId = i.id; reactions = i.reactions;
    } else if (type == 'reminder') {
      final i = item as Reminder; comments = i.comments; itemId = i.id; reactions = i.reactions;
    }

    final bool hasMyReaction = reactions.values.any((users) => users.contains(dataService.userId));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (buttonContext) => InkWell(
            onTap: () => _showReactionPicker(buttonContext, groupId, itemId, type, dataService),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Icon(hasMyReaction ? Icons.add_reaction_rounded : Icons.add_reaction_outlined, 
                    size: 18, color: hasMyReaction ? colorScheme.primary : Colors.grey[600]),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => _showCommentsSheet(context, groupId, itemId, type, comments, dataService),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey[600]),
                if (comments.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text('${comments.length}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReactionPicker(BuildContext context, String groupId, String itemId, String type, DataService dataService) {
    final emojis = ['❤️', '👍', '😂', '😮', '😢', '🔥', '👏', '✅'];
    
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final size = MediaQuery.of(context).size;
    
    // Ancho dinámico del selector basado en la pantalla, máx 380px
    double pickerWidth = 380.0;
    if (pickerWidth > size.width - 24) {
      pickerWidth = size.width - 24;
    }
    
    // Calcular el left asegurando que no se salga de la pantalla
    double leftPosition = position.dx - (pickerWidth / 2);
    if (leftPosition < 12) leftPosition = 12;
    if (leftPosition + pickerWidth > size.width - 12) {
      leftPosition = size.width - pickerWidth - 12;
    }

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => entry?.remove(),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: leftPosition,
            bottom: size.height - position.dy + 8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: pickerWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(35), // Un poco más redondo
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25), 
                      blurRadius: 20, 
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: emojis.map((e) => GestureDetector(
                    onTap: () {
                      dataService.toggleReaction(groupId, itemId, type, e);
                      entry?.remove();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(e, style: const TextStyle(fontSize: 26)), // Emojis más grandes
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(entry);
  }

  void _showCommentsSheet(BuildContext context, String groupId, String itemId, String type, List<GroupComment> comments, DataService dataService) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(l10n.comments, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Expanded(
              child: comments.isEmpty
                ? Center(
                    child: Text(l10n.noCommentsYet, style: const TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: dataService.getUserProfile(comment.author),
                          builder: (context, snapshot) {
                            final profile = snapshot.data;
                            final name = profile?['username'] ?? profile?['name'] ?? profile?['displayName'] ?? (comment.author == dataService.userId ? dataService.userName : 'Usuario');

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 14, child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 10))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(width: 8),
                                          Text(DateFormat('dd/MM HH:mm').format(comment.timestamp), style: TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                      Text(comment.text, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: l10n.writeCommentHint, border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.blue),
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        dataService.addComment(groupId, itemId, type, controller.text.trim());
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemTap(BuildContext context, String type, dynamic item) {
    if (type == 'note') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => NoteEditorScreen(note: item as Note)));
    } else if (type == 'reminder') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderDetailsScreen(reminder: item as Reminder)));
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'post': return Icons.chat_bubble_outline_rounded;
      case 'poll': return Icons.poll_rounded;
      case 'note': return Icons.note_alt_rounded;
      case 'reminder': return Icons.alarm_rounded;
      default: return Icons.info_outline;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'post': return 'PUBLICACIÓN';
      case 'poll': return 'ENCUESTA';
      case 'note': return 'NOTA';
      case 'reminder': return 'RECORDATORIO';
      default: return 'INFO';
    }
  }

  Widget _buildItemContent(BuildContext context, String type, dynamic item, bool isDark, ColorScheme colorScheme, DataService dataService, Group group) {
    switch (type) {
      case 'post':
        final post = item as GroupPost;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(post.content),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length,
                    itemBuilder: (context, idx) => Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: (post.images[idx].startsWith('http') || post.images[idx].startsWith('blob:') || kIsWeb)
                              ? NetworkImage(post.images[idx])
                              : FileImage(File(post.images[idx])) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case 'poll':
        final poll = item as GroupPoll;
        final totalVotes = poll.options.fold<int>(0, (sum, opt) => sum + opt.votes);
        final hasVoted = poll.options.any((opt) => opt.votedBy.contains(dataService.userId));
        final isExpired = poll.isExpired;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(poll.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('FINALIZADA', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (poll.description != null) ...[
                const SizedBox(height: 4),
                Text(poll.description!, style: TextStyle(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
              ],
              if (poll.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: poll.images.length,
                    itemBuilder: (context, idx) => Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: (poll.images[idx].startsWith('http') || poll.images[idx].startsWith('blob:') || kIsWeb)
                              ? NetworkImage(poll.images[idx])
                              : FileImage(File(poll.images[idx])) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...poll.options.asMap().entries.map((entry) {
                final optIndex = entry.key;
                final option = entry.value;
                final percent = totalVotes == 0 ? 0.0 : option.votes / totalVotes;
                final isSelected = option.votedBy.contains(dataService.userId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: (hasVoted || isExpired) ? null : () => dataService.voteInPoll(group.id, poll.id, optIndex, dataService.userId ?? ''),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.3),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.text, 
                                style: TextStyle(
                                  fontSize: 13, 
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: (hasVoted || isExpired) && !isSelected ? (isDark ? Colors.white : Colors.black).withOpacity(0.5) : null,
                                ),
                              ),
                            ),
                            Text(
                              '${(percent * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: percent,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.5),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text('$totalVotes votos', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ),
                  const Spacer(),
                  if (!isExpired && poll.expiresAt != null)
                    Flexible(
                      child: Text(
                        'Cierra en ${_formatRemainingTime(poll.expiresAt!)}',
                        style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      case 'note':
        final note = item as Note;
        final bool hasTitle = note.title.isNotEmpty && note.title != 'Sin título' && note.title != 'Nota rápida' && note.title != 'Nota de sesión';
        final isNoteDark = note.backgroundColor != null 
            ? note.backgroundColor!.computeLuminance() < 0.5 
            : isDark;
        final textColor = isNoteDark ? Colors.white : Colors.black;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: note.backgroundColor ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasTitle) ...[
                                Text(
                                  note.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: textColor.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                note.previewText.isEmpty ? 'Sin contenido' : note.previewText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                                maxLines: 8,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: Icon(Icons.download_for_offline_rounded, color: textColor.withValues(alpha: 0.4)),
                            tooltip: 'Importar a mis notas',
                            onPressed: () => _importNote(context, note, dataService),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'reminder':
        final reminder = item as Reminder;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Fecha límite: ${reminder.date}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_task_rounded, color: Colors.green),
                tooltip: 'Añadir a mi lista',
                onPressed: () => _importReminder(context, reminder, dataService),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _importNote(BuildContext context, Note note, DataService dataService) {
    final newNote = Note(
      id: Uuid().v4(),
      title: note.title,
      content: note.content,
      backgroundColor: note.backgroundColor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notebookId: null,
      pageType: note.pageType,
    );
    final l10n = AppLocalizations.of(context)!;
    dataService.addNote(newNote);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noteImportedToPersonal)));
  }

  void _importReminder(BuildContext context, Reminder reminder, DataService dataService) {
    final l10n = AppLocalizations.of(context)!;
    final newReminder = Reminder(
      id: Uuid().v4(),
      title: reminder.title,
      date: reminder.date,
      time: reminder.time,
      category: reminder.category,
      location: reminder.location,
      description: reminder.description,
      dateTime: reminder.dateTime,
    );
    dataService.addReminder(newReminder);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reminderAddedToPersonal)));
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showAddContentOptions(BuildContext context, Group group) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.post_add_rounded),
            title: Text(l10n.newPost),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostScreen(groupId: group.id)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_add_rounded),
            title: Text(l10n.shareNote),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(groupId: group.id),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_add_rounded),
            title: Text(l10n.shareReminder),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddReminderScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.poll_rounded),
            title: Text(l10n.newPoll),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => CreatePollScreen(groupId: group.id))
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime(DateTime expiresAt) {
    final difference = expiresAt.difference(DateTime.now());
    if (difference.isNegative) return 'Finalizada';
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'segundos';
  }

  void _showDeleteConfirmation(BuildContext context, DataService dataService, String groupId, String itemId, String type) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePostConfirmTitle),
        content: Text(l10n.deletePostConfirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              dataService.deleteItemFromGroup(groupId, itemId, type);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
