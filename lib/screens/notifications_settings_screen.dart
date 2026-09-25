import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/web_notification_service.dart';
import '../services/data_service.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context);

    final bool allEnabled = dataService.allNotificationsEnabled;

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
          l10n.notifications,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;
          final double maxContentWidth = isWide ? 880 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32.0 : 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    // Switch Maestro
                    _buildSection(
                      context,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: allEnabled ? colorScheme.primary.withAlpha(25) : colorScheme.onSurface.withAlpha(25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              allEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                              color: allEnabled ? colorScheme.primary : colorScheme.onSurface.withAlpha(127),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.allowNotifications,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  allEnabled ? l10n.activated : l10n.disabled,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withAlpha(127),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: allEnabled,
                            activeThumbColor: colorScheme.primary,
                            onChanged: (value) {
                              dataService.setAllNotificationsEnabled(value);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, l10n.classStartWarnings),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: dataService.classRemindersEnabled && allEnabled
                                      ? colorScheme.primary.withAlpha(25)
                                      : colorScheme.onSurface.withAlpha(25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: dataService.classRemindersEnabled && allEnabled
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withAlpha(127),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.classStartWarnings,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      l10n.notifyBeforeClassStarts,
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withAlpha(127),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: dataService.classRemindersEnabled && allEnabled,
                                activeThumbColor: colorScheme.primary,
                                onChanged: allEnabled
                                    ? (value) => dataService.setClassRemindersEnabled(value)
                                    : null,
                              ),
                            ],
                          ),
                          if (dataService.classRemindersEnabled && allEnabled) ...[
                            const SizedBox(height: 20),
                            Divider(height: 1, color: colorScheme.outlineVariant.withAlpha(51)),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noticeAnticipation,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withAlpha(180),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [0, 5, 10, 15, 20, 30, 45, 60].map((minutes) {
                                final isSelected = dataService.classReminderMinutesBefore == minutes;
                                final label = minutes == 0
                                    ? l10n.atClassStart
                                    : (minutes == 60 ? l10n.oneHourBefore : l10n.minutesBefore(minutes));
                                return ChoiceChip(
                                  label: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: colorScheme.primary,
                                  backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(100),
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (_) {
                                    dataService.setClassReminderMinutesBefore(minutes);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, l10n.categories),
                    const SizedBox(height: 16),
                    
                    _buildSection(
                      context,
                      child: Column(
                        children: [
                          _buildNotificationTile(
                            context,
                            title: l10n.reminders,
                            subtitle: l10n.remindersSubtitle,
                            icon: Icons.notifications_none_rounded,
                            value: dataService.remindersNotificationsEnabled,
                            enabled: allEnabled,
                            onChanged: (value) => dataService.setRemindersNotificationsEnabled(value),
                          ),
                          _buildDivider(colorScheme),
                          _buildNotificationTile(
                            context,
                            title: l10n.groupActivity,
                            subtitle: l10n.groupActivitySubtitle,
                            icon: Icons.group_outlined,
                            value: dataService.groupActivityNotificationsEnabled,
                            enabled: allEnabled,
                            onChanged: (value) => dataService.setGroupActivityNotificationsEnabled(value),
                          ),
                          _buildDivider(colorScheme),
                          _buildNotificationTile(
                            context,
                            title: l10n.calendarEvents,
                            subtitle: l10n.calendarEventsSubtitle,
                            icon: Icons.calendar_today_rounded,
                            value: dataService.calendarEventsNotificationsEnabled,
                            enabled: allEnabled,
                            onChanged: (value) => dataService.setCalendarEventsNotificationsEnabled(value),
                          ),
                          _buildDivider(colorScheme),
                          _buildNotificationTile(
                            context,
                            title: l10n.updates,
                            subtitle: l10n.updatesSubtitle,
                            icon: Icons.update_rounded,
                            value: dataService.appUpdatesNotificationsEnabled,
                            enabled: allEnabled,
                            isLast: true,
                            onChanged: (value) => dataService.setAppUpdatesNotificationsEnabled(value),
                          ),
                        ],
                      ),
                    ),
                    
                    // Sección EXCLUSIVA de Móvil (Ajustes del Sistema Operativo)
                    if (!kIsWeb) ...[
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, l10n.systemConfiguration),
                      const SizedBox(height: 16),
                      _buildSection(
                        context,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.systemConfigurationDesc,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await openAppSettings();
                                },
                                icon: const Icon(Icons.settings_outlined, size: 18),
                                label: Text(l10n.openSystemSettings),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary.withAlpha(51)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Sección EXCLUSIVA de Web (Notificaciones del Navegador Web Push)
                    if (kIsWeb) ...[
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, l10n.browserNotifications),
                      const SizedBox(height: 16),
                      _buildSection(
                        context,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.language_rounded, color: colorScheme.primary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.browserAlerts,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        WebNotificationService().isPermissionGranted()
                                            ? l10n.browserPermissionGranted
                                            : l10n.browserAlertsDesc,
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withAlpha(140),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final granted = await WebNotificationService().requestPermission();
                                  setState(() {});
                                  if (granted) {
                                    WebNotificationService().showNotification(
                                      title: l10n.testNotificationTitle,
                                      body: l10n.testNotificationBody,
                                    );
                                  }
                                },
                                icon: Icon(
                                  WebNotificationService().isPermissionGranted()
                                      ? Icons.check_circle_rounded
                                      : Icons.notifications_active_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  WebNotificationService().isPermissionGranted()
                                      ? l10n.sendTestNotification
                                      : l10n.enableBrowserNotifications,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WebNotificationService().isPermissionGranted()
                                      ? colorScheme.primaryContainer
                                      : colorScheme.primary,
                                  foregroundColor: WebNotificationService().isPermissionGranted()
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildSection(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(51)),
      ),
      child: child,
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? colorScheme.primary.withAlpha(15) : colorScheme.onSurface.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? colorScheme.primary : colorScheme.onSurface.withAlpha(64),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withAlpha(64),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? colorScheme.onSurface.withAlpha(127) : colorScheme.onSurface.withAlpha(64),
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: colorScheme.primary,
        onChanged: enabled ? onChanged : null,
      ),
      shape: isLast 
        ? const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)))
        : null,
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 20,
      color: colorScheme.outlineVariant.withAlpha(51),
    );
  }
}
