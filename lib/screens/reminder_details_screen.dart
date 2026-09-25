import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/reminder.dart';
import '../services/data_service.dart';
import '../models/subject.dart';
import 'add_reminder_screen.dart';

class ReminderDetailsScreen extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback? onBack;

  const ReminderDetailsScreen({super.key, required this.reminder, this.onBack});

  @override
  State<ReminderDetailsScreen> createState() => _ReminderDetailsScreenState();
}

class _ReminderDetailsScreenState extends State<ReminderDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = context.watch<DataService>();
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    
    // Find the current reminder in DataService to ensure we have the latest data
    Reminder reminder;
    try {
      reminder = dataService.reminders.firstWhere((r) => r.id == widget.reminder.id);
    } catch (_) {
      // Fallback if not found (e.g. just deleted), though build might still run once
      reminder = widget.reminder;
    }
    
    // Find associated subject if exists
    Subject? subject;
    if (reminder.subjectId != null) {
      try {
        subject = dataService.subjects.firstWhere((s) => s.id == reminder.subjectId);
      } catch (_) {
        subject = null;
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF050505) : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (canPop) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReminderScreen(reminderToEdit: reminder),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _showDeleteConfirmation(context, l10n, reminder.id),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeader(reminder, colorScheme, isDark, l10n),
              const SizedBox(height: 32),
              _buildDetailSection(
                context,
                icon: Icons.calendar_today_rounded,
                label: l10n.dateTimeLabel,
                value: reminder.isAllDay 
                    ? '${reminder.date} (${l10n.allDayLabel})' 
                    : '${reminder.date}${reminder.time != null ? ' ${l10n.atTime} ${reminder.time}' : ''}',
                isDark: isDark,
              ),
              if (reminder.location != null && reminder.location!.isNotEmpty)
                _buildDetailSection(
                  context,
                  icon: Icons.location_on_outlined,
                  label: l10n.place,
                  value: reminder.location!,
                  isDark: isDark,
                ),
              _buildDetailSection(
                context,
                icon: Icons.category_outlined,
                label: l10n.categoryLabel,
                value: _getCategoryLabel(reminder.category, l10n),
                isDark: isDark,
                trailing: reminder.isUrgent 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l10n.urgent.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  : null,
              ),
              if (subject != null)
                _buildDetailSection(
                  context,
                  icon: Icons.tag_rounded,
                  label: l10n.linkSubject,
                  value: subject.name,
                  isDark: isDark,
                  iconColor: subject.color,
                ),
              if (reminder.description != null && reminder.description!.isNotEmpty)
                _buildDescriptionSection(reminder.description!, isDark, l10n),
              if (reminder.attachments.isNotEmpty)
                _buildAttachmentsSection(reminder.attachments, isDark, colorScheme, l10n),
              if (reminder.sharedWith.isNotEmpty)
                _buildSharedSection(reminder.sharedWith, isDark, colorScheme, l10n),
              const SizedBox(height: 120),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: _buildCompletionButton(reminder, colorScheme, l10n, dataService),
        ),
      ),
    );
  }

  String _getCategoryLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'Recordatorio': return l10n.reminder;
      case 'Tarea': return l10n.task;
      case 'Proyecto': return l10n.project;
      case 'Examen': return l10n.exam;
      case 'Evento': return l10n.event;
      default: return key;
    }
  }

  Widget _buildHeader(Reminder reminder, ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _getCategoryLabel(reminder.category, l10n).toUpperCase(),
            style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          reminder.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? (isDark ? Colors.white : Colors.black)).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor ?? (isDark ? Colors.white70 : Colors.black54), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String description, bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.descriptionLabel.toUpperCase(),
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Text(
              description,
              style: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(List<String> attachments, bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.attachmentsLabel.toUpperCase(),
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                final path = attachments[index];
                final fileName = path.split('/').last;
                final isImage = ['.jpg', '.jpeg', '.png'].any((ext) => fileName.toLowerCase().endsWith(ext));

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          fileName,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedSection(List<String> sharedWith, bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sharedWithLabel.toUpperCase(),
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: sharedWith.map((name) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: colorScheme.primary,
                  child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCompletionButton(Reminder reminder, ColorScheme colorScheme, AppLocalizations l10n, DataService dataService) {
    if (reminder.category == 'Evento') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: reminder.isCompleted ? Colors.green.withOpacity(0.1) : colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: reminder.isCompleted ? [] : [
          BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: InkWell(
        onTap: () {
          final isCompleting = !reminder.isCompleted;
          final updatedReminder = reminder.copyWith(
            isCompleted: isCompleting,
            completedAt: isCompleting ? DateTime.now() : null,
            clearCompletedAt: !isCompleting,
          );
          dataService.updateReminder(updatedReminder);
        },
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                reminder.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: reminder.isCompleted ? Colors.green : Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                reminder.isCompleted ? l10n.completed : l10n.markAsCompleted,
                style: TextStyle(
                  color: reminder.isCompleted ? Colors.green : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppLocalizations l10n, String reminderId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.deleteReminderConfirm, 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.deleteReminderConfirmDesc, 
          style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (widget.onBack != null) {
                // If on tablet/embedded, we handle deletion through DataService and close panel
                Provider.of<DataService>(context, listen: false).deleteReminder(reminderId);
                widget.onBack!();
              } else {
                Navigator.pop(context, 'delete'); // Return to list with delete signal for mobile
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
