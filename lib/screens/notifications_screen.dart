import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context);
    final notifications = dataService.notifications.reversed.toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 700) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Notificaciones',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              if (dataService.hasUnreadNotifications)
                IconButton(
                  icon: Icon(Icons.done_all_rounded, color: colorScheme.primary),
                  onPressed: () => dataService.markAllNotificationsAsRead(),
                  tooltip: 'Marcar todas como leídas',
                ),
            ],
          ),
          body: notifications.isEmpty
              ? _buildEmptyState(colorScheme, isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(context, notification, colorScheme, isDark);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te avisaremos cuando haya algo nuevo.',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02))
            : colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isRead
              ? (isDark ? Colors.white : Colors.black).withOpacity(0.05)
              : colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (notification.iconColor ?? colorScheme.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.icon,
            color: notification.iconColor ?? colorScheme.primary,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notification.body,
              style: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatTimestamp(context, notification.timestamp),
              style: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return l10n.localeName == 'es' ? 'Hace ${difference.inMinutes} min' : '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return l10n.localeName == 'es' ? 'Hace ${difference.inHours} h' : '${difference.inHours} h ago';
    } else {
      return DateFormat('dd MMM, HH:mm', l10n.localeName).format(timestamp);
    }
  }
}
