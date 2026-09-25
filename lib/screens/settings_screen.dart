import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'package:nest/widgets/value_listenable_builders.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import 'app_data_screen.dart';
import 'account_settings_screen.dart';
import 'appearance_screen.dart';
import 'calendar_sync_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'notifications_settings_screen.dart';
import 'security_settings_screen.dart';
import '../widgets/user_avatar.dart';

class _MenuOption {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  const _MenuOption(this.index, this.title, this.subtitle, this.icon);
}

class SettingsScreen extends StatefulWidget {
  final String heroTag;
  const SettingsScreen({super.key, this.heroTag = 'profile_avatar_tag'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  Widget _getDetailWidget(int index) {
    switch (index) {
      case 0:
        return const AccountSettingsScreen();
      case 1:
        return const AppearanceScreen();
      case 2:
        return const SecuritySettingsScreen();
      case 3:
        return const CalendarSyncScreen();
      case 4:
        return const NotificationsSettingsScreen();
      case 5:
        return const AppDataScreen();
      case 6:
        return const HelpSupportScreen();
      case 7:
        return const AboutScreen();
      default:
        return const AccountSettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = context.watch<DataService>();
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 720;

    return ValueListenableBuilder2<bool, bool>(
      first: dataService.useDynamicColor,
      second: dataService.useMulticolor,
      builder: (context, isDynamic, isMulticolor, child) {
        final colorScheme = theme.colorScheme;

        if (isWide) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Row(
                children: [
                  // Panel Izquierdo: Menú de Opciones
                  _buildLeftMasterPane(context, dataService, colorScheme, isDark, l10n, widget.heroTag),
                  
                  // Divisor vertical sutil
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withAlpha(40),
                  ),

                  // Panel Derecho: Pantalla de Detalle Seleccionada
                  Expanded(
                    child: _buildRightDetailPane(context, colorScheme),
                  ),
                ],
              ),
            ),
          );
        }

        final content = _buildMobileContent(context, dataService, colorScheme, isDynamic, isMulticolor, isDark, l10n, widget.heroTag);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -700) {
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  l10n.settings,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
              body: content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftMasterPane(BuildContext context, DataService dataService, ColorScheme colorScheme, bool isDark, AppLocalizations l10n, String heroTag) {
    final fb = FirebaseService();

    final menuItems = [
      _MenuOption(1, l10n.appearance, 'Tema y colores', Icons.palette_rounded),
      _MenuOption(2, l10n.security, 'Contraseña y seguridad', Icons.security_rounded),
      _MenuOption(3, l10n.calendarSync, dataService.calendarSyncEnabled ? 'Activado' : 'Desactivado', Icons.calendar_today_rounded),
      _MenuOption(4, l10n.notifications, l10n.activated, Icons.notifications_rounded),
      _MenuOption(5, 'Sincronización y Datos', 'Estado de red y almacenamiento', Icons.cloud_rounded),
      _MenuOption(6, l10n.helpSupport, 'Preguntas y soporte', Icons.help_rounded),
      _MenuOption(7, l10n.aboutNest, 'Información y versión', Icons.info_rounded),
    ];

    final bool isProfileSelected = _selectedIndex == 0;

    return Container(
      width: 320,
      color: isDark ? colorScheme.surfaceContainerLowest : colorScheme.surfaceContainerLow.withAlpha(120),
      child: Column(
        children: [
          // Header del Menú
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                if (Navigator.canPop(context))
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                Expanded(
                  child: Text(
                    l10n.settings,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tarjeta Unificada de Perfil de Usuario (Index 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _selectedIndex = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isProfileSelected
                        ? colorScheme.primary.withAlpha(30)
                        : (isDark ? colorScheme.surfaceContainerHighest.withAlpha(50) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isProfileSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withAlpha(40),
                      width: isProfileSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: dataService.userName,
                        photoUrl: fb.userPhotoUrl,
                        size: 46,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dataService.userName,
                              style: TextStyle(
                                color: isProfileSelected ? colorScheme.primary : colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              dataService.userAlias.isNotEmpty ? '@${dataService.userAlias}' : 'Sin alias',
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(140),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isProfileSelected ? colorScheme.primary : colorScheme.onSurface.withAlpha(80),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Divider(height: 16, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withAlpha(40)),

          // Lista de Opciones
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _selectedIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: isSelected
                          ? colorScheme.primary.withAlpha(30)
                          : Colors.transparent,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: isSelected ? Colors.white : colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(120),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = item.index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightDetailPane(BuildContext context, ColorScheme colorScheme) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _getDetailWidget(_selectedIndex),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context, DataService dataService, ColorScheme colorScheme, bool isDynamic, bool isMulticolor, bool isDark, AppLocalizations l10n, String heroTag) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle(context, l10n.myProfile),
          _buildAccountCard(context, colorScheme, heroTag),
          
          const SizedBox(height: 32),
          _buildSectionTitle(context, l10n.preferences),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.palette_outlined,
              iconColor: (isMulticolor && !isDynamic) ? const Color(0xFFEC4899) : colorScheme.primary,
              title: l10n.appearance,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppearanceScreen()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.language_rounded,
              iconColor: (isMulticolor && !isDynamic) ? const Color(0xFFF59E0B) : colorScheme.primary,
              title: l10n.language,
              onTap: () => _showLanguageDialog(context, dataService),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_none_rounded,
              iconColor: (isMulticolor && !isDynamic) ? const Color(0xFF8B5CF6) : colorScheme.primary,
              title: l10n.notifications,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsSettingsScreen()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.security_rounded,
              iconColor: (isMulticolor && !isDynamic) ? const Color(0xFF6366F1) : colorScheme.primary,
              title: l10n.security,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.calendar_today_rounded,
              iconColor: (isMulticolor && !isDynamic) ? const Color(0xFF10B981) : colorScheme.primary,
              title: l10n.calendarSync,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarSyncScreen()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.cloud_rounded,
              iconColor: (isMulticolor && !isDynamic) ? const Color(0xFF3B82F6) : colorScheme.primary,
              title: l10n.syncAndData,
              isLast: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppDataScreen()),
              ),
            ),
          ]),

          const SizedBox(height: 32),
          _buildSectionTitle(context, l10n.infoSection),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.help_outline_rounded,
              iconColor: isDark ? Colors.white70 : Colors.black54,
              title: l10n.helpSupport,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline_rounded,
              iconColor: isDark ? Colors.white70 : Colors.black54,
              title: l10n.aboutNest,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              ),
              isLast: true,
            ),
          ]),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, DataService dataService) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
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
                l10n.localeName == 'es' ? 'Seleccionar Idioma' : 'Select Language',
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(context, 'Español', const Locale('es'), colorScheme, dataService),
              const SizedBox(height: 12),
              _buildLanguageOption(context, 'English', const Locale('en'), colorScheme, dataService),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, Locale locale, ColorScheme colorScheme, DataService dataService) {
    bool isSelected = dataService.appLocale.value == locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colorScheme.primary.withAlpha(76) : (isDark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(13)),
        ),
      ),
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
            color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
        onTap: () {
          dataService.appLocale.value = locale;
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withAlpha(76),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, ColorScheme colorScheme, String heroTag) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = colorScheme.primary;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = context.watch<DataService>();
    final fb = FirebaseService();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withAlpha(13)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withAlpha(isDark ? 38 : 20),
                      primaryColor.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const AccountSettingsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeOutCubic;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
                borderRadius: BorderRadius.circular(32),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Hero(
                        tag: heroTag,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withAlpha(25), width: 1),
                              ),
                            ),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withAlpha(25),
                                border: Border.all(color: primaryColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withAlpha(51),
                                    blurRadius: 15,
                                    spreadRadius: -5,
                                  )
                                ],
                              ),
                              child: UserAvatar(
                                name: dataService.userName,
                                photoUrl: fb.userPhotoUrl,
                                size: 72,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dataService.userName,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dataService.userAlias.isNotEmpty ? '@${dataService.userAlias}' : 'Sin alias',
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black).withAlpha(102),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: primaryColor.withAlpha(25)),
                                  ),
                                  child: Text(
                                    fb.isAnonymous ? l10n.guest : dataService.userIdentifier,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                if (!fb.isAnonymous) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showMyQrCode(context, dataService.userIdentifier, fb.userPhotoUrl, primaryColor),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(8),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withAlpha(13)),
                                      ),
                                      child: Icon(
                                        Icons.qr_code_2_rounded,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      Icon(
                        Icons.chevron_right_rounded,
                        color: (isDark ? Colors.white : Colors.black).withAlpha(76),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyQrCode(BuildContext context, String identifier, String? photoUrl, Color primaryColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = context.read<DataService>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? theme.cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mi Código QR',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              UserAvatar(
                name: dataService.userName,
                photoUrl: photoUrl,
                size: 60,
              ),
              const SizedBox(height: 12),
              
              Text(
                dataService.userName,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                identifier,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: identifier,
                  version: QrVersions.auto,
                  size: 180.0,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: primaryColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Escanea para compartir esta cuenta de Nest',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: identifier));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID copiado al portapapeles'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar ID'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withAlpha(13)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(102),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: (isDark ? Colors.white : Colors.black).withAlpha(76),
                size: 20,
              ),
            ],
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 64,
            endIndent: 20,
            color: (isDark ? Colors.white : Colors.black).withAlpha(13),
          ),
      ],
    );
  }
}
