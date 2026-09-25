import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'package:nest/services/data_service.dart';
import 'package:nest/theme_constants.dart';
import 'package:nest/widgets/value_listenable_builders.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dataService = context.watch<DataService>();
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;
    final bool isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.appearance,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. MODO PREDETERMINADO (Arriba de la Vista Previa)
                _buildSectionTitle(l10n.defaultMode),
                _buildSettingsCard(context, child: _buildModeSelector(context, l10n, dataService)),
                const SizedBox(height: 24),

                // 2. VISTA PREVIA EN VIVO
                _buildLiveThemePreview(context, dataService),
                const SizedBox(height: 20),

                // 3. MODO DE LA APP (Abajo de la Vista Previa)
                if (!isTablet) ...[
                  _buildSectionTitle(l10n.appMode),
                  _buildHomeLayoutSchemes(context, l10n, dataService),
                  const SizedBox(height: 28),
                ],

                // 4. TEMAS Y COLORES DE ACENTO
                _buildSectionTitle(l10n.themes),
                _buildSettingsCard(
                  context, 
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (isAndroid) ...[
                        _buildMaterial3Option(context, l10n, dataService),
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 20, endIndent: 20),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _buildAccentColorSelector(context, dataService),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 5. ESTILO DE HORARIO (ESQUEMAS: CUADRÍCULA VS LISTA)
                _buildSectionTitle(l10n.scheduleStyle),
                _buildScheduleStyleSchemes(context, l10n, dataService),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveThemePreview(BuildContext context, DataService dataService) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        dataService.homeLayout,
        dataService.useDynamicColor,
        dataService.useMulticolor,
        dataService.appAccentColor,
        dataService.appThemeMode,
      ]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final isMulticolor = dataService.useMulticolor.value;
        final isDynamic = dataService.useDynamicColor.value;
        final primary = isDynamic ? theme.colorScheme.primary : (isMulticolor ? const Color(0xFF6366F1) : dataService.appAccentColor.value);
        final isSimplified = dataService.homeLayout.value == HomeLayout.simplified;

        final size = MediaQuery.of(context).size;
        final double screenWidth = size.width;
        final bool isWeb = kIsWeb;
        final bool isTablet = screenWidth > 800;
        final bool isFoldable = screenWidth > 600 && screenWidth <= 800;

        String deviceBadgeText = l10n.phoneDevice;
        IconData deviceBadgeIcon = Icons.smartphone_rounded;
        if (isWeb) {
          deviceBadgeText = l10n.webBrowserDevice;
          deviceBadgeIcon = Icons.language_rounded;
        } else if (isTablet) {
          deviceBadgeText = l10n.tabletDevice;
          deviceBadgeIcon = Icons.tablet_mac_rounded;
        } else if (isFoldable) {
          deviceBadgeText = l10n.foldableDevice;
          deviceBadgeIcon = Icons.devices_fold_rounded;
        }

        final cardBg = isDark ? const Color(0xFF1B1C22) : Colors.white;
        final frameBg = isDark ? const Color(0xFF0D0E12) : const Color(0xFFF8F9FA);
        final textPrimary = isDark ? Colors.white : Colors.black87;
        final textSecondary = isDark ? Colors.white54 : Colors.black54;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121318) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye_rounded, size: 18, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.livePreview,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primary.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        Icon(deviceBadgeIcon, size: 12, color: primary),
                        const SizedBox(width: 5),
                        Text(
                          '$deviceBadgeText  |  ${isDark ? l10n.dark : l10n.lightMode}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Device Adaptive Frame Mockup
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: (isTablet || isWeb) ? 340 : (isFoldable ? 290 : 180),
                  height: (isTablet || isWeb) ? 220 : (isFoldable ? 260 : 360),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: frameBg,
                    borderRadius: BorderRadius.circular(isWeb ? 12 : (isTablet ? 16 : 28)),
                    border: Border.all(color: primary.withAlpha(100), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withAlpha(25),
                        blurRadius: 20,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Camera punch hole for phone
                      if (!isWeb)
                        Center(
                          child: Container(
                            width: 6, height: 6,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black26,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Avatar + Title/Date according to mode
                            if (!isSimplified) ...[
                              // ORIGINAL MODE HEADER: Avatar + Greeting line (No bell on top right), Date centered below
                              Row(
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: const Text('J', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(width: 70, height: 5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2.5))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.eco_rounded, size: 9, color: primary),
                                      const SizedBox(width: 4),
                                      Container(width: 45, height: 3.5, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // SIMPLIFIED MODE HEADER: Avatar + Date line + Bell icon on top right
                              Row(
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: const Text('J', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(width: 65, height: 5.5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(3))),
                                  ),
                                  Icon(Icons.notifications_none_rounded, size: 15, color: primary),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),

                            // Main Body Content according to selected layout
                            if (!isSimplified) ...[
                              // ORIGINAL LAYOUT: Stacked Cards + Floating Current Class Card
                              // Card 1: Today
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 3),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 35, height: 4.5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2))),
                                            const SizedBox(width: 3),
                                            Icon(Icons.chevron_right_rounded, size: 11, color: textSecondary),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(color: primary.withAlpha(25), shape: BoxShape.circle),
                                          child: Icon(Icons.add, size: 9, color: primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.wb_sunny_outlined, size: 11, color: textSecondary),
                                        const SizedBox(width: 4),
                                        Container(width: 60, height: 3.5, decoration: BoxDecoration(color: textSecondary, borderRadius: BorderRadius.circular(2))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Card 2: Recent Notes
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 3),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 45, height: 4.5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2))),
                                            const SizedBox(width: 3),
                                            Icon(Icons.chevron_right_rounded, size: 11, color: textSecondary),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(color: primary.withAlpha(25), shape: BoxShape.circle),
                                          child: Icon(Icons.add, size: 9, color: primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(color: primary.withAlpha(25), borderRadius: BorderRadius.circular(5)),
                                          child: Icon(Icons.description_outlined, size: 9, color: primary),
                                        ),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(width: 55, height: 4, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2))),
                                            const SizedBox(height: 2),
                                            Container(width: 35, height: 3, decoration: BoxDecoration(color: textSecondary, borderRadius: BorderRadius.circular(1.5))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              // Card 3: Current Class Floating Card (attached above nav bar)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: primary.withAlpha(50), width: 0.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(width: 40, height: 3, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(1.5))),
                                    const SizedBox(height: 2),
                                    Container(width: 60, height: 4.5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.arrow_forward_rounded, size: 7, color: textSecondary),
                                              const SizedBox(width: 3),
                                              Container(width: 50, height: 3.5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(1.5))),
                                            ],
                                          ),
                                          Container(width: 20, height: 3, decoration: BoxDecoration(color: textSecondary, borderRadius: BorderRadius.circular(1.5))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                            ] else ...[
                              // SIMPLIFIED LAYOUT: Real Simplified Home Cards (Today + Recent Notes)
                              // Card 1: Today
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 3),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 35, height: 4.5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2))),
                                            const SizedBox(width: 3),
                                            Icon(Icons.chevron_right_rounded, size: 11, color: textSecondary),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(color: primary.withAlpha(25), shape: BoxShape.circle),
                                          child: Icon(Icons.add, size: 9, color: primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.wb_sunny_outlined, size: 11, color: textSecondary),
                                        const SizedBox(width: 4),
                                        Container(width: 60, height: 3.5, decoration: BoxDecoration(color: textSecondary, borderRadius: BorderRadius.circular(2))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Card 2: Recent Notes
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 3),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 45, height: 4.5, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2))),
                                            const SizedBox(width: 3),
                                            Icon(Icons.chevron_right_rounded, size: 11, color: textSecondary),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(color: primary.withAlpha(25), shape: BoxShape.circle),
                                          child: Icon(Icons.add, size: 9, color: primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(color: primary.withAlpha(25), borderRadius: BorderRadius.circular(5)),
                                          child: Icon(Icons.description_outlined, size: 9, color: primary),
                                        ),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(width: 55, height: 4, decoration: BoxDecoration(color: textPrimary, borderRadius: BorderRadius.circular(2))),
                                            const SizedBox(height: 2),
                                            Container(width: 35, height: 3, decoration: BoxDecoration(color: textSecondary, borderRadius: BorderRadius.circular(1.5))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],

                            // Floating Bottom Navigation Bar
                            if (!isSimplified) ...[
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 12), blurRadius: 6, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildMiniNavItem(Icons.home_rounded, true, primary, isDynamic, cardBg),
                                    _buildMiniNavItem(Icons.format_list_bulleted_rounded, false, primary, isDynamic, cardBg),
                                    _buildMiniNavItem(Icons.groups_rounded, false, primary, isDynamic, cardBg),
                                    _buildMiniNavItem(Icons.description_rounded, false, primary, isDynamic, cardBg),
                                    _buildMiniNavItem(Icons.schedule_outlined, false, primary, isDynamic, cardBg),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Container(
                                    width: 52, height: 26,
                                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Icon(Icons.home_rounded, size: 13, color: primary),
                                        Icon(Icons.groups_rounded, size: 13, color: textSecondary),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 26,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: primary.withAlpha(25),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: primary.withAlpha(60), width: 0.5),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(width: 3, height: 12, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(1.5))),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('CURRENT CLASS', style: TextStyle(color: primary, fontSize: 6.5, fontWeight: FontWeight.w900)),
                                                Text('Day finished', style: TextStyle(color: textPrimary, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniNavItem(IconData icon, bool isSelected, Color primary, bool isDynamic, Color cardBg) {
    if (isDynamic && isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: primary.withAlpha(40),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 10, color: primary),
      );
    }
    return Icon(
      icon,
      size: 10,
      color: isSelected ? primary : Colors.grey,
    );
  }

  Widget _buildScheduleStyleSchemes(BuildContext context, AppLocalizations l10n, DataService dataService) {
    return ValueListenableBuilder<ScheduleStyle>(
      valueListenable: dataService.scheduleStyle,
      builder: (context, selectedStyle, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorScheme = Theme.of(context).colorScheme;

        return Row(
          children: [
            Expanded(
              child: _buildSchemeCard(
                context,
                title: l10n.gridStyle,
                subtitle: l10n.hoursAndDaysGrid,
                isSelected: selectedStyle == ScheduleStyle.grid,
                onTap: () => dataService.scheduleStyle.value = ScheduleStyle.grid,
                mockWidget: _buildGridMockScheme(context, selectedStyle == ScheduleStyle.grid, isDark, colorScheme),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSchemeCard(
                context,
                title: l10n.timelineStyle,
                subtitle: l10n.chronologicalList,
                isSelected: selectedStyle == ScheduleStyle.timeline,
                onTap: () => dataService.scheduleStyle.value = ScheduleStyle.timeline,
                mockWidget: _buildListMockScheme(context, selectedStyle == ScheduleStyle.timeline, isDark, colorScheme),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeLayoutSchemes(BuildContext context, AppLocalizations l10n, DataService dataService) {
    return ValueListenableBuilder<HomeLayout>(
      valueListenable: dataService.homeLayout,
      builder: (context, selectedLayout, child) {
        return Row(
          children: [
            Expanded(
              child: _buildSimpleLayoutCard(
                context,
                title: l10n.originalLayout,
                subtitle: l10n.fullPanel,
                icon: Icons.dashboard_rounded,
                isSelected: selectedLayout == HomeLayout.original,
                onTap: () => dataService.homeLayout.value = HomeLayout.original,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSimpleLayoutCard(
                context,
                title: l10n.simplifiedLayout,
                subtitle: l10n.essentialMinimalist,
                icon: Icons.splitscreen_rounded,
                isSelected: selectedLayout == HomeLayout.simplified,
                onTap: () => dataService.homeLayout.value = HomeLayout.simplified,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleLayoutCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(20)
              : (isDark ? theme.cardColor : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? colorScheme.primary : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary.withAlpha(35) : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark ? Colors.white : Colors.black).withAlpha(120),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget mockWidget,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(20)
              : (isDark ? theme.cardColor : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                mockWidget,
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: (isDark ? Colors.white : Colors.black).withAlpha(120),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMockScheme(BuildContext context, bool isSelected, bool isDark, ColorScheme colorScheme) {
    final primary = isSelected ? colorScheme.primary : (isDark ? Colors.white38 : Colors.black38);
    return Container(
      height: 85,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1014) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? colorScheme.primary.withAlpha(100) : Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'X', 'J', 'V'].map((d) => Text(
              d,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primary),
            )).toList(),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(height: 16, margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: colorScheme.primary.withAlpha(isSelected ? 180 : 80), borderRadius: BorderRadius.circular(4))),
                      Container(height: 22, margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.amber.withAlpha(isSelected ? 180 : 80), borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(height: 26, margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(isSelected ? 180 : 80), borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(height: 20, margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.purple.withAlpha(isSelected ? 180 : 80), borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListMockScheme(BuildContext context, bool isSelected, bool isDark, ColorScheme colorScheme) {
    final primary = isSelected ? colorScheme.primary : (isDark ? Colors.white38 : Colors.black38);
    return Container(
      height: 85,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1014) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? colorScheme.primary.withAlpha(100) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primary.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'LUNES',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 3, height: 20, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 50, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white70 : Colors.black87, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 2),
                      Container(width: 30, height: 3, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 3, height: 20, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white70 : Colors.black87, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 2),
                      Container(width: 25, height: 3, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15)),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withAlpha(100),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        );
      }
    );
  }

  Widget _buildModeSelector(BuildContext context, AppLocalizations l10n, DataService dataService) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: dataService.appThemeMode,
      builder: (context, selectedMode, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  context,
                  title: l10n.system,
                  isSelected: selectedMode == ThemeMode.system,
                  icon: Icons.settings_brightness_rounded,
                  onTap: () => dataService.appThemeMode.value = ThemeMode.system,
                ),
              ),
              Expanded(
                child: _buildModeButton(
                  context,
                  title: l10n.darkMode,
                  isSelected: selectedMode == ThemeMode.dark,
                  icon: Icons.dark_mode_rounded,
                  onTap: () => dataService.appThemeMode.value = ThemeMode.dark,
                ),
              ),
              Expanded(
                child: _buildModeButton(
                  context,
                  title: l10n.lightMode,
                  isSelected: selectedMode == ThemeMode.light,
                  icon: Icons.light_mode_rounded,
                  onTap: () => dataService.appThemeMode.value = ThemeMode.light,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton(BuildContext context, {
    required String title,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : (theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterial3Option(BuildContext context, AppLocalizations l10n, DataService dataService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canUseDynamic = dataService.isAndroid12OrHigher;

    return ValueListenableBuilder<bool>(
      valueListenable: dataService.useDynamicColor,
      builder: (context, isDynamic, child) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDynamic ? Theme.of(context).colorScheme.primary.withAlpha(25) : Colors.grey.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDynamic ? Icons.auto_awesome_rounded : Icons.android_rounded, 
              color: isDynamic ? Theme.of(context).colorScheme.primary : Colors.grey
            ),
          ),
          title: Text(
            l10n.material3Aesthetic,
            style: TextStyle(
              color: canUseDynamic ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            canUseDynamic ? l10n.material3Desc : l10n.material3Error,
            style: TextStyle(color: (isDark ? Colors.white : Colors.black).withAlpha(100), fontSize: 12),
          ),
          trailing: Switch(
            value: canUseDynamic && isDynamic,
            onChanged: canUseDynamic ? (value) {
              dataService.useDynamicColor.value = value;
              if (value) {
                dataService.useMulticolor.value = false;
              }
            } : null,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildAccentColorSelector(BuildContext context, DataService dataService) {
    return ValueListenableBuilder2<Color, bool>(
      first: dataService.appAccentColor,
      second: dataService.useMulticolor,
      builder: (context, selectedColor, isMulticolor, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isDynamic = dataService.useDynamicColor.value;

        return SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: appAccentColors.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelectedMulticolor = isMulticolor && !isDynamic;
                return GestureDetector(
                  onTap: () {
                    dataService.useDynamicColor.value = false;
                    dataService.useMulticolor.value = true;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelectedMulticolor ? (isDark ? Colors.white : Colors.black) : Colors.transparent, width: 3),
                    ),
                    child: isSelectedMulticolor ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }
              final color = appAccentColors[index - 1];
              final isSelected = !isMulticolor && !isDynamic && selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () {
                  dataService.useDynamicColor.value = false;
                  dataService.useMulticolor.value = false;
                  dataService.appAccentColor.value = color;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent, width: 3)),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
