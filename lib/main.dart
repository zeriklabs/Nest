import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:intl/intl.dart';
import 'services/data_service.dart';
import 'services/firebase_service.dart';
import 'widgets/user_avatar.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/reminders_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_reminder_screen.dart';
import 'screens/note_editor_screen.dart';
import 'screens/create_notebook_screen.dart';
import 'screens/create_project_screen.dart';
import 'services/permission_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'models/subject.dart';
import 'widgets/nest_icon.dart';
import 'widgets/custom_nav_bar.dart';
import 'widgets/value_listenable_builders.dart';
import 'theme_constants.dart';



final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Eliminado WebViewPlatform.instance manual para permitir que v4 se autoconfigure en Web

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }

    Map<String, dynamic>? initialSettings;
    bool biometricEnabled = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('appearance_cache');
      if (cached != null) initialSettings = jsonDecode(cached);
      initialSettings ??= {};
      initialSettings['userName'] = prefs.getString('userName');
      initialSettings['userAlias'] = prefs.getString('userAlias');
      initialSettings['userEmail'] = prefs.getString('userEmail');
      initialSettings['profileCompleted'] = prefs.getBool('profileCompleted');
      initialSettings['userBirthday'] = prefs.getString('userBirthday');
      biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      debugPrint("Error loading initial settings: $e");
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => DataService(initialSettings: initialSettings),
        child: NestApp(isLocked: biometricEnabled),
      ),
    );
  }, (error, stack) {
    debugPrint("Global Error: $error");
  });
}

class NestApp extends StatefulWidget {
  final bool isLocked;
  const NestApp({super.key, this.isLocked = false});
  @override
  State<NestApp> createState() => _NestAppState();
}

class _NestAppState extends State<NestApp> {
  late StreamSubscription _intentDataStreamSubscription;
  late bool _isLocked;
  bool _checkingLock = false;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.isLocked;
    _initSharingListener();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    await PermissionService().requestAllPermissions();
  }

  void _initSharingListener() {
    if (kIsWeb) return;
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _processSharedFile(value.first.path);
    });
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _processSharedFile(value.first.path);
    });
  }

  void _processSharedFile(String path) async {
    final context = mainNavigatorKey.currentContext;
    if (context == null) return;
    String status = 'loading';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (status == 'loading') _performImport(path, (s) => setState(() => status = s));
          return PopScope(canPop: status != 'loading', child: const Center());
        },
      ),
    );
  }

  void _performImport(String path, Function(String) onResult) async {
    if (kIsWeb) {
      onResult('error');
      return;
    }
    try {
      final file = File(path);
      final jsonList = jsonDecode(await file.readAsString());
      final subjects = (jsonList as List).map((j) => Subject.fromJson(j)).toList();
      final ds = mainNavigatorKey.currentContext?.read<DataService>();
      if (ds != null) {
        ds.importSubjects(subjects);
        onResult('success');
      }
    } catch (e) { onResult('error'); }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return ValueListenableBuilder6<Locale, bool, ThemeMode, List<dynamic>, Color, bool>(
          first: dataService.appLocale,
          second: dataService.useDynamicColor,
          third: dataService.appThemeMode,
          fourth: const [],
          fifth: dataService.appAccentColor,
          sixth: dataService.useMulticolor,
          builder: (context, locale, isDynamic, mode, _, accentColor, isMulticolor, child) {
            final darkVariant = darkTheme;
            final lightVariant = lightTheme;
            final primaryColor = isMulticolor ? const Color(0xFF6366F1) : accentColor;
            final bool isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && (kIsWeb ? true : MediaQuery.platformBrightnessOf(context) == Brightness.dark));

            return MaterialApp(
              navigatorKey: mainNavigatorKey,
              title: 'Nest',
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                _SpanishFleatherLocalizationsDelegate(),
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              themeMode: mode,
              theme: _buildThemeData(lightVariant, isDynamic, lightDynamic, primaryColor, isMulticolor),
              darkTheme: _buildThemeData(darkVariant, isDynamic, darkDynamic, primaryColor, isMulticolor),
              home: (_checkingLock)
                ? _LoadingScaffold(message: "", isDark: isDark)
                : (_isLocked
                    ? LockScreen(onUnlocked: () => setState(() => _isLocked = false))
                    : const AppStartupGate()),
            );
          },
        );
      },
    );
  }

  ThemeData _buildThemeData(AppThemeData variant, bool isDynamic, ColorScheme? dynamicScheme, Color accentColor, bool isMulticolor) {
    ColorScheme colorScheme;
    final bool isDark = variant.brightness == Brightness.dark;

    if (isDynamic && dynamicScheme != null) {
      colorScheme = dynamicScheme;
    } else if (isMulticolor) {
      colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: variant.brightness,
        surface: variant.backgroundColor,
      ).copyWith(
        primary: const Color(0xFF6366F1),
        secondary: const Color(0xFFEC4899),
        tertiary: const Color(0xFF10B981),
      );
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: variant.brightness,
        surface: variant.backgroundColor,
      ).copyWith(
        primary: accentColor,
      );
    }

    // Material 3 aesthetic uses standard surface colors
    final Color backgroundColor = isDynamic ? colorScheme.surface : variant.backgroundColor;
    final Color cardColor = isDynamic
        ? ElevationOverlay.applySurfaceTint(colorScheme.surface, colorScheme.primary, 3)
        : variant.cardColor;

    return ThemeData(
      useMaterial3: true,
      brightness: variant.brightness,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: backgroundColor,
        indicatorColor: colorScheme.primary.withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            overflow: TextOverflow.ellipsis,
          );
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: isDynamic, // Center title for Material 3 standard
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDynamic ? 28 : 24), // M3 uses larger radius
        ),
      ),
    );
  }
}

