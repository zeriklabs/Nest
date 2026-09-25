import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:device_calendar/device_calendar.dart' hide Reminder;
import 'package:nest/services/data_service.dart';
import 'package:nest/services/calendar_service.dart';
import 'package:nest/l10n/app_localizations.dart';

class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  Future<void> _showCalendarSelectorModal(BuildContext context, DataService dataService) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: FutureBuilder<List<Calendar>>(
            future: CalendarService().getAvailableCalendars(),
            builder: (futureContext, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              }

              final calendars = snapshot.data ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.selectCalendar,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige en qué calendario de tu dispositivo se sincronizarán tus eventos y recordatorios de Nest.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (calendars.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No se encontraron calendarios en el sistema o no se otorgaron permisos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: calendars.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cal = calendars[index];
                          final calName = cal.name ?? 'Sin nombre';
                          final account = cal.accountName ?? '';
                          final displayName = account.isNotEmpty ? '$calName ($account)' : calName;
                          final isSelected = dataService.selectedCalendarId == cal.id ||
                              (dataService.selectedCalendarId == null && (cal.isDefault ?? false));

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: isSelected ? Colors.white : colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              calName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: account.isNotEmpty
                                ? Text(account, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12))
                                : null,
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                                : null,
                            onTap: () {
                              if (cal.id != null) {
                                dataService.setSelectedCalendar(cal.id!, displayName);
                              }
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sincronizando con: $calName')),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context);
    final isSyncEnabled = !kIsWeb && dataService.calendarSyncEnabled;
    final selectedCalendarName = dataService.selectedCalendarName ?? l10n.defaultCalendar;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
          l10n.calendarSync,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                  children: [
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: (isSyncEnabled || kIsWeb) ? colorScheme.primary.withAlpha(30) : colorScheme.primary.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: Icon(
                          kIsWeb ? Icons.cloud_done_rounded : (isSyncEnabled ? Icons.sync_rounded : Icons.calendar_today_rounded),
                          key: ValueKey<String>(kIsWeb ? 'web' : isSyncEnabled.toString()),
                          size: isWide ? 80 : 70,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      kIsWeb ? 'Sincronización Web ➔ Móvil' : l10n.yourAgendaEverywhere,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: isWide ? 26 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(
                        kIsWeb 
                            ? 'Todo lo que crees o modifiques aquí se guarda en tu cuenta de Nest en tiempo real.'
                            : l10n.syncDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(160),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (kIsWeb)
                      _buildWebGuideView(context, colorScheme, isDark, isWide)
                    else ...[
                      // Tarjeta de Activación Maestro en Móvil
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSyncEnabled 
                              ? colorScheme.primary.withAlpha(120) 
                              : colorScheme.outlineVariant.withAlpha(51),
                            width: isSyncEnabled ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSyncEnabled ? colorScheme.primary : colorScheme.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.power_settings_new_rounded,
                                color: isSyncEnabled ? Colors.white : colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSyncEnabled ? l10n.activeSync : l10n.enableSync,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    isSyncEnabled ? l10n.alreadyConnected : l10n.unlockFunctions,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withAlpha(127),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isSyncEnabled,
                              activeColor: colorScheme.primary,
                              onChanged: (value) {
                                dataService.setCalendarSyncEnabled(value);
                                if (value) {
                                  Future.delayed(const Duration(milliseconds: 250), () {
                                    if (mounted) {
                                      _showCalendarSelectorModal(context, dataService);
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Tarjeta para Seleccionar el Calendario Específico del Sistema
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isSyncEnabled ? 1.0 : 0.5,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSyncEnabled ? colorScheme.primary.withAlpha(40) : colorScheme.outlineVariant.withAlpha(51), 
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: isSyncEnabled ? () => _showCalendarSelectorModal(context, dataService) : null,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Calendario de destino',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedCalendarName,
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),
                    _buildSectionTitle(context, (isSyncEnabled || kIsWeb) ? l10n.activeBenefits : l10n.whyActivate),
                    const SizedBox(height: 20),

                    if (isWide)
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildBenefitItem(
                                  context,
                                  icon: Icons.notifications_active_rounded,
                                  title: l10n.smartAlerts,
                                  description: l10n.smartAlertsDesc,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildBenefitItem(
                                  context,
                                  icon: Icons.calendar_month_rounded,
                                  title: l10n.noConflicts,
                                  description: l10n.noConflictsDesc,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildBenefitItem(
                                  context,
                                  icon: Icons.widgets_rounded,
                                  title: l10n.multiplatform,
                                  description: l10n.multiplatformDesc,
                                ),
                              ),
                              const SizedBox(width: 24),
                              const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildBenefitItem(
                            context,
                            icon: Icons.notifications_active_rounded,
                            title: l10n.smartAlerts,
                            description: l10n.smartAlertsDesc,
                          ),
                          const SizedBox(height: 20),
                          _buildBenefitItem(
                            context,
                            icon: Icons.calendar_month_rounded,
                            title: l10n.noConflicts,
                            description: l10n.noConflictsDesc,
                          ),
                          const SizedBox(height: 20),
                          _buildBenefitItem(
                            context,
                            icon: Icons.widgets_rounded,
                            title: l10n.multiplatform,
                            description: l10n.multiplatformDesc,
                          ),
                        ],
                      ),
                    
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

  Widget _buildWebGuideView(BuildContext context, ColorScheme colorScheme, bool isDark, bool isWide) {
    final step1 = _buildStepItem(
      context,
      stepNumber: '1',
      icon: Icons.phone_android_rounded,
      title: 'Abre Nest en tu teléfono',
      description: 'Abre la app de Nest en tu teléfono Android o iPhone e inicia sesión.',
    );
    final step2 = _buildStepItem(
      context,
      stepNumber: '2',
      icon: Icons.settings_rounded,
      title: 'Ajustes ➔ Sincronización',
      description: 'Ingresa al menú de Ajustes y presiona en "Sincronización con calendario".',
    );
    final step3 = _buildStepItem(
      context,
      stepNumber: '3',
      icon: Icons.toggle_on_rounded,
      title: 'Activa y elige tu calendario',
      description: 'Activa el interruptor y selecciona tu calendario del sistema (Google, Apple, Samsung, etc.).',
    );
    final step4 = _buildStepItem(
      context,
      stepNumber: '4',
      icon: Icons.check_circle_rounded,
      title: '¡Listo!',
      description: 'Todo lo que crees o edites desde la Web aparecerá automáticamente en el calendario de tu teléfono.',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner de Sincronización en la Nube
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.primary.withAlpha(80), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.cloud_done_rounded, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sincronización Cloud Activa',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tus eventos, horario y recordatorios creados aquí en la Web se sincronizan en tiempo real con tu app móvil.',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(150),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        _buildSectionTitle(context, 'Pasos para activarlo en tu dispositivo móvil'),
        const SizedBox(height: 16),

        if (isWide)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: step1),
                  const SizedBox(width: 16),
                  Expanded(child: step2),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: step3),
                  const SizedBox(width: 16),
                  Expanded(child: step4),
                ],
              ),
            ],
          )
        else
          Column(
            children: [
              step1,
              const SizedBox(height: 12),
              step2,
              const SizedBox(height: 12),
              step3,
              const SizedBox(height: 12),
              step4,
            ],
          ),
      ],
    );
  }

  Widget _buildStepItem(BuildContext context, {
    required String stepNumber,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(50) : colorScheme.surfaceContainerLow.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(150),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {bool enabled = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: enabled ? colorScheme.primary : colorScheme.onSurface.withAlpha(64),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, {required IconData icon, required String title, required String description}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(153),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
