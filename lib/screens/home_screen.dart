import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import '../services/data_service.dart';
import '../models/subject.dart';
import '../models/reminder.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../services/firebase_service.dart';
import '../utils/date_utils.dart';
import '../widgets/user_avatar.dart';
import 'settings_screen.dart';
import 'reminder_details_screen.dart';
import 'project_details_screen.dart';
import 'notifications_screen.dart';
import 'note_editor_screen.dart';
import 'add_reminder_screen.dart';
import 'create_project_screen.dart';
import 'contacts_screen.dart';
import 'focus_screen.dart';
import 'complete_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

IconData getSeasonIcon(DateTime date) {
  final month = date.month;
  final tz = date.timeZoneName;

  bool isSouthern = tz.contains('Argentina') || tz.contains('Buenos_Aires') ||
      tz.contains('Santiago') || tz.contains('Sao_Paulo') ||
      tz.contains('Sydney') || tz.contains('Melbourne') ||
      tz.contains('Auckland') || tz.contains('Johannesburg') ||
      tz.contains('Montevideo') || tz.contains('Asuncion') ||
      tz.contains('Lima') || tz.contains('La_Paz');

  if (!isSouthern) {
    final upperTz = tz.toUpperCase();
    isSouthern = upperTz == 'ART' || upperTz == 'BRT' || upperTz == 'CLT' ||
        upperTz == 'AEST' || upperTz == 'NZST' || upperTz == 'SAST' ||
        upperTz == 'AEDT' || upperTz == 'AWST';
  }

  int effectiveMonth = isSouthern ? (month + 6) % 12 : month;
  if (effectiveMonth == 0) effectiveMonth = 12;

  if (effectiveMonth >= 3 && effectiveMonth <= 5) return Icons.spa_rounded;
  if (effectiveMonth >= 6 && effectiveMonth <= 8) return Icons.wb_sunny_rounded;
  if (effectiveMonth >= 9 && effectiveMonth <= 11) return Icons.eco_rounded;
  return Icons.ac_unit_rounded;
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _notificationSwipeProgress = 0.0;
  bool _showNotificationOverlay = false;
  bool _hasCheckedProfile = false;

  late DataService _dataService;

  @override
  void initState() {
    super.initState();
    // Escuchamos al DataService para detectar cuando termine la sincronización inicial
    // y verificar si el perfil está completo.
    _dataService = Provider.of<DataService>(context, listen: false);
    _dataService.addListener(_onDataServiceUpdate);
  }

  void _onDataServiceUpdate() {
    if (!mounted) return;
    
    // Si ya terminó de inicializar y no hemos chequeado el perfil aún
    if (_dataService.initialized && !_hasCheckedProfile) {
      // Si el perfil ya está completo, ya no necesitamos chequear más
      if (_dataService.profileCompleted) {
        _hasCheckedProfile = true;
        return;
      }

      // Si es un usuario real (no invitado) y el perfil no está completo según local
      if (!_dataService.isGuest) {
        // Esperamos a que la identificación remota ocurra. 
        // Si después de un momento sigue sin estar completo, saltamos la pantalla.
        _hasCheckedProfile = true;
        
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (!_dataService.profileCompleted && !_dataService.isGuest) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CompleteProfileScreen(
                  initialName: FirebaseService().userName ?? _dataService.userName,
                  initialEmail: FirebaseService().userEmail,
                ),
              ),
            );
          }
        });
      } else {
        _hasCheckedProfile = true;
      }
    }
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    final todayReminders = _dataService.reminders.where((r) =>
    r.dateTime.year == now.year &&
        r.dateTime.month == now.month &&
        r.dateTime.day == now.day &&
        !r.isCompleted
    ).toList();

    bool isExamClose = todayReminders.any((r) {
      if (r.category != 'Examen') return false;
      if (r.isAllDay) return true;
      final diff = r.dateTime.difference(now).inMinutes;
      return diff >= 0 && diff <= 180; // Mostrar 3 horas antes
    });

    bool hasFinishedExam = _dataService.reminders.any((r) {
      if (r.category != 'Examen' || !r.isCompleted || r.completedAt == null) return false;
      if (r.dateTime.year != now.year || r.dateTime.month != now.month || r.dateTime.day != now.day) return false;
      final diff = now.difference(r.completedAt!).inMinutes;
      return diff >= 0 && diff <= 120; // Mostrar solo por 2 horas tras marcarlo
    });

    return _dataService.getSessionGreeting(
      locale: l10n.localeName,
      morningPool: l10n.morningGreetings,
      afternoonPool: l10n.afternoonGreetings,
      eveningPool: l10n.eveningGreetings,
      noTasksPool: l10n.noTasksGreetings,
      busyDayPool: l10n.busyDayGreetings,
      examPool: l10n.examGreetings,
      postExamPool: l10n.postExamGreetings,
      birthdayPool: l10n.birthdayGreetings,
      taskCount: todayReminders.length,
      hasExamToday: isExamClose,
      hasFinishedExam: hasFinishedExam,
    );
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataServiceUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            alignment: const Alignment(-0.85, -0.92),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NotificationsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            alignment: const Alignment(0.85, -0.92),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;

    if (isTablet) {
      return _buildTabletHome(context);
    }

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta! < 0) {
          setState(() {
            _notificationSwipeProgress += -details.primaryDelta! / 100;
            _notificationSwipeProgress = _notificationSwipeProgress.clamp(0.0, 1.0);
          });
        } else if (details.primaryDelta! > 0 && _notificationSwipeProgress > 0) {
          setState(() {
            _notificationSwipeProgress -= details.primaryDelta! / 100;
            _notificationSwipeProgress = _notificationSwipeProgress.clamp(0.0, 1.0);
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 700) {
          _navigateToSettings(context);
        } else if (details.primaryVelocity! < -700 || _notificationSwipeProgress > 0.5) {
          _navigateToNotifications(context);
        }
        setState(() {
          _notificationSwipeProgress = 0.0;
        });
      },
      child: ValueListenableBuilder<HomeLayout>(
        valueListenable: dataService.homeLayout,
        builder: (context, layout, _) {
          if (layout == HomeLayout.simplified) {
            return _buildSimplifiedHome(context);
          }
          return _buildOriginalHome(context);
        },
      ),
    );
  }

  Widget _buildOriginalHome(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  final double pixels = notification.metrics.pixels;
                  const double threshold = 85.0; // snapOffset

                  if (pixels > 0 && pixels < threshold && _scrollController.hasClients) {
                    Future.microtask(() {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          pixels > threshold / 3 ? threshold : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    });
                  }
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const _SnappingScrollPhysics(snapOffset: 85),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DynamicHeaderDelegate(
                      welcomeMessage: _getGreeting(context),
                      onProfileTap: () => _navigateToSettings(context),
                      notificationSwipeProgress: _notificationSwipeProgress,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Hoy Section (Suggestions + Reminders)
                          _buildHoySection(context),
                          const SizedBox(height: 24),
                          // Notas recientes Section
                          _buildRecentNotesSection(context),
                          SizedBox(height: 140 + MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                  // Spacer to ensure we can always scroll enough to collapse the header
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 85),
                  ),
                ],
              ),
            ),
            _buildTransformingBottomWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedHome(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = Provider.of<DataService>(context);

    final now = DateTime.now();
    String dayName = DateFormat('EEEE', l10n.localeName).format(now);
    dayName = dayName[0].toUpperCase() + dayName.substring(1);
    final dateLabel = DateFormat(l10n.datePattern, l10n.localeName).format(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leadingWidth: 66,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: GestureDetector(
              onTap: () => _navigateToSettings(context),
              child: Hero(
                tag: 'profile_avatar_tag',
                child: _buildSimpleAvatar(context, 38),
              ),
            ),
          ),
        ),
        title: Text(
          '$dayName, $dateLabel',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _navigateToNotifications(context),
            icon: Icon(
              dataService.hasUnreadNotifications
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHoySection(context, simplified: true),
            const SizedBox(height: 32),
            _buildRecentNotesSection(context, simplified: true),
            SizedBox(height: 140 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }


  Widget _buildTabletHome(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabletHeader(context, isDark, theme.colorScheme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna Izquierda: Información de tiempo y tareas
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildNowBrief(context),
                              const SizedBox(height: 32),
                              _buildHoySection(context, simplified: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Columna Derecha: Acciones rápidas y notas
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildRecentNotesSection(context, simplified: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Notification Overlay
            if (_showNotificationOverlay)
              _buildNotificationOverlay(context, isDark, theme.colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOverlay(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final dataService = Provider.of<DataService>(context);
    final notifications = dataService.notifications.reversed.toList();
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Backdrop to close
        GestureDetector(
          onTap: () => setState(() => _showNotificationOverlay = false),
          child: Container(
            color: Colors.black.withOpacity(0.1),
          ),
        ),
        // Floating Panel
        Positioned(
          top: 80,
          right: 32,
          child: Material(
            elevation: 20,
            borderRadius: BorderRadius.circular(28),
            color: isDark ? const Color(0xFF151515) : Colors.white,
            child: Container(
              width: 380,
              height: 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                    child: Row(
                      children: [
                        Text(
                          'Notificaciones',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (dataService.hasUnreadNotifications)
                          TextButton(
                            onPressed: () => dataService.markAllNotificationsAsRead(),
                            child: Text(
                              'Leer todas',
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        IconButton(
                          onPressed: () => setState(() => _showNotificationOverlay = false),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: notifications.isEmpty
                        ? _buildEmptyOverlayState(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notif = notifications[index];
                              return _buildOverlayNotificationCard(context, notif, colorScheme, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOverlayState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 48, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayNotificationCard(BuildContext context, dynamic notification, ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead
            ? (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02))
            : colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (notification.iconColor ?? colorScheme.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.icon,
            color: notification.iconColor ?? colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabletHeader(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final dataService = Provider.of<DataService>(context);
    final now = DateTime.now();

    final l10n = AppLocalizations.of(context)!;
    String dayName = DateFormat('EEEE', l10n.localeName).format(now);
    dayName = dayName[0].toUpperCase() + dayName.substring(1);
    final dateLabel = DateFormat(l10n.fullDatePattern, l10n.localeName).format(now);
    final seasonIcon = getSeasonIcon(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(context),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      seasonIcon,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showNotificationOverlay = !_showNotificationOverlay;
              });
            },
            icon: Stack(
              children: [
                Icon(
                  _showNotificationOverlay ? Icons.notifications_rounded : Icons.notifications_none_rounded, 
                  color: colorScheme.primary, 
                  size: 28
                ),
                if (dataService.hasUnreadNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAvatar(BuildContext context, double size) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final photoUrl = FirebaseService().userPhotoUrl;
    final name = dataService.userName;

    return UserAvatar(
      name: name,
      photoUrl: photoUrl,
      size: size,
    );
  }

  Widget _buildSimplifiedSection(BuildContext context, {required String title, required Widget child, VoidCallback? onAdd, VoidCallback? onTapTitle}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onTapTitle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (onTapTitle != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary.withOpacity(0.5), size: 20),
                  ],
                ],
              ),
            ),
            if (onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildNowBrief(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = Provider.of<DataService>(context);

    // Find current and next class
    final now = DateTime.now();
    final todayClasses = dataService.getClassesForDate(now);
    final currentTime = now.hour + now.minute / 60.0;

    ClassInstance? currentClass;
    ClassInstance? nextClass;

    for (var c in todayClasses) {
      if (currentTime >= c.startHour && currentTime <= c.endHour) {
        currentClass = c;
      } else if (c.startHour > currentTime && nextClass == null) {
        nextClass = c;
      }
    }

    if (nextClass == null) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final tomorrowClasses = dataService.getClassesForDate(tomorrow);
      if (tomorrowClasses.isNotEmpty) {
        nextClass = tomorrowClasses.first;
      }
    }

    final currentTitle = currentClass?.subject.name ?? (nextClass != null && nextClass.date.day == now.day ? l10n.freeSlot : l10n.dayFinished);

    final Color accentColor = currentClass?.subject.color ?? theme.colorScheme.primary;

    if (dataService.subjects.isEmpty) {
      return InkWell(
        onTap: () => _showScheduleManagementPanel(context),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.15)),
          ),
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined, size: 32, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                l10n.noClassesProgrammed,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showScheduleManagementPanel(context),
      borderRadius: BorderRadius.circular(28),
      child: Hero(
        tag: 'schedule_management_hero',
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
          return Material(
            color: Colors.transparent,
            child: toHeroContext.widget,
          );
        },
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withOpacity(isDark ? 0.3 : 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('HH:mm').format(now),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.currentClass.toUpperCase(),
                  style: TextStyle(
                    color: (currentClass?.subject.color ?? theme.colorScheme.primary).withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              currentTitle,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
            if (currentClass != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Text(
                      currentClass.schedule.room ?? 'S/N',
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.next.toUpperCase(),
                          style: TextStyle(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextClass?.subject.name ?? l10n.noClasses,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (nextClass != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        nextClass.date.day == now.day
                            ? nextClass.formattedTime.split(' - ')[0]
                            : DateFormat('E HH:mm').format(nextClass.date),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildRecentNotesSection(BuildContext context, {bool simplified = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final recentNotes = List<Note>.from(dataService.notes);
        recentNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        if (recentNotes.isEmpty) {
          return (simplified ? _buildSimplifiedSection : _buildSectionContainer)(
            context,
            title: l10n.recentNotes,
            onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NoteEditorScreen())),
            onTapTitle: () => Provider.of<DataService>(context, listen: false).mainTabIndex = 3,
            child: _buildEmptyState(
              context,
              icon: Icons.note_add_outlined,
              message: l10n.noNotesYet,
            ),
          );
        }

        // Feature Note (The most recent one)
        final featuredNote = recentNotes.first;
        final remainingNotes = recentNotes.skip(1).take(4).toList();

        return (simplified ? _buildSimplifiedSection : _buildSectionContainer)(
          context,
          title: l10n.recentNotes,
          onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NoteEditorScreen())),
          onTapTitle: () => Provider.of<DataService>(context, listen: false).mainTabIndex = 3,
          child: Column(
            children: [
              _buildFeaturedNoteCard(context, featuredNote, simplified: simplified),
              if (remainingNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < remainingNotes.length; i += 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildNoteCard(context, remainingNotes[i], simplified: simplified),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 1; i < remainingNotes.length; i += 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildNoteCard(context, remainingNotes[i], simplified: simplified),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedNoteCard(BuildContext context, Note note, {bool simplified = false}) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = note.backgroundColor ?? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04));
    final bool isNoteDark = note.backgroundColor != null 
        ? note.backgroundColor!.computeLuminance() < 0.5 
        : isDark;

    final Color textColor = isNoteDark ? Colors.white : Colors.black;
    final String preview = note.previewText.isEmpty ? l10n.noContent : note.previewText;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note))),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: (note.backgroundColor == null && !isDark) ? Border.all(color: Colors.black.withOpacity(0.05)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "RECIENTE",
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateUtilsFormatter.formatDynamicDate(context, note.updatedAt),
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!note.isQuickNote && note.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  note.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Text(
              preview,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 15,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsBento(BuildContext context, {bool simplified = false}) {
    final theme = Theme.of(context);
    final dataService = Provider.of<DataService>(context);
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final todayClasses = dataService.getClassesForDate(now);
    final currentTime = now.hour + now.minute / 60.0;

    ClassInstance? currentClass;
    for (var c in todayClasses) {
      if (currentTime >= c.startHour && currentTime <= c.endHour) {
        currentClass = c;
        break;
      }
    }

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCircularAction(
          context,
          title: l10n.skipClass,
          icon: Icons.event_busy_rounded,
          color: Colors.redAccent,
          onTap: currentClass == null ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.noActiveClassToSkip)),
            );
          } : () {
            dataService.discardClassForDate(currentClass!.subject.id, now);
          },
        ),
        /*
        _buildCircularAction(
          context,
          title: l10n.focus,
          icon: Icons.timer_outlined,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FocusScreen()),
            );
          },
        ),
        _buildCircularAction(
          context,
          title: l10n.project,
          icon: Icons.folder_special_outlined,
          color: Colors.indigoAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProjectScreen())),
        ),
        */
        _buildCircularAction(
          context,
          title: l10n.contacts,
          icon: Icons.qr_code_scanner_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactsScreen())),
        ),
      ],
    );

    if (simplified) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallSubheader(l10n.quickActions.toUpperCase()),
          const SizedBox(height: 8),
          content,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            l10n.quickActions,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildCircularAction(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.12 : 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.1), width: 1.2),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransformingBottomWidget() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = Provider.of<DataService>(context);

    // Find current and next class
    final now = DateTime.now();
    final todayClasses = dataService.getClassesForDate(now);
    final currentTime = now.hour + now.minute / 60.0;

    ClassInstance? currentClass;
    ClassInstance? nextClass;

    for (var c in todayClasses) {
      if (currentTime >= c.startHour && currentTime <= c.endHour) {
        currentClass = c;
      } else if (c.startHour > currentTime && nextClass == null) {
        nextClass = c;
      }
    }

    if (nextClass == null) {
      // Look for first class tomorrow
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final tomorrowClasses = dataService.getClassesForDate(tomorrow);
      if (tomorrowClasses.isNotEmpty) {
        nextClass = tomorrowClasses.first;
      }
    }

    final currentTitle = currentClass?.subject.name ?? (nextClass != null && nextClass.date.day == now.day ? l10n.freeSlot : l10n.dayFinished);
    final currentSub = currentClass != null 
        ? (currentClass.schedule.room ?? 'S/N') 
        : (nextClass != null && nextClass.date.day == now.day ? l10n.nextClassPrefix(nextClass.subject.name) : l10n.restTime);
    final Color accentColor = currentClass?.subject.color ?? theme.colorScheme.primary;

    if (dataService.subjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
        valueListenable: dataService.useMulticolor,
        builder: (context, isMulticolor, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: dataService.useDynamicColor,
            builder: (context, isDynamic, _) {
              final Color primaryColor = theme.colorScheme.primary;
              final Color surfaceColor = theme.colorScheme.surface;
              
              return ListenableBuilder(
                listenable: _scrollController,
                builder: (context, child) {
                  double offset = _scrollController.hasClients ? _scrollController.offset : 0;
                  double t = (offset / 60).clamp(0.0, 1.0);

                  double screenWidth = MediaQuery.of(context).size.width;
                  double cardWidth = screenWidth - 40;
                  double pillWidth = 230;
                  double currentWidth = lerpDouble(cardWidth, pillWidth, t)!;

                  double currentRadius = lerpDouble(24, 50, t)!;
                  double currentPaddingV = lerpDouble(16, 8, t)!;
                  double currentPaddingH = lerpDouble(20, 14, t)!;

                  final Color cardBgColor = Color.alphaBlend(
                    accentColor.withOpacity(lerpDouble(isDark ? 0.15 : 0.1, isDark ? 0.25 : 0.15, t)!),
                    surfaceColor
                  );

                  final double opacity = (1.0 - (offset / 300).clamp(0.0, 0.4));

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 5 + MediaQuery.of(context).padding.bottom), // Justo sobre el borde superior de la barra de navegación
                      child: Opacity(
                        opacity: opacity,
                        child: Hero(
                          tag: 'schedule_management_hero',
                          flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                            return Material(
                              color: Colors.transparent,
                              child: toHeroContext.widget,
                            );
                          },
                          child: GestureDetector(
                            onTap: () => _showScheduleManagementPanel(context),
                            child: Container(
                            width: currentWidth,
                            height: lerpDouble(185, 56, t),
                            decoration: BoxDecoration(
                              color: cardBgColor.withOpacity(0.98),
                              borderRadius: BorderRadius.circular(currentRadius),
                              border: Border.all(color: accentColor.withOpacity(isDark ? 0.3 : 0.15)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: currentPaddingH, vertical: currentPaddingV),
                              child: ClipRect(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                  Opacity(
                                    opacity: (1 - t * 2.5).clamp(0.0, 1.0),
                                    child: OverflowBox(
                                      maxWidth: 400,
                                      child: Center(
                                        child: Container(
                                          width: cardWidth - 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: SingleChildScrollView(
                                            physics: const NeverScrollableScrollPhysics(),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(l10n.currentClass.toUpperCase(), 
                                                      style: TextStyle(
                                                        color: currentClass?.subject.color ?? primaryColor, 
                                                        fontSize: 10, 
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 1.1,
                                                      )
                                                    ),
                                                    const Spacer(),
                                                    if (currentClass != null)
                                                      Text(
                                                        currentClass.formattedTime,
                                                        style: TextStyle(
                                                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  currentTitle, 
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : Colors.black, 
                                                    fontSize: 22, 
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.7,
                                                  )
                                                ),
                                                const SizedBox(height: 16),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.arrow_forward_rounded, size: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(l10n.next.toUpperCase(), style: TextStyle(color: (isDark ? Colors.white38 : Colors.black38), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                                            Text(
                                                              nextClass?.subject.name ?? l10n.noClasses,
                                                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (nextClass != null)
                                                        Text(
                                                          nextClass.date.day == now.day 
                                                            ? nextClass.formattedTime.split(' - ')[0] 
                                                            : DateFormat('E HH:mm').format(nextClass.date),
                                                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: ((t - 0.2) * 2.5).clamp(0.0, 1.0),
                                    child: OverflowBox(
                                      maxWidth: 400,
                                      child: Center(
                                        child: Container(
                                          width: pillWidth,
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                DateFormat('HH:mm').format(now),
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 18,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                                width: 1.2,
                                                height: 20,
                                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                                              ),
                                              Flexible(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      currentTitle,
                                                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.bold, height: 1.1),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      currentSub,
                                                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHoySection(BuildContext context, {bool simplified = false}) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit14Days = today.add(const Duration(days: 14));

    // Filter Reminders for next 14 days
    final allUpcomingReminders = dataService.reminders.where((r) {
      if (r.isCompleted) return false;
      final eventEnd = r.endDate ?? r.dateTime;
      // Show if ends after today starts AND starts before 14 days limit
      return !eventEnd.isBefore(today) && r.dateTime.isBefore(limit14Days);
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Filter Projects for next 14 days (by endDate) - Temporarily disabled
    final allUpcomingProjects = <Project>[];
    /*
    final allUpcomingProjects = dataService.projects.where((p) =>
      p.status != ProjectStatus.completed &&
      p.status != ProjectStatus.archived &&
      (p.endDate != null && p.endDate!.isAfter(now) && p.endDate!.isBefore(limit14Days))
    ).toList()..sort((a, b) => (a.endDate!).compareTo(b.endDate!));
    */

    final bool noItemsIn14Days = allUpcomingReminders.isEmpty && allUpcomingProjects.isEmpty;

    // Items for Today and Tomorrow list
    final tomorrow = today.add(const Duration(days: 1));
    
    final rawTodayReminders = allUpcomingReminders.where((r) => r.isHappeningOn(today)).toList();
    final rawTomorrowReminders = allUpcomingReminders.where((r) => r.isHappeningOn(tomorrow)).toList();

    final todayProjects = allUpcomingProjects.where((p) => 
      p.endDate != null && p.endDate!.year == today.year && p.endDate!.month == today.month && p.endDate!.day == today.day
    ).toList();
    final tomorrowProjects = allUpcomingProjects.where((p) => 
      p.endDate != null && p.endDate!.year == tomorrow.year && p.endDate!.month == tomorrow.month && p.endDate!.day == tomorrow.day
    ).toList();

    // --- Smart Summary Logic ---
    final veryCloseLimit = today.add(const Duration(days: 3));
    dynamic highlightItem;
    String recommendation = '';
    
    // 1. Urgent Reminders in next 3 days
    highlightItem = allUpcomingReminders.firstWhereOrNull((r) => r.isUrgent && r.dateTime.isBefore(veryCloseLimit));
    if (highlightItem != null) {
      recommendation = l10n.localeName == 'es' 
          ? "Es prioritario avanzar con ${highlightItem.title}"
          : "It's priority to move forward with ${highlightItem.title}";
    }

    // 2. Exams in next 3 days
    if (highlightItem == null) {
      highlightItem = allUpcomingReminders.firstWhereOrNull((r) => r.category == 'Examen' && r.dateTime.isBefore(veryCloseLimit));
      if (highlightItem != null) {
        recommendation = l10n.localeName == 'es'
            ? "Es buen momento para estudiar para ${highlightItem.title}"
            : "It's a good time to study for ${highlightItem.title}";
      }
    }

    // 3. Tasks/Projects in next 3 days
    if (highlightItem == null) {
      highlightItem = allUpcomingReminders.firstWhereOrNull((r) => (r.category == 'Tarea' || r.category == 'Proyecto') && r.dateTime.isBefore(veryCloseLimit));
      if (highlightItem != null) {
        recommendation = l10n.localeName == 'es'
            ? "Te recomendamos trabajar en ${highlightItem.title}"
            : "We recommend working on ${highlightItem.title}";
      }
      
      if (highlightItem == null) {
        highlightItem = allUpcomingProjects.firstWhereOrNull((p) => p.endDate != null && p.endDate!.isBefore(veryCloseLimit));
        if (highlightItem != null) {
          recommendation = l10n.localeName == 'es'
              ? "No olvides avanzar con el proyecto ${highlightItem.title}"
              : "Don't forget to move forward with project ${highlightItem.title}";
        }
      }
    }


    // Fallback: If nothing "very close" but something in 14 days, and Today/Tomorrow list is empty
    if (highlightItem == null && rawTodayReminders.isEmpty && todayProjects.isEmpty && rawTomorrowReminders.isEmpty && tomorrowProjects.isEmpty && !noItemsIn14Days) {
        final nextReminder = allUpcomingReminders.firstOrNull;
        final nextProject = allUpcomingProjects.firstOrNull;
        
        if (nextReminder != null && (nextProject == null || nextReminder.dateTime.isBefore(nextProject.endDate!))) {
            highlightItem = nextReminder;
            recommendation = l10n.localeName == 'es' ? "Próximamente: ${nextReminder.title}" : "Coming soon: ${nextReminder.title}";
        } else if (nextProject != null) {
            highlightItem = nextProject;
            recommendation = l10n.localeName == 'es' ? "Próximo cierre: ${nextProject.title}" : "Next deadline: ${nextProject.title}";
        }
    }

    // Event Legend (Grouped Logic)
    final todayEvents = allUpcomingReminders.where((r) => 
      r.category == 'Evento' && r.isHappeningOn(today)
    ).toList();
    
    final upcomingEvents = allUpcomingReminders.where((r) => 
      r.category == 'Evento' && !r.isHappeningOn(today)
    ).toList();

    String? eventLegend;
    bool hasTodayEvents = todayEvents.isNotEmpty;
    bool groupTomorrowEvents = rawTomorrowReminders.where((r) => r.category == 'Evento').length > 1;

    if (todayEvents.length > 1) {
      final currentHour = now.hour + now.minute / 60.0;
      int inProgress = 0;
      int remaining = 0;
      DateTime? nextEventTime;
      
      for (var e in todayEvents) {
        final eventStart = e.dateTime.hour + e.dateTime.minute / 60.0;
        if (currentHour >= eventStart && currentHour <= eventStart + 1.0) {
          inProgress++;
        } else if (eventStart > currentHour) {
          remaining++;
          if (nextEventTime == null || e.dateTime.isBefore(nextEventTime)) {
            nextEventTime = e.dateTime;
          }
        }
      }

      if (l10n.localeName == 'es') {
        eventLegend = "Hoy: ${todayEvents.length} eventos";
        if (inProgress > 0) {
          eventLegend += " ($inProgress en curso, $remaining restantes)";
        } else if (nextEventTime != null) {
          eventLegend += " (el próximo a las ${DateFormat('HH:mm').format(nextEventTime)})";
        }
      } else {
        eventLegend = "Today: ${todayEvents.length} events";
        if (inProgress > 0) {
          eventLegend += " ($inProgress in progress, $remaining remaining)";
        } else if (nextEventTime != null) {
          eventLegend += " (next at ${DateFormat('HH:mm').format(nextEventTime)})";
        }
      }
    } else if (todayEvents.length == 1) {
      final e = todayEvents.first;
      eventLegend = l10n.localeName == 'es'
          ? "Hoy: ${e.title}${e.time != null ? ' a las ${e.time}' : ''}"
          : "Today: ${e.title}${e.time != null ? ' at ${e.time}' : ''}";
    }

    // Add info about tomorrow if grouped
    if (groupTomorrowEvents) {
      final tomorrowCount = rawTomorrowReminders.where((r) => r.category == 'Evento').length;
      final tomorrowMsg = l10n.localeName == 'es' 
          ? "Mañana: $tomorrowCount eventos programados" 
          : "Tomorrow: $tomorrowCount events scheduled";
      
      if (eventLegend == null) {
        eventLegend = tomorrowMsg;
      } else {
        eventLegend += "\n$tomorrowMsg";
      }
    } else if (eventLegend == null && upcomingEvents.length > 1) {
      eventLegend = l10n.localeName == 'es'
          ? "Tienes ${upcomingEvents.length} eventos programados para los próximos días"
          : "You have ${upcomingEvents.length} events scheduled for the next few days";
    }

    // Items for Today and Tomorrow list (Filtered for display)
    final todayReminders = rawTodayReminders.where((r) => 
      (r.category != 'Evento')
    ).toList();
    
    // Do not repeat multi-day events or reminders in "Mañana" if they are already active today
    final tomorrowReminders = rawTomorrowReminders.where((r) => 
      !r.isHappeningOn(today) && (!groupTomorrowEvents || r.category != 'Evento')
    ).toList();

    final onAdd = () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddReminderScreen()));

    return (simplified ? _buildSimplifiedSection : _buildSectionContainer)(
      context,
      title: l10n.today,
      onAdd: onAdd,
      onTapTitle: () => Provider.of<DataService>(context, listen: false).mainTabIndex = 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noItemsIn14Days)
            _buildEmptyState(
              context,
              icon: Icons.wb_sunny_outlined,
              message: l10n.localeName == 'es' ? 'Todo despejado por hoy' : 'All clear for today',
              verticalPadding: 20,
              iconSize: 42,
            ),
          // Smart Summary Card
          if (highlightItem != null || (eventLegend != null && !hasTodayEvents))
            _buildSmartSummaryCard(context, highlightItem, recommendation, eventLegend),
          
          // Events Card for Today
          if (hasTodayEvents)
            _CollapsibleEventsCard(events: todayEvents),

          if (todayReminders.isNotEmpty || todayProjects.isNotEmpty || tomorrowReminders.isNotEmpty || tomorrowProjects.isNotEmpty)
            const SizedBox(height: 16),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (todayReminders.isNotEmpty || todayProjects.isNotEmpty) ...[
                  _buildSmallSubheader(l10n.todayLabel.toUpperCase()),
                  ...todayReminders.map((r) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildHomeReminderCard(context, r, simplified: simplified))),
                  ...todayProjects.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildHomeProjectCard(context, p, simplified: simplified))),
                ],
                if (tomorrowReminders.isNotEmpty || tomorrowProjects.isNotEmpty) ...[
                  _buildSmallSubheader(l10n.tomorrowLabel.toUpperCase()),
                  ...tomorrowReminders.map((r) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildHomeReminderCard(context, r, simplified: simplified))),
                  ...tomorrowProjects.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildHomeProjectCard(context, p, simplified: simplified))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSummaryCard(BuildContext context, dynamic highlightItem, String recommendation, String? eventLegend) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              highlightItem != null ? Icons.lightbulb_outline_rounded : Icons.calendar_today_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recommendation.isNotEmpty)
                  Text(
                    recommendation,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                if (eventLegend != null) ...[
                  if (recommendation.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    eventLegend,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeProjectCard(BuildContext context, Project project, {bool simplified = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailsScreen(projectId: project.id))),
      borderRadius: BorderRadius.circular(simplified ? 16 : 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(simplified ? 16 : 20),
          border: simplified ? null : Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.folder_special_rounded, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.project,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: project.progress,
                strokeWidth: 3,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallSubheader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildHomeReminderCard(BuildContext context, Reminder reminder, {bool simplified = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEvent = reminder.category == 'Evento';

    return isEvent ? _buildEventCard(context, reminder, isDark, simplified: simplified) : _buildStandardReminderCard(context, reminder, isDark, simplified: simplified);
  }

  Widget _buildEventCard(BuildContext context, Reminder reminder, bool isDark, {bool simplified = false}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(simplified ? 16 : 22),
        border: Border.all(
          color: simplified ? Colors.transparent : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          width: 1.0
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReminderDetailsScreen(reminder: reminder),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.eventLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (reminder.isAllDay)
                        Text(
                          l10n.allDayLabel.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      else if (reminder.time != null)
                        Text(
                          reminder.time!,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (reminder.location != null && reminder.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            reminder.location!,
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colorScheme.primary.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildStandardReminderCard(BuildContext context, Reminder reminder, bool isDark, {bool simplified = false}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(simplified ? 16 : 20),
        border: simplified ? null : Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final dataService = Provider.of<DataService>(context, listen: false);
              dataService.updateReminder(reminder.copyWith(
                isCompleted: true,
                completedAt: DateTime.now(),
              ));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: reminder.isUrgent
                    ? colorScheme.primary.withOpacity(0.1)
                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: reminder.isUrgent
                      ? colorScheme.primary.withOpacity(0.5)
                      : (isDark ? Colors.white24 : Colors.black12),
                  width: 1.5,
                ),
              ),
              child: reminder.isUrgent
                  ? Icon(Icons.priority_high_rounded, size: 14, color: colorScheme.primary)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReminderDetailsScreen(reminder: reminder),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getCategoryLabel(reminder.category, l10n),
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (reminder.isAllDay)
            Text(
              l10n.allDayLabel,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (reminder.time != null)
            Text(
              reminder.time!,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
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

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String message, double verticalPadding = 40, double iconSize = 64}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          SizedBox(height: iconSize > 40 ? 16 : 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, {required String title, required Widget child, VoidCallback? onAdd, VoidCallback? onTapTitle}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = Provider.of<DataService>(context);

    return ValueListenableBuilder<bool>(
        valueListenable: dataService.useMulticolor,
        builder: (context, isMulticolor, _) {
          final Color primaryColor = theme.colorScheme.primary;
          final Color accentColor = isMulticolor ? const Color(0xFF8B5CF6) : primaryColor;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onTapTitle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, 
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black, 
                              fontSize: 22, 
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            )
                          ),
                          if (onTapTitle != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded, color: accentColor.withOpacity(0.5), size: 22),
                          ],
                        ],
                      ),
                    ),
                    if (onAdd != null)
                      Container(
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onAdd,
                          icon: Icon(Icons.add_rounded, color: accentColor, size: 22),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          );
        }
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, {bool simplified = false}) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = note.backgroundColor ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02));
    final bool isNoteDark = note.backgroundColor != null 
        ? note.backgroundColor!.computeLuminance() < 0.5 
        : isDark;

    final Color textColor = isNoteDark ? Colors.white : Colors.black;

    final bool hasTitle = !note.isQuickNote && note.title.isNotEmpty && note.title != l10n.quickNote;
    final String preview = note.previewText.isEmpty ? l10n.noContent : note.previewText;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
        );
      },
      borderRadius: BorderRadius.circular(simplified ? 16 : 15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(simplified ? 16 : 20),
          border: (note.backgroundColor == null && !isDark && !simplified) ? Border.all(color: Colors.black.withOpacity(0.05)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasTitle) ...[
              Text(
                note.title,
                style: TextStyle(
                  color: isNoteDark ? textColor : textColor.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              preview,
              style: TextStyle(
                  color: isNoteDark ? textColor.withOpacity(0.6) : textColor.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  height: 1.3
              ),
              maxLines: hasTitle ? 3 : 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateUtilsFormatter.formatDynamicDate(context, note.updatedAt),
                style: TextStyle(
                  color: isNoteDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark, AppLocalizations l10n) {
    String formattedDate = DateFormat(l10n.fullDatePattern, l10n.localeName).format(date);
    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ],
      ),
    );
  }

  void _showScheduleManagementPanel(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierLabel: 'ScheduleManagement',
        barrierColor: Colors.black.withOpacity(0.6),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ScheduleManagementDialog(
            onShowGlobalActions: () => _showGlobalScheduleActions(context),
            onShowClassOptions: (item) => _showClassOptions(context, item),
            buildDateHeader: (date, isDark, l10n) => _buildDateHeader(date, isDark, l10n),
            buildClassItem: (ctx, item, isDark, onTap) => _buildClassItemInternal(ctx, item, isDark, onTap),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildClassItemInternal(BuildContext context, ClassInstance item, bool isDark, VoidCallback onTap) {
    final l10n = AppLocalizations.of(context)!;
    final color = item.isDiscarded
        ? (isDark ? Colors.white24 : Colors.black12)
        : item.subject.color;

    return Opacity(
      opacity: item.isDiscarded ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.03)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.subject.name,
                              style: TextStyle(
                                color: item.isDiscarded
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : (isDark ? Colors.white : Colors.black),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: item.isDiscarded ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!item.isDiscarded && (item.offsetHours != 0 || item.customDurationHours != null))
                            Icon(Icons.event_repeat_rounded, size: 16, color: Colors.orange.withOpacity(0.6)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.isDiscarded ? l10n.sessionDiscarded : '${item.formattedTime} • ${item.schedule.room ?? 'S/N'}',
                        style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.isDiscarded)
                  Icon(Icons.chevron_right_rounded, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGlobalScheduleActions(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context, listen: false);

    final now = DateTime.now();
    final todayClasses = dataService.getClassesForDate(now);
    final currentHour = now.hour + now.minute / 60.0;
    final hasNextClassToday = todayClasses.any((c) => c.startHour > currentHour + 0.05);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              _buildActionTile(
                context,
                l10n.advanceClass,
                Icons.fast_forward_rounded,
                colorScheme.primary,
                enabled: hasNextClassToday,
                    () {
                  try {
                    final next = todayClasses.firstWhere((c) => c.startHour > currentHour);
                    final offset = currentHour - next.schedule.startHourDouble;
                    dataService.addOverride(ScheduleOverride(
                      subjectId: next.subject.id,
                      date: now,
                      originalStartTime: next.schedule.startTime,
                      offsetHours: offset,
                    ));
                  } catch (_) {}
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildDiscardMenu(context, isDark, colorScheme, dataService, l10n),
              const SizedBox(height: 12),
              if (dataService.hasFutureDiscarded())
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActionTile(
                    context,
                    l10n.resumeSchedule,
                    Icons.play_circle_outline_rounded,
                    Colors.green,
                        () {
                      final now = DateTime.now();
                      final maxDate = now.add(const Duration(days: 365));
                      dataService.resumePeriod(now, maxDate);
                      Navigator.pop(context);
                    },
                  ),
                ),
              _buildActionTile(
                context,
                l10n.pauseSchedule,
                Icons.pause_circle_outline_rounded,
                Colors.orange,
                    () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: theme.copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            primary: Colors.orange,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                    helpText: l10n.resumeScheduleOn,
                    cancelText: l10n.cancelLabel.toUpperCase(),
                    confirmText: l10n.pauseBtn,
                  );

                  if (pickedDate != null) {
                    final endDiscard = DateTime(pickedDate.year, pickedDate.month, pickedDate.day).subtract(const Duration(seconds: 1));
                    dataService.discardPeriod(now, endDiscard);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                l10n.configureSchedule,
                Icons.settings_outlined,
                (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                    () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscardMenu(BuildContext context, bool isDark, ColorScheme colorScheme, DataService dataService, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.discardLabel,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDiscardChip(context, l10n.thisClass, () {
                  final now = DateTime.now();
                  final classes = dataService.getClassesForDate(now);
                  final currentHour = now.hour + now.minute / 60.0;
                  try {
                    final current = classes.firstWhere((c) => currentHour >= c.startHour && currentHour <= c.endHour);
                    dataService.discardClassForDate(current.subject.id, now);
                  } catch (_) {}
                  Navigator.pop(context);
                }),
                _buildDiscardChip(context, l10n.todayLabel, () {
                  final now = DateTime.now();
                  dataService.discardPeriod(now, now);
                  Navigator.pop(context);
                }),
                _buildDiscardChip(context, l10n.tomorrowLabel, () {
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  dataService.discardPeriod(tomorrow, tomorrow);
                  Navigator.pop(context);
                }),
                _buildDiscardChip(context, l10n.weekLabel, () {
                  final now = DateTime.now();
                  final endOfWeek = now.add(Duration(days: 7 - now.weekday));
                  dataService.discardPeriod(now, endOfWeek);
                  Navigator.pop(context);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscardChip(BuildContext context, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, {bool enabled = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = enabled ? color : (isDark ? Colors.white24 : Colors.black26);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: displayColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: displayColor, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: enabled ? (isDark ? Colors.white : Colors.black) : displayColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (enabled)
                Icon(Icons.chevron_right_rounded, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassItem(BuildContext context, ClassInstance item, bool isDark) {
    return _buildClassItemInternal(context, item, isDark, () => _showClassOptions(context, item));
  }

  void _showClassOptions(BuildContext context, ClassInstance item) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 4.5,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                item.subject.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.formattedTime} | ${item.schedule.room ?? 'S/N'}',
                style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 14),
              ),
              const SizedBox(height: 30),
              _buildActionTile(
                context,
                l10n.reprogramClass,
                Icons.event_repeat_rounded,
                colorScheme.primary,
                    () {
                  Navigator.pop(context);
                  _showReprogramPanel(context, item);
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                item.isDiscarded ? l10n.restoreSession : l10n.discardSession,
                item.isDiscarded ? Icons.restore_rounded : Icons.delete_outline_rounded,
                item.isDiscarded ? Colors.green : Colors.redAccent,
                    () {
                  if (item.isDiscarded) {
                    dataService.removeOverride(
                        item.subject.id,
                        item.date,
                        item.schedule.startTime
                    );
                  } else {
                    dataService.addOverride(ScheduleOverride(
                      subjectId: item.subject.id,
                      date: item.date,
                      originalStartTime: item.schedule.startTime,
                      isDiscarded: true,
                    ));
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReprogramPanel(BuildContext context, ClassInstance item) {
    _showReprogramOptionsInternal(context, item);
  }

  void _showReprogramOptionsInternal(BuildContext context, ClassInstance item) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context, listen: false);

    final duration = item.schedule.durationHours;
    final recommendedSlots = dataService.getRecommendedSlots(item.date, duration);
    final range = dataService.getNormalClassRange();

    final normalSlots = recommendedSlots.where((s) => s.startHour >= range['start']! && s.endHour <= range['end']!).toList();
    final extraSlots = recommendedSlots.where((s) => !normalSlots.contains(s)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  l10n.selectFreeSlot,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('EEEE d', l10n.localeName).format(item.date)} | ${duration.toStringAsFixed(1)}h',
                  style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 14),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (normalSlots.isNotEmpty) ...[
                        _buildSmallSubheaderHome(l10n.localeName == 'es' ? 'HORARIO NORMAL' : 'NORMAL HOURS', context),
                        const SizedBox(height: 10),
                        ...normalSlots.map((slot) => _buildSlotTileHome(context, slot, item, dataService, colorScheme, isDark, true)),
                        const SizedBox(height: 20),
                      ],
                      if (extraSlots.isNotEmpty) ...[
                        _buildSmallSubheaderHome(l10n.localeName == 'es' ? 'HORARIO EXTRACURRICULAR' : 'EXTRACURRICULAR HOURS', context),
                        const SizedBox(height: 10),
                        ...extraSlots.map((slot) => _buildSlotTileHome(context, slot, item, dataService, colorScheme, isDark, false)),
                        const SizedBox(height: 20),
                      ],
                      if (recommendedSlots.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(l10n.noFreeSlotsToday, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3))),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: Text(l10n.localeName == 'es' ? 'Otro día' : 'Other day'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: item.date,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null && context.mounted) {
                              Navigator.pop(context);
                              final newItem = ClassInstance(
                                subject: item.subject,
                                schedule: item.schedule,
                                date: picked,
                              );
                              _showReprogramOptionsInternal(context, newItem);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.access_time_rounded, size: 18),
                          label: Text(l10n.localeName == 'es' ? 'Personalizado' : 'Custom'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: () => _showCustomTimeAndDurationDialog(context, item),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotTileHome(BuildContext context, TimeSlot slot, ClassInstance item, DataService dataService, ColorScheme colorScheme, bool isDark, bool isNormal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildActionTile(
        context,
        slot.formattedRange,
        isNormal ? Icons.schedule_rounded : Icons.history_toggle_off_rounded,
        isNormal ? colorScheme.primary : Colors.orange,
        () {
          final targetStart = slot.startHour;
          final originalStart = item.schedule.startHourDouble;
          final offset = targetStart - originalStart;

          dataService.addOverride(ScheduleOverride(
            subjectId: item.subject.id,
            date: item.date,
            originalStartTime: item.schedule.startTime,
            offsetHours: offset,
          ));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSmallSubheaderHome(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Colors.grey.withOpacity(0.6),
        ),
      ),
    );
  }

  TimeOfDay _doubleToTimeOfDay(double value) {
    int hour = value.floor();
    int minute = ((value - hour) * 60).round();
    if (minute == 60) {
      hour++;
      minute = 0;
    }
    return TimeOfDay(hour: hour % 24, minute: minute);
  }

  void _showCustomTimeAndDurationDialog(BuildContext context, ClassInstance item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context, listen: false);
    TimeOfDay selectedTime = _doubleToTimeOfDay(item.startHour);
    double selectedDuration = item.customDurationHours ?? item.schedule.durationHours;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setInternalState) => Padding(
          padding: EdgeInsets.fromLTRB(28, 12, 28, MediaQuery.of(context).viewInsets.bottom + 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 25),
              Text(l10n.localeName == 'es' ? 'Horario Personalizado' : 'Custom Schedule', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 25),
              _buildSettingRowHome(
                context,
                l10n.time,
                selectedTime.format(context),
                Icons.access_time_rounded,
                () async {
                  final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                  if (picked != null) setInternalState(() => selectedTime = picked);
                },
                isDark
              ),
              const SizedBox(height: 15),
              _buildSettingRowHome(
                context,
                l10n.localeName == 'es' ? 'Duración' : 'Duration',
                '${selectedDuration.toStringAsFixed(1)} h',
                Icons.timer_outlined,
                () => _showDurationPickerHome(context, selectedDuration, (val) => setInternalState(() => selectedDuration = val), isDark),
                isDark
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final targetStart = selectedTime.hour + selectedTime.minute / 60.0;
                    final originalStart = item.schedule.startHourDouble;
                    final offset = targetStart - originalStart;

                    dataService.addOverride(ScheduleOverride(
                      subjectId: item.subject.id,
                      date: item.date,
                      originalStartTime: item.schedule.startTime,
                      offsetHours: offset,
                      customDurationHours: selectedDuration,
                    ));
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close parent reprogram menu
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRowHome(BuildContext context, String label, String value, IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  void _showDurationPickerHome(BuildContext context, double current, Function(double) onSelected, bool isDark) {
    final List<double> options = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF202020) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text('$opt h', textAlign: TextAlign.center, style: TextStyle(fontWeight: current == opt ? FontWeight.bold : null)),
            selected: current == opt,
            onTap: () {
              onSelected(opt);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

}

class _ScheduleManagementDialog extends StatelessWidget {
  final VoidCallback onShowGlobalActions;
  final Function(ClassInstance) onShowClassOptions;
  final Widget Function(DateTime, bool, AppLocalizations) buildDateHeader;
  final Widget Function(BuildContext, ClassInstance, bool, VoidCallback) buildClassItem;

  const _ScheduleManagementDialog({
    required this.onShowGlobalActions,
    required this.onShowClassOptions,
    required this.buildDateHeader,
    required this.buildClassItem,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Center(
      child: Hero(
        tag: 'schedule_management_hero',
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 25, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.scheduleManagement,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                      ),
                    ),
                    Row(
                      children: [
                        Consumer<DataService>(
                          builder: (context, ds, _) => ds.hasFutureDiscarded() 
                            ? IconButton(
                                icon: const Icon(Icons.play_circle_outline_rounded, color: Colors.green),
                                onPressed: () {
                                  final now = DateTime.now();
                                  final maxDate = now.add(const Duration(days: 365));
                                  ds.resumePeriod(now, maxDate);
                                },
                              )
                            : const SizedBox.shrink(),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.more_horiz_rounded, color: (isDark ? Colors.white : Colors.black).withOpacity(0.7)),
                            onPressed: onShowGlobalActions,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<DataService>(
                  builder: (context, dataService, child) {
                    final List<dynamic> scheduleItems = [];
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final currentHour = now.hour + now.minute / 60.0;

                    for (int i = 0; i < 14; i++) {
                      final date = today.add(Duration(days: i));
                      var classes = dataService.getClassesForDate(date, includeDiscarded: true);

                      // Filter out classes that have already passed for today
                      if (i == 0) {
                        classes = classes.where((c) => c.endHour > currentHour).toList();
                      }

                      if (classes.isNotEmpty) {
                        scheduleItems.add(date); // Header
                        scheduleItems.addAll(classes);
                      }
                    }

                    if (scheduleItems.isEmpty) {
                      return Center(child: Text(l10n.noClassesProgrammed, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3))));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: scheduleItems.length,
                      itemBuilder: (context, index) {
                        final l10n = AppLocalizations.of(context)!;
                        final item = scheduleItems[index];
                        if (item is DateTime) {
                          return buildDateHeader(item, isDark, l10n);
                        } else if (item is ClassInstance) {
                          return buildClassItem(context, item, isDark, () => onShowClassOptions(item));
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Center(
                      child: Text(
                        l10n.done,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _DynamicHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String welcomeMessage;
  final VoidCallback onProfileTap;
  final double notificationSwipeProgress;

  _DynamicHeaderDelegate({required this.welcomeMessage, required this.onProfileTap, this.notificationSwipeProgress = 0.0});

  @override
  double get minExtent => 75;
  @override
  double get maxExtent => 155;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context);

    final now = DateTime.now();

    String dayName = DateFormat('EEEE', l10n.localeName).format(now);
    dayName = dayName[0].toUpperCase() + dayName.substring(1);

    double baseProgress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    double progress = Curves.easeInQuint.transform(baseProgress);
    double avatarSize = (56.0 - (progress * 20.0)).clamp(36.0, 56.0);
    double avatarContainerSize = avatarSize + (progress * 12.0);

    String dateLabel = DateFormat(l10n.datePattern, l10n.localeName).format(now);

    Widget buildConnectivityIndicator() {
      final status = dataService.connectivityStatus;
      IconData icon;
      String label;
      Color color;

      switch (status) {
        case ConnectivityStatus.wifi:
          icon = Icons.wifi_rounded;
          label = l10n.connected;
          color = Colors.green;
          break;
        case ConnectivityStatus.mobile:
          icon = Icons.swap_vert_rounded;
          label = l10n.mobileData;
          color = Colors.blue;
          break;
        case ConnectivityStatus.none:
          icon = Icons.cloud_off_rounded;
          label = l10n.noConnection;
          color = Colors.red;
          break;
        case ConnectivityStatus.syncing:
          icon = Icons.sync_rounded;
          label = l10n.syncing;
          color = colorScheme.primary;
          break;
      }

      return Row(
        key: ValueKey('connectivity_${status.name}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ConnectivityStatus.syncing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    final status = dataService.connectivityStatus;
    final bool isImportantStatus = status == ConnectivityStatus.syncing ||
        status == ConnectivityStatus.none ||
        status == ConnectivityStatus.mobile;

    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: ValueListenableBuilder<bool>(
          valueListenable: dataService.useMulticolor,
          builder: (context, isMulticolor, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: dataService.useDynamicColor,
              builder: (context, isDynamic, _) {
                final Color primaryColor = theme.colorScheme.primary;
                final Color surfaceColor = theme.colorScheme.surface;
                final gradientColors = isMulticolor
                    ? [const Color(0xFF8B5CF6).withOpacity(progress > 0.5 ? 1.0 : 0.8), const Color(0xFF6366F1).withOpacity(progress > 0.5 ? 1.0 : 0.8)]
                    : [primaryColor.withOpacity(progress > 0.5 ? 1.0 : 0.8), primaryColor.withOpacity(progress > 0.5 ? 1.0 : 0.8)];

                return Stack(
                  children: [
                    if (!isWideScreen)
                      Positioned(
                        left: 20,
                        top: lerpDouble(15, 14.5, progress),
                        child: GestureDetector(
                          onTap: onProfileTap,
                          child: Hero(
                            tag: 'profile_avatar_tag',
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: avatarContainerSize,
                                  height: avatarContainerSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: avatarContainerSize - 3,
                                  height: avatarContainerSize - 3,
                                  margin: const EdgeInsets.all(1.5),
                                  padding: EdgeInsets.all(progress * 6.0),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: UserAvatar(
                                    name: dataService.userName,
                                    photoUrl: FirebaseService().userPhotoUrl,
                                    size: avatarSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: isWideScreen ? 20 : 92,
                      top: lerpDouble(15, 30, progress),
                      right: 20,
                      height: avatarSize,
                      child: Opacity(
                        opacity: (1 - (progress * 4.0)).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            welcomeMessage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 20,
                      top: lerpDouble(75, 14.5, progress),
                      height: avatarContainerSize,
                      child: Container(
                        alignment: Alignment.lerp(Alignment.center, Alignment.centerRight, progress),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                          },
                          child: Container(
                            height: avatarContainerSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                colors: isMulticolor
                                    ? [const Color(0xFF8B5CF6).withOpacity(progress), const Color(0xFF6366F1).withOpacity(progress)]
                                    : [primaryColor.withOpacity(progress), primaryColor.withOpacity(progress)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              margin: EdgeInsets.all(progress > 0.1 ? 1.5 : 0),
                              padding: EdgeInsets.symmetric(horizontal: 14 * progress, vertical: 8 * progress),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: _CubeSwitcher(
                                alignment: Alignment.lerp(Alignment.center, Alignment.centerRight, progress)!,
                                child: (isImportantStatus && notificationSwipeProgress < 0.1)
                                    ? buildConnectivityIndicator()
                                    : (notificationSwipeProgress > 0.35)
                                        ? Row(
                                            key: const ValueKey('notif_info'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _RingingBell(
                                                isRinging: true,
                                                icon: Icons.notifications_active_rounded,
                                                size: (18 - (progress * 4.0)).clamp(14.0, 18.0),
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  dataService.hasUnreadNotifications
                                                      ? (l10n.localeName == 'es' ? 'Tienes notificaciones nuevas' : 'New notifications available')
                                                      : (l10n.localeName == 'es' ? 'No tienes notificaciones nuevas' : 'No new notifications'),
                                                  style: TextStyle(
                                                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade700,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            key: const ValueKey('date_info'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _RingingBell(
                                                isRinging: notificationSwipeProgress > 0.1,
                                                icon: getSeasonIcon(now),
                                                size: (18 - (progress * 4.0)).clamp(14.0, 18.0),
                                                color: notificationSwipeProgress > 0.1 ? Colors.amber : primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (notificationSwipeProgress < 0.2 && progress < 0.4)
                                                      Opacity(
                                                        opacity: (1 - (progress * 2.5)).clamp(0.0, 1.0),
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(right: 4),
                                                          child: Text('$dayName,', style: TextStyle(color: primaryColor, fontSize: 15), maxLines: 1),
                                                        ),
                                                      ),
                                                    Text(
                                                      dateLabel,
                                                      style: TextStyle(
                                                        color: primaryColor,
                                                        fontSize: (15 - (progress * 1.0)).clamp(13.0, 15.0),
                                                        fontWeight: progress > 0.6 ? FontWeight.w600 : FontWeight.normal,
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
      ),
    );
  }

  @override
  bool shouldRebuild(_DynamicHeaderDelegate oldDelegate) => true;
}

class _RingingBell extends StatefulWidget {
  final bool isRinging;
  final IconData icon;
  final Color color;
  final double size;

  const _RingingBell({
    required this.isRinging,
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_RingingBell> createState() => _RingingBellState();
}

class _RingingBellState extends State<_RingingBell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    if (widget.isRinging) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_RingingBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRinging && !oldWidget.isRinging) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRinging && oldWidget.isRinging) {
      _controller.animateTo(0.5, duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Mapear el valor de 0-1 a un ángulo de -0.3 a 0.3 radianes
        final double angle = (widget.isRinging || _controller.isAnimating) 
            ? (0.5 - _controller.value) * 0.7 
            : 0.0;
            
        return Transform.rotate(
          angle: angle,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _CollapsibleEventsCard extends StatefulWidget {
  final List<Reminder> events;
  const _CollapsibleEventsCard({required this.events});

  @override
  State<_CollapsibleEventsCard> createState() => _CollapsibleEventsCardState();
}

class _CollapsibleEventsCardState extends State<_CollapsibleEventsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    final bool isSingle = widget.events.length == 1;
    final event = widget.events.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isSingle 
              ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderDetailsScreen(reminder: event)))
              : () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSingle 
                            ? event.title 
                            : (l10n.localeName == 'es' 
                                ? "Hoy tienes ${widget.events.length} eventos" 
                                : "Today you have ${widget.events.length} events"),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isSingle 
                            ? (event.time ?? l10n.allDayLabel)
                            : (l10n.localeName == 'es' ? "Toca para ver detalles" : "Tap to see details"),
                          style: TextStyle(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSingle 
                      ? Icons.chevron_right_rounded
                      : (_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (!isSingle && _isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: widget.events.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildMiniEventRow(context, e, isDark, colorScheme),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniEventRow(BuildContext context, Reminder event, bool isDark, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderDetailsScreen(reminder: event))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.time != null)
              Text(
                event.time!,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SnappingScrollPhysics extends AlwaysScrollableScrollPhysics {
  final double snapOffset;
  const _SnappingScrollPhysics({required this.snapOffset, super.parent});

  @override
  _SnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnappingScrollPhysics(snapOffset: snapOffset, parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics metrics, double velocity) {
    if (metrics.pixels > 0 && metrics.pixels < snapOffset) {
      double target = velocity > 0 
          ? snapOffset 
          : (velocity < 0 ? 0 : (metrics.pixels > snapOffset / 3 ? snapOffset : 0));
      return ScrollSpringSimulation(spring, metrics.pixels, target, velocity, tolerance: tolerance);
    }
    return super.createBallisticSimulation(metrics, velocity);
  }
}

class _CubeSwitcher extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  final Duration duration;

  const _CubeSwitcher({
    required this.child, 
    this.alignment = Alignment.centerLeft,
    this.duration = const Duration(milliseconds: 550),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: alignment,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final isExiting = animation.status == AnimationStatus.dismissed || 
                              animation.status == AnimationStatus.reverse;
            
            double angle = (1.0 - animation.value) * (math.pi / 2);
            if (isExiting) angle = -angle;

            double zTranslation = 20.0 * (1.0 - animation.value);

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translate(0.0, 0.0, -zTranslation)
                ..rotateX(angle),
              alignment: alignment,
              child: Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}