class AppStartupGate extends StatelessWidget {
  const AppStartupGate({super.key});

  String? _getResetPasswordCodeFromUri() {
    if (!kIsWeb) return null;
    try {
      final uri = Uri.base;
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'] ?? uri.queryParameters['apiKey'];

      if ((mode == 'resetPassword' || mode == 'action') && oobCode != null && oobCode.isNotEmpty) {
        return oobCode;
      }

      if (uri.hasFragment) {
        final fragment = uri.fragment.startsWith('/') ? uri.fragment.substring(1) : uri.fragment;
        final fragmentUri = Uri.parse('http://dummy.com/$fragment');
        final fMode = fragmentUri.queryParameters['mode'];
        final fCode = fragmentUri.queryParameters['oobCode'];
        if ((fMode == 'resetPassword' || fCode != null) && fCode != null && fCode.isNotEmpty) {
          return fCode;
        }
      }
    } catch (e) {
      debugPrint("Error parsing reset password URI: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final resetCode = _getResetPasswordCodeFromUri();
    if (resetCode != null) {
      return ResetPasswordScreen(oobCode: resetCode);
    }

    return StreamBuilder<User?>(
      initialData: FirebaseAuth.instance.currentUser,
      stream: FirebaseService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final Widget child;

        if (user != null) {
          child = const MainNavigationScreen();
        } else if (snapshot.connectionState == ConnectionState.waiting && FirebaseAuth.instance.currentUser != null) {
          child = const _LoadingScaffold(message: "Preparando");
        } else {
          child = const LoginScreen();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
        );
      },
    );
  }
}

class _BouncingDotsText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _BouncingDotsText({required this.text, required this.style, super.key});

  @override
  State<_BouncingDotsText> createState() => _BouncingDotsTextState();
}

class _BouncingDotsTextState extends State<_BouncingDotsText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.text, style: widget.style),
        const SizedBox(width: 1),
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final double value = (_controller.value - delay) % 1.0;
              final double bounce = (value < 0.35) ? -4.0 * (1.0 - ((value - 0.175).abs() / 0.175)) : 0.0;
              final double opacity = (value < 0.35) ? 1.0 : 0.35;
              return Transform.translate(
                offset: Offset(0, bounce.clamp(-4.0, 0.0)),
                child: Opacity(
                  opacity: opacity.clamp(0.3, 1.0),
                  child: Text('.', style: widget.style.copyWith(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  final String message;
  final bool? isDark;
  const _LoadingScaffold({this.message = "Preparando", this.isDark, super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final String displayMsg = message.isNotEmpty ? message : "Preparando";

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0F0F11) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NestIcon(size: 88),
            const SizedBox(height: 36),
            SizedBox(
              width: 180,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor: colorScheme.primary.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _BouncingDotsText(
              text: displayMsg,
              style: TextStyle(
                color: dark ? Colors.white.withAlpha(165) : Colors.black.withAlpha(165),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _lastValidNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccountDeletionDialogs();
    });
  }

  void _checkAccountDeletionDialogs() {
    final dataService = context.read<DataService>();

    if (dataService.accountDeletionNotice.value != null) {
      final notice = dataService.accountDeletionNotice.value!;
      dataService.accountDeletionNotice.value = null;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Cuenta Eliminada', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(notice),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (dataService.pendingDeletionDate.value != null) {
      final scheduledDate = dataService.pendingDeletionDate.value!;
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(scheduledDate);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.restore_from_trash_rounded, color: Colors.red, size: 32),
          ),
          title: const Text('Cuenta en Periodo de Eliminación', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text(
            'Tu cuenta tiene una solicitud de eliminación programada para el $formattedDate.\n\n¿Deseas cancelar la eliminación y restaurar tu cuenta de Nest ahora?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await dataService.logout();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cerrar sesión'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await dataService.cancelAccountDeletion();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Solicitud cancelada! Tu cuenta de Nest ha sido restaurada.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Restaurar mi cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }
  final List<Widget> _pages = [
    const HomeScreen(key: PageStorageKey('home')),
    const RemindersScreen(key: PageStorageKey('reminders')),
    const GroupsScreen(key: PageStorageKey('groups')),
    const NotesScreen(key: PageStorageKey('notes')),
    const ScheduleScreen(),
    const SettingsScreen(heroTag: 'settings_tab_profile_tag'),
  ];

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final selectedIndex = dataService.mainTabIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (selectedIndex != 0) {
            dataService.mainTabIndex = 0;
          }
        },
        child: Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: isTablet
        ? Row(
              children: [
                _buildNavigationRail(context, selectedIndex, dataService, isDark, colorScheme),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: selectedIndex,
              children: _pages,
            ),
        bottomNavigationBar: isTablet
          ? null
          : ValueListenableBuilder2<bool, HomeLayout>(
              first: dataService.useDynamicColor,
              second: dataService.homeLayout,
              builder: (context, isDynamic, layout, _) {
                final bool simplified = layout == HomeLayout.simplified;

                int? navIndex;
                if (simplified) {
                  if (selectedIndex == 0) navIndex = 0;
                  else if (selectedIndex == 2) navIndex = 1;
                  else navIndex = null;
                } else {
                  if (selectedIndex < 5) navIndex = selectedIndex;
                  else navIndex = null;
                }

                if (navIndex != null) {
                  _lastValidNavIndex = navIndex;
                }

                Widget navWidget;
                if (isDynamic && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
                  navWidget = Container(
                    decoration: BoxDecoration(
                      color: ElevationOverlay.applySurfaceTint(
                        colorScheme.surface,
                        colorScheme.primary,
                        3,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: NavigationBarTheme(
                      data: NavigationBarThemeData(
                        indicatorColor: (navIndex == null)
                            ? Colors.transparent
                            : colorScheme.primary.withOpacity(0.12),
                        iconTheme: WidgetStateProperty.resolveWith((states) {
                          if (navIndex == null) return IconThemeData(color: isDark ? Colors.white38 : Colors.black38, size: 26);
                          if (states.contains(WidgetState.selected)) return IconThemeData(color: colorScheme.primary, size: 26);
                          return IconThemeData(color: isDark ? Colors.white38 : Colors.black38, size: 26);
                        }),
                      ),
                      child: NavigationBar(
                        key: ValueKey('nav_bar_${navIndex == null}'),
                        height: simplified ? 64 : 80,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        labelBehavior: simplified ? NavigationDestinationLabelBehavior.alwaysHide : NavigationDestinationLabelBehavior.onlyShowSelected,
                        selectedIndex: navIndex ?? _lastValidNavIndex,
                        onDestinationSelected: (i) {
                          if (simplified) {
                            if (i == 0) dataService.mainTabIndex = 0;
                            if (i == 1) dataService.mainTabIndex = 2;
                          } else {
                            dataService.mainTabIndex = i;
                          }
                        },
                        destinations: simplified ? [
                          NavigationDestination(
                            icon: const Icon(Icons.home_outlined),
                            selectedIcon: Icon(navIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
                            label: l10n.today,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.groups_outlined),
                            selectedIcon: Icon(navIndex == 1 ? Icons.groups_rounded : Icons.groups_outlined),
                            label: l10n.groups,
                          ),
                        ] : [
                          NavigationDestination(
                            icon: const Icon(Icons.home_outlined),
                            selectedIcon: Icon(navIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
                            label: l10n.today,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.format_list_bulleted_outlined),
                            selectedIcon: Icon(navIndex == 1 ? Icons.format_list_bulleted_rounded : Icons.format_list_bulleted_outlined),
                            label: l10n.reminders,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.groups_outlined),
                            selectedIcon: Icon(navIndex == 2 ? Icons.groups_rounded : Icons.groups_outlined),
                            label: l10n.groups,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.description_outlined),
                            selectedIcon: Icon(navIndex == 3 ? Icons.description_rounded : Icons.description_outlined),
                            label: l10n.notes,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.schedule_outlined),
                            selectedIcon: Icon(navIndex == 4 ? Icons.schedule_rounded : Icons.schedule_outlined),
                            label: l10n.schedule,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  navWidget = CustomNavBar(
                    selectedIndex: selectedIndex,
                    isSimplified: simplified,
                    useMaterial3: dataService.useDynamicColor.value,
                    onItemSelected: (i) => dataService.mainTabIndex = i,
                  );
                }

                if (simplified) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 160,
                            child: navWidget,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCurrentClassPill(context, dataService, isDark, colorScheme, isDynamic: isDynamic),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: navWidget,
                  ),
                );
              },
            ),
        ),
      ),
    );
  }

  Widget _buildCurrentClassPill(BuildContext context, DataService dataService, bool isDark, ColorScheme colorScheme, {bool isDynamic = false}) {
    final l10n = AppLocalizations.of(context)!;
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
      if (tomorrowClasses.isNotEmpty) nextClass = tomorrowClasses.first;
    }

    final currentTitle = currentClass?.subject.name ?? (nextClass != null && nextClass.date.day == now.day ? l10n.freeSlot : l10n.dayFinished);
    final currentSub = currentClass != null
        ? (currentClass.schedule.room ?? 'S/N')
        : (nextClass != null && nextClass.date.day == now.day ? l10n.nextClassPrefix(nextClass.subject.name) : l10n.restTime);

    final bool isScheduleTab = dataService.mainTabIndex == 4;
    final bool isRemindersTab = dataService.mainTabIndex == 1;
    final bool isNotesTab = dataService.mainTabIndex == 3;
    final bool isAddTab = isScheduleTab || isRemindersTab || isNotesTab;
    final Color subjectColor = currentClass?.subject.color ?? nextClass?.subject.color ?? colorScheme.primary;

    if (isDynamic) {
      final Color containerColor = isAddTab
          ? colorScheme.primary
          : colorScheme.primaryContainer;
      final Color onContainerColor = isAddTab
          ? colorScheme.onPrimary
          : colorScheme.onPrimaryContainer;

      return GestureDetector(
        onTap: () {
          if (isScheduleTab) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubjectEditorSheet(),
                fullscreenDialog: true,
              ),
            );
          } else if (isRemindersTab) {
            _showAddReminderOptions(context, colorScheme);
          } else if (isNotesTab) {
            if (dataService.notesTabIndex == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateNotebookScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NoteEditorScreen()));
            }
          } else {
            dataService.mainTabIndex = 4;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isAddTab ? Colors.transparent : colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAddTab ? Icons.add_rounded : Icons.schedule_rounded,
                color: onContainerColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isScheduleTab
                        ? l10n.addSubjectBtn
                        : (isRemindersTab
                            ? l10n.addReminder
                            : (isNotesTab ? l10n.newPage : currentTitle)),
                      style: TextStyle(color: onContainerColor, fontSize: 12, fontWeight: FontWeight.bold, height: 1.1),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isScheduleTab
                        ? l10n.newSubject
                        : (isRemindersTab
                            ? l10n.newReminder
                            : (isNotesTab
                                ? (dataService.notesTabIndex == 1 ? l10n.newNotebook : l10n.quickNote)
                                : currentSub)),
                      style: TextStyle(color: onContainerColor.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Color pillBg = isAddTab ? subjectColor : (isDark ? const Color(0xFF1A1A1C) : Colors.white);
    final Color pillContentColor = isAddTab ? Colors.white : (isDark ? Colors.white : Colors.black);

    return GestureDetector(
      onTap: () {
        if (isScheduleTab) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubjectEditorSheet(),
              fullscreenDialog: true,
            ),
          );
        } else if (isRemindersTab) {
          _showAddReminderOptions(context, colorScheme);
        } else if (isNotesTab) {
          if (dataService.notesTabIndex == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateNotebookScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NoteEditorScreen()));
          }
        } else {
          dataService.mainTabIndex = 4;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isAddTab ? Colors.white.withOpacity(0.2) : subjectColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                isAddTab ? Icons.add_rounded : Icons.schedule_rounded,
                key: ValueKey(isAddTab),
                color: pillContentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: Column(
                  key: ValueKey(isAddTab ? 'add' : 'info'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isScheduleTab
                        ? l10n.addSubjectBtn
                        : (isRemindersTab
                            ? l10n.addReminder
                            : (isNotesTab ? l10n.newPage : currentTitle)),
                      style: TextStyle(color: pillContentColor, fontSize: 12, fontWeight: FontWeight.bold, height: 1.1),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isScheduleTab
                        ? l10n.newSubject
                        : (isRemindersTab
                            ? l10n.newReminder
                            : (isNotesTab
                                ? (dataService.notesTabIndex == 1 ? l10n.newNotebook : l10n.quickNote)
                                : currentSub)),
                      style: TextStyle(color: pillContentColor.withOpacity(isAddTab ? 0.9 : 0.6), fontSize: 9, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderOptions(BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(l10n.whatToCreate, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildOptionItem(context, icon: Icons.notification_add_rounded, title: l10n.newReminder, subtitle: l10n.remindersSubtitle, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AddReminderScreen())); }),
            const SizedBox(height: 12),
            _buildOptionItem(context, icon: Icons.folder_special_rounded, title: l10n.newProject, subtitle: l10n.newProjectSubtitle, onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProjectScreen())); }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colorScheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: colorScheme.primary)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }


  Widget _buildNavigationRail(BuildContext context, int selectedIndex, DataService dataService, bool isDark, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final photoUrl = FirebaseService().userPhotoUrl;
    final size = MediaQuery.of(context).size;
    final bool isLandscape = size.width > size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        // Si la altura es poca (ej. ventana emergente), reducimos drásticamente los espaciados
        final bool isShort = availableHeight < 600;

        final double verticalSpacing = isShort ? 8.0 : (isLandscape ? 18.0 : 24.0);
        final double leadingBottomPadding = isShort ? 12.0 : (isLandscape ? 30.0 : 60.0);
        final double iconSize = isShort ? 28.0 : (isLandscape ? 30.0 : 32.0);
        final double avatarSize = isShort ? 44.0 : (isLandscape ? 52.0 : 60.0);

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availableHeight),
              child: IntrinsicHeight(
                child: ValueListenableBuilder2<bool, HomeLayout>(
                  first: dataService.useDynamicColor,
                  second: dataService.homeLayout,
                  builder: (context, isDynamic, layout, _) {
                    final bool simplified = layout == HomeLayout.simplified;

                    int? navIndex;
                    if (simplified) {
                      if (selectedIndex == 0) navIndex = 0;
                      else if (selectedIndex == 2) navIndex = 1;
                      else navIndex = null;
                    } else {
                      navIndex = selectedIndex > 4 ? null : selectedIndex;
                    }

                    if (isDynamic && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
                      return NavigationRail(
                        groupAlignment: 0.0,
                        selectedIndex: navIndex,
                        onDestinationSelected: (i) {
                          if (simplified) {
                            if (i == 0) dataService.mainTabIndex = 0;
                            if (i == 1) dataService.mainTabIndex = 2;
                          } else {
                            dataService.mainTabIndex = i;
                          }
                        },
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: Colors.transparent,
                        leading: _buildRailLeading(context, selectedIndex, dataService, colorScheme, iconSize, avatarSize, isLandscape, leadingBottomPadding),
                        destinations: simplified ? [
                          NavigationRailDestination(
                            icon: const Icon(Icons.home_outlined), 
                            selectedIcon: const Icon(Icons.home_rounded),
                            label: Text(l10n.today),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.groups_outlined), 
                            selectedIcon: const Icon(Icons.groups_rounded),
                            label: Text(l10n.groups),
                          ),
                        ] : [
                          NavigationRailDestination(
                            icon: const Icon(Icons.home_outlined), 
                            selectedIcon: const Icon(Icons.home_rounded),
                            label: Text(l10n.today),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.format_list_bulleted_outlined), 
                            selectedIcon: const Icon(Icons.format_list_bulleted_rounded),
                            label: Text(l10n.reminders),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.groups_outlined), 
                            selectedIcon: const Icon(Icons.groups_rounded),
                            label: Text(l10n.groups),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.description_outlined), 
                            selectedIcon: const Icon(Icons.description_rounded),
                            label: Text(l10n.notes),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.schedule_outlined),
                            selectedIcon: const Icon(Icons.calendar_today_rounded),
                            label: Text(l10n.schedule),
                          ),
                        ],
                      );
                    }

                    return NavigationRail(
                      groupAlignment: 0.0,
                      selectedIndex: navIndex,
                      onDestinationSelected: (i) {
                        if (simplified) {
                          if (i == 0) dataService.mainTabIndex = 0;
                          if (i == 1) dataService.mainTabIndex = 2;
                        } else {
                          dataService.mainTabIndex = i;
                        }
                      },
                      labelType: NavigationRailLabelType.none,
                      minWidth: isLandscape ? 85 : 95,
                      backgroundColor: Colors.transparent,
                      indicatorColor: colorScheme.primary.withOpacity(0.1),
                      selectedIconTheme: IconThemeData(color: colorScheme.primary, size: iconSize),
                      unselectedIconTheme: IconThemeData(
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                        size: iconSize,
                      ),
                      leading: _buildRailLeading(context, selectedIndex, dataService, colorScheme, iconSize, avatarSize, isLandscape, leadingBottomPadding),
                      destinations: simplified ? [
                        _buildRailDestination(
                          icon: Icons.home_rounded,
                          label: l10n.today,
                          verticalPadding: verticalSpacing,
                        ),
                        _buildRailDestination(
                          icon: Icons.groups_rounded,
                          label: l10n.groups,
                          verticalPadding: verticalSpacing,
                        ),
                      ] : [
                        _buildRailDestination(
                          icon: Icons.home_rounded,
                          label: l10n.today,
                          verticalPadding: verticalSpacing,
                        ),
                        _buildRailDestination(
                          icon: Icons.format_list_bulleted_rounded,
                          label: l10n.reminders,
                          verticalPadding: verticalSpacing,
                        ),
                        _buildRailDestination(
                          icon: Icons.groups_rounded,
                          label: l10n.groups,
                          verticalPadding: verticalSpacing,
                        ),
                        _buildRailDestination(
                          icon: Icons.description_rounded,
                          label: l10n.notes,
                          verticalPadding: verticalSpacing,
                        ),
                        _buildRailDestination(
                          icon: Icons.schedule_outlined,
                          label: l10n.schedule,
                          verticalPadding: verticalSpacing,
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRailLeading(BuildContext context, int selectedIndex, DataService dataService, ColorScheme colorScheme, double iconSize, double avatarSize, bool isLandscape, double leadingBottomPadding) {
    final photoUrl = FirebaseService().userPhotoUrl;
    final bool isSettingsSelected = selectedIndex == 5;

    return Padding(
      padding: EdgeInsets.only(top: isLandscape ? 16 : 24, bottom: leadingBottomPadding),
      child: GestureDetector(
        onTap: () {
          dataService.mainTabIndex = 5; // Index de Settings
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSettingsSelected ? colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: isSettingsSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
              width: 2.0,
            ),
          ),
          child: isSettingsSelected
              ? Icon(
                  Icons.settings_rounded,
                  color: colorScheme.onPrimary,
                  size: avatarSize * 0.55,
                )
              : UserAvatar(
                  name: dataService.userName,
                  photoUrl: photoUrl,
                  size: avatarSize,
                ),
        ),
      ),
    );
  }

  NavigationRailDestination _buildRailDestination({required IconData icon, required String label, double verticalPadding = 24}) {
    return NavigationRailDestination(
      icon: Icon(icon),
      label: Text(label),
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
    );
  }
}

class _SpanishFleatherLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _SpanishFleatherLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return GlobalWidgetsLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(_SpanishFleatherLocalizationsDelegate old) => false;
}
