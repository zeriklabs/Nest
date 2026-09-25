import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/subject.dart';
import '../widgets/value_listenable_builders.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'schedule_manager_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final List<String> hours = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
  late ScrollController _vScrollController;
  late ScrollController _hScrollController;
  late ScrollController _vScrollSyncController;
  late ScrollController _timelineScrollController;
  final Map<int, GlobalKey> _dayKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
    5: GlobalKey(),
    6: GlobalKey(),
  };
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _vScrollController = ScrollController(keepScrollOffset: false);
    _vScrollSyncController = ScrollController(keepScrollOffset: false);
    _hScrollController = ScrollController(keepScrollOffset: false);
    _timelineScrollController = ScrollController();
    
    _vScrollController.addListener(() {
      if (_vScrollSyncController.hasClients) {
        _vScrollSyncController.jumpTo(_vScrollController.offset);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime(animated: false);
    });
  }

  void _scrollToCurrentTime({bool animated = false}) {
    if (!mounted) return;
    
    final ds = Provider.of<DataService>(context, listen: false);
    if (ds.lockScheduleAutoScroll) return;

    if (ds.scheduleStyle.value == ScheduleStyle.timeline) {
      _scrollToTodayTimeline(animated: animated);
      return;
    }

    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;
    final bool isLandscape = size.width > size.height;
    final double columnWidth = isTablet ? (isLandscape ? 240.0 : 200.0) : 130.0;
    final double hourHeight = isTablet ? 120.0 : 100.0;

    final now = DateTime.now();
    final currentHourDouble = now.hour + now.minute / 60.0;
    final targetVerticalOffset = (currentHourDouble > 0.5 ? currentHourDouble - 0.5 : 0) * hourHeight;
    
    if (_vScrollController.hasClients) {
      if (animated) {
        _vScrollController.animateTo(targetVerticalOffset, duration: const Duration(milliseconds: 800), curve: Curves.fastOutSlowIn);
      } else {
        _vScrollController.jumpTo(targetVerticalOffset);
      }
    }
    
    if (_hScrollController.hasClients) {
      final targetHorizontalOffset = (now.weekday - 1) * columnWidth;
      if (animated) {
        _hScrollController.animateTo(targetHorizontalOffset, duration: const Duration(milliseconds: 800), curve: Curves.fastOutSlowIn);
      } else {
        _hScrollController.jumpTo(targetHorizontalOffset);
      }
    }
  }

  void _scrollToTodayTimeline({bool animated = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final todayIndex = DateTime.now().weekday - 1;
      final key = _dayKeys[todayIndex];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: animated ? const Duration(milliseconds: 600) : Duration.zero,
          curve: Curves.fastOutSlowIn,
          alignment: 0.05,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vScrollController.dispose();
    _hScrollController.dispose();
    _vScrollSyncController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;
    final bool isLandscape = size.width > size.height;

    // Escuchar cambios de pestaña para re-posicionar si volvemos a esta pantalla
    return Consumer<DataService>(
      builder: (context, ds, child) {
        if (ds.mainTabIndex == 4 && !ds.lockScheduleAutoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentTime(animated: true);
          });
        }
        
        final isSimplified = ds.homeLayout.value == HomeLayout.simplified;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ds, isDark, colorScheme, isTablet),
                SizedBox(height: isTablet ? 6 : 4),
                Expanded(
                  child: ds.scheduleStyle.value == ScheduleStyle.timeline
                      ? _buildTimelineView(ds, isDark, colorScheme, isTablet)
                      : _buildTimetableGrid(isDark, colorScheme, isTablet, isLandscape),
                ),
                if (!isTablet && !isSimplified) _buildAddButton(context, isDark, colorScheme),
              ],
            ),
          ),
          floatingActionButton: isTablet ? Padding(
            padding: const EdgeInsets.only(bottom: 20, right: 20),
            child: FloatingActionButton.extended(
              heroTag: 'schedule_fab',
              onPressed: () => _openEditor(context, null),
              backgroundColor: colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.addSubjectBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ) : null,
        );
      }
    );
  }

  Widget _buildHeader(BuildContext context, DataService dataService, bool isDark, ColorScheme colorScheme, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final isSimplified = dataService.homeLayout.value == HomeLayout.simplified;

    return Padding(
      padding: EdgeInsets.fromLTRB(isSimplified ? 20 : 20, isTablet ? 12 : 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 0),
              Text(
                l10n.weeklySchedule,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: isTablet ? 24 : 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  dataService.scheduleStyle.value == ScheduleStyle.timeline
                      ? Icons.grid_on_rounded
                      : Icons.view_headline_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 22,
                ),
                tooltip: dataService.scheduleStyle.value == ScheduleStyle.timeline
                    ? 'Ver en cuadrícula'
                    : 'Ver en lista',
                onPressed: () {
                  dataService.scheduleStyle.value =
                      dataService.scheduleStyle.value == ScheduleStyle.grid
                          ? ScheduleStyle.timeline
                          : ScheduleStyle.grid;
                },
              ),
              if (Provider.of<DataService>(context).connectivityStatus == ConnectivityStatus.syncing)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              _buildHeaderMenu(context, isDark, l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMenu(BuildContext context, bool isDark, AppLocalizations l10n) {
    final ds = Provider.of<DataService>(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, 
        color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4), size: 24),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      onSelected: (val) {
        switch (val) {
          case 'manage':
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleManagerScreen()));
            break;
          case 'change_style':
            ds.scheduleStyle.value = ds.scheduleStyle.value == ScheduleStyle.grid 
                ? ScheduleStyle.timeline 
                : ScheduleStyle.grid;
            break;
          case 'toggle_scroll':
            ds.lockScheduleAutoScroll = !ds.lockScheduleAutoScroll;
            break;
          case 'import':
            _showImportDialog(context, isDark, l10n);
            break;
          case 'export':
            _showExportDialog(context, isDark, l10n);
            break;
          case 'delete':
            _showDeleteAllScheduleDialog(context, isDark, l10n);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'manage',
          child: Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(l10n.scheduleManagement, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'change_style',
          child: Row(
            children: [
              Icon(ds.scheduleStyle.value == ScheduleStyle.grid ? Icons.view_day_rounded : Icons.grid_on_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(l10n.changeView, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (ds.scheduleStyle.value == ScheduleStyle.grid)
          PopupMenuItem(
            value: 'toggle_scroll',
            child: Row(
              children: [
                Icon(ds.lockScheduleAutoScroll ? Icons.lock_open_rounded : Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Text(ds.lockScheduleAutoScroll ? l10n.unlockScheduleAutoScroll : l10n.lockScheduleAutoScroll, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(l10n.importSchedule, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.ios_share_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(l10n.exportAndShare, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 12),
              Text(l10n.deleteSchedule, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimetableGrid(bool isDark, ColorScheme colorScheme, bool isTablet, bool isLandscape) {
    final theme = Theme.of(context);
    final double columnWidth = isTablet ? (isLandscape ? 240.0 : 200.0) : 130.0;
    final double hourHeight = isTablet ? 120.0 : 100.0;
    final double hourColWidth = isTablet ? 90.0 : 70.0;

    return Consumer<DataService>(
      builder: (context, dataService, _) {
        final l10n = AppLocalizations.of(context)!;
        final subjects = dataService.subjects;
        final List<String> translatedDays = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];

        return ValueListenableBuilder2<bool, bool>(
          first: dataService.useMulticolor,
          second: dataService.useDynamicColor,
          builder: (context, isMulticolor, isDynamic, _) {
            if (subjects.isEmpty) {
              return _buildEmptySchedule(theme, l10n, isDark);
            }

            final activePrimary = theme.colorScheme.primary;

            return Stack(
              children: [
                // Contenido principal desplazable
                SingleChildScrollView(
                  controller: _hScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: hourColWidth + (columnWidth * days.length),
                    child: Column(
                      children: [
                        // Cabecera de días
                        Container(
                          height: isTablet ? 44 : 38,
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            border: Border(
                              bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: hourColWidth),
                              ...List.generate(days.length, (index) {
                                final dayName = days[index];
                                final translatedDay = translatedDays[index];
                                final isToday = dayName.toLowerCase() == _getTodayName().toLowerCase();
                                return SizedBox(
                                  width: columnWidth,
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 10, vertical: isTablet ? 4 : 2),
                                      decoration: isToday ? BoxDecoration(
                                        color: activePrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                      ) : null,
                                      child: Text(
                                        translatedDay,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isToday
                                            ? activePrimary
                                            : (isDark ? Colors.white38 : Colors.black45),
                                          fontSize: isTablet ? 14 : 13,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        // Cuerpo de la cuadrícula
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _vScrollController,
                            physics: const ClampingScrollPhysics(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: hourColWidth), // Espacio para la columna de horas fija

                                // Cuadrícula de clases
                                SizedBox(
                                  width: columnWidth * days.length,
                                  height: hours.length * hourHeight,
                                  child: Stack(
                                    children: [
                                      // Resaltado del día actual
                                      Builder(
                                        builder: (context) {
                                          final todayIdx = days.indexWhere((d) => d.toLowerCase() == _getTodayName().toLowerCase());
                                          if (todayIdx == -1) return const SizedBox();
                                          return Positioned(
                                            left: todayIdx * columnWidth,
                                            top: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: columnWidth,
                                              color: activePrimary.withOpacity(isDark ? 0.12 : 0.08),
                                            ),
                                          );
                                        }
                                      ),
                                      // Líneas de fondo
                                      for (int i = 0; i < hours.length; i++)
                                        Positioned(
                                          top: i * hourHeight,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 1,
                                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                          ),
                                        ),
                                      for (int i = 0; i < days.length; i++)
                                        Positioned(
                                          left: i * columnWidth,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 1,
                                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                          ),
                                        ),

                                      // Materias
                                      ...subjects.expand((subject) {
                                        return subject.schedules.map((schedule) {
                                          int dayIdx = days.indexWhere((d) => d.toLowerCase() == schedule.day.toLowerCase());
                                          if (dayIdx == -1) return const SizedBox();

                                          final isToday = schedule.day.toLowerCase() == _getTodayName().toLowerCase();
                                          final override = isToday ? dataService.getOverride(subject.id, DateTime.now(), schedule.startTime) : null;

                                          double hourOffset = (schedule.startHourDouble + (override?.offsetHours ?? 0));
                                          if (hourOffset.isNaN || hourOffset.isInfinite) hourOffset = 0.0;

                                          return _buildScheduleItem(
                                            context,
                                            subject,
                                            dayIdx,
                                            hourOffset,
                                            subject.name,
                                            subject.color,
                                            duration: schedule.durationHours,
                                            isDiscarded: override?.isDiscarded ?? false,
                                            isDark: isDark,
                                            sessionRoom: schedule.room,
                                            columnWidth: columnWidth,
                                            hourHeight: hourHeight,
                                          );
                                        });
                                      }),
                                      _buildTimeIndicator(activePrimary, isDark, hourHeight: hourHeight),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Columna de Horas FIJA (Solo se desplaza verticalmente)
                Positioned(
                  left: 0,
                  top: isTablet ? 44 : 38, // Empieza debajo del header de los días
                  bottom: 0,
                  child: Container(
                    width: hourColWidth,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(5, 0),
                        ),
                      ],
                      border: Border(
                        right: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _vScrollSyncController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Stack(
                        children: [
                          Column(
                            children: hours.map((hour) => Container(
                              height: hourHeight,
                              width: hourColWidth,
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                hour,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 11,
                                  color: isDark ? Colors.white38 : Colors.black45,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )).toList(),
                          ),
                          _buildTimeIndicator(activePrimary, isDark, isForHoursColumn: true, hourHeight: hourHeight),
                        ],
                      ),
                    ),
                  ),
                ),

                // Esquina superior izquierda FIJA (Une el header con la columna de horas sin sombra)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: hourColWidth,
                    height: isTablet ? 44 : 38,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border(
                        right: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
                        bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.access_time_rounded,
                        size: isTablet ? 20 : 16,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySchedule(ThemeData theme, AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noSubjectsYet,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noClassesProgrammed,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getTodayName() {
    const dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dayNames[DateTime.now().weekday - 1];
  }

  Widget _buildTimeIndicator(Color primaryColor, bool isDark, {bool isForHoursColumn = false, double hourHeight = 100.0}) {
    final currentHourDouble = _now.hour + _now.minute / 60.0;
    final top = currentHourDouble * hourHeight;
    const double lineHeight = 2.0;
    const double dotHeight = 12.0;
    
    if (isForHoursColumn) {
      return Positioned(
        top: top - (dotHeight / 2),
        right: 0,
        child: Container(
          width: 6,
          height: dotHeight,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
          ),
        ),
      );
    }

    return Positioned(
      top: top - (lineHeight / 2),
      left: 0,
      right: 0,
      child: Container(
        height: lineHeight,
        color: primaryColor.withOpacity(0.4),
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, Subject subject, int dayIndex, double hourOffset, String title, Color color, {double duration = 1.0, bool isDiscarded = false, required bool isDark, String? sessionRoom, double columnWidth = 130.0, double hourHeight = 100.0}) {
    final String displayRoomName = sessionRoom ?? 'S/N';
    final bool isTablet = MediaQuery.of(context).size.width > 720;
    
    return Positioned(
      top: hourOffset * hourHeight + 4,
      left: dayIndex * columnWidth + 4,
      child: Opacity(
        opacity: isDiscarded ? 0.3 : 1.0,
        child: GestureDetector(
          onTap: () => _openEditor(context, subject),
          child: Container(
            width: columnWidth - 8,
            height: (duration * hourHeight) - 8,
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: [
                if (!isDiscarded)
                  BoxShadow(
                    color: color.withOpacity(isDark ? 0.05 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: (duration * hourHeight) < 60 ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: isTablet ? 15 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((duration * hourHeight) > 60 && (displayRoomName != 'S/N' || subject.building != null)) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${displayRoomName != 'S/N' ? displayRoomName : ''}${displayRoomName != 'S/N' && subject.building != null ? ', ' : ''}${subject.building ?? ''}',
                      style: TextStyle(
                        color: isDark ? color.withOpacity(0.8) : color.withOpacity(0.9),
                        fontSize: isTablet ? 11 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 5),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openEditor(context, null),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    l10n.addSubjectBtn,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, bool isDark, AppLocalizations l10n) {
    final ds = Provider.of<DataService>(context, listen: false);
    final String jsonString = jsonEncode(ds.subjects.map((s) => s.toJson()).toList());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.exportSchedule, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.exportScheduleDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final tempDir = await getTemporaryDirectory();
                        final file = File('${tempDir.path}/horario_nest.json');
                        await file.writeAsString(jsonString);
                        
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: l10n.shareFileDesc,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.localeName == 'es' ? 'Error al compartir el archivo' : 'Error sharing file')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: Text(l10n.shareFile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final String? outputPath = await FilePicker.platform.saveFile(
                            dialogTitle: l10n.exportSchedule,
                            fileName: 'horario_nest.json',
                            type: FileType.custom,
                            allowedExtensions: ['json'],
                            bytes: utf8.encode(jsonString),
                          );
                          
                          if (outputPath != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.fileSavedSuccess)),
                            );
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.save_alt_rounded, size: 20),
                        label: Text(l10n.saveLabel),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancelLabel),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, bool isDark, AppLocalizations l10n) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.importSchedule, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null) {
                    Navigator.pop(context);
                    _importFromFile(result.files.single.path!, l10n);
                  }
                },
                icon: const Icon(Icons.file_open_rounded),
                label: Text(l10n.selectJsonFile),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(l10n.orPasteCode, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  hintText: '[{"id": "1", ...}]',
                  hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final List<dynamic> jsonList = jsonDecode(controller.text);
                final subjects = jsonList.map((j) => Subject.fromJson(j as Map<String, dynamic>)).toList();
                Provider.of<DataService>(context, listen: false).importSubjects(subjects);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.importSuccess)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.importError)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.importLabel),
          ),
        ],
      ),
    );
  }

  void _importFromFile(String path, AppLocalizations l10n) async {
    try {
      final file = File(path);
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final subjects = jsonList.map((j) => Subject.fromJson(j as Map<String, dynamic>)).toList();
      
      if (mounted) {
        Provider.of<DataService>(context, listen: false).importSubjects(subjects);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFileSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFileError)),
        );
      }
    }
  }

  void _openEditor(BuildContext context, Subject? subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectEditorSheet(subject: subject),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildTimelineView(DataService dataService, bool isDark, ColorScheme colorScheme, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> translatedDays = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];

    // Group subjects by day
    final Map<int, List<ClassInstance>> groupedClasses = {};
    for (int i = 0; i < 7; i++) {
      // Get classes for a specific day of the week (1-7)
      final DateTime dateForWeekday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 - i));
      groupedClasses[i] = dataService.getClassesForDate(
        dateForWeekday,
        includeDiscarded: true,
      )..sort((a, b) => a.startHour.compareTo(b.startHour));
    }

    final hasAnyClasses = groupedClasses.values.any((list) => list.isNotEmpty);

    if (!hasAnyClasses) {
      return _buildEmptySchedule(Theme.of(context), l10n, isDark);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!dataService.lockScheduleAutoScroll) {
        _scrollToTodayTimeline(animated: false);
      }
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          key: const PageStorageKey('timeline_schedule_list'),
          controller: _timelineScrollController,
          cacheExtent: 5000,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          itemCount: 7,
          itemBuilder: (context, index) {
            final classes = groupedClasses[index]!;
            if (classes.isEmpty) return const SizedBox.shrink();

            final bool isToday = (index + 1) == DateTime.now().weekday;

            return Column(
              key: _dayKeys[index],
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 24, bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        translatedDays[index].toUpperCase(),
                        style: TextStyle(
                          color: isToday ? colorScheme.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                ),
                ...classes.map((c) => _buildTimelineItem(context, c, isDark, colorScheme)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, ClassInstance item, bool isDark, ColorScheme colorScheme) {
    final color = item.subject.color;
    final timeRange = item.formattedTime.split(' - ');
    final startTime = timeRange[0];
    final endTime = timeRange.length > 1 ? timeRange[1] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () => _openEditor(context, item.subject),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startTime,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1.5,
                height: 35,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.subject.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.schedule.room ?? 'Aula S/N',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAllScheduleDialog(BuildContext context, bool isDark, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.deleteAllScheduleConfirm, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Text(
          l10n.deleteAllScheduleDesc,
          style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<DataService>(context, listen: false).clearAllSubjects();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.localeName == 'es' ? 'Horario eliminado' : 'Schedule deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class SubjectEditorSheet extends StatefulWidget {
  final Subject? subject;
  const SubjectEditorSheet({super.key, this.subject});

  @override
  State<SubjectEditorSheet> createState() => _SubjectEditorSheetState();
}

class _SubjectEditorSheetState extends State<SubjectEditorSheet> {
  final List<Map<String, dynamic>> _schedules = [];
  late Color _selectedColor;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.subject?.color ?? const Color(0xFF6366F1);
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _teacherController.text = widget.subject!.teacher ?? '';
      _buildingController.text = widget.subject!.building ?? '';
      _groupController.text = widget.subject!.group ?? '';
      for (var s in widget.subject!.schedules) {
        _schedules.add({
          'id': s.id,
          'day': s.day,
          'start': s.startTime,
          'end': s.endTime,
          'room': s.room ?? '',
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.subject == null && _selectedColor == const Color(0xFF6366F1)) {
      _selectedColor = Theme.of(context).colorScheme.primary;
    }
  }

  void _addSchedule() {
    setState(() {
      _schedules.add({
        'id': Uuid().v4(),
        'day': 'Lunes',
        'start': const TimeOfDay(hour: 8, minute: 0),
        'end': const TimeOfDay(hour: 9, minute: 0),
        'room': '',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final bool isTablet = size.width > 720;
    final double contentWidth = isTablet ? 600 : size.width;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.subject != null ? l10n.editSubject : l10n.newSubject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(l10n.generalInfo, isDark),
                      _buildInput(_nameController, l10n.subjectNameHint, Icons.book_outlined, isDark),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildInput(_buildingController, l10n.buildingLabel, Icons.apartment_rounded, isDark)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildInput(_groupController, l10n.groupNoun, Icons.groups_outlined, isDark)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildInput(_teacherController, l10n.teacherLabel, Icons.person_outline_rounded, isDark),
                      const SizedBox(height: 30),
                      _buildLabel(l10n.distinctiveColor, isDark),
                      _buildColorPicker(isDark, l10n),
                      const SizedBox(height: 30),
                      _buildLabel(l10n.schedulesLabel, isDark),
                      ..._schedules.asMap().entries.map((e) => _buildScheduleSlot(e.key, e.value, isDark, l10n)),
                      const SizedBox(height: 10),
                      _buildAddScheduleBtn(isDark, l10n),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(context, isDark, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
          prefixIcon: Icon(icon, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildColorPicker(bool isDark, AppLocalizations l10n) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final colors = [
      primaryColor, const Color(0xFFEC4899), const Color(0xFF10B981),
      const Color(0xFFF59E0B), const Color(0xFF3B82F6), const Color(0xFF8B5CF6),
      const Color(0xFFEF4444), const Color(0xFF06B6D4),
    ];
    
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 1,
        itemBuilder: (context, index) {
          if (index == colors.length) {
            return GestureDetector(
              onTap: () => _showFullColorPicker(isDark, l10n),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 45,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                ),
                child: Icon(Icons.add_rounded, color: isDark ? Colors.white70 : Colors.black54),
              ),
            );
          }

          final color = colors[index];
          final isSelected = _selectedColor.value == color.value;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 45,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) : null,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          );
        },
      ),
    );
  }

  void _showFullColorPicker(bool isDark, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setInternalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.colorize_rounded, color: _selectedColor, size: 24),
                  const SizedBox(width: 12),
                  Text(l10n.colorSelector, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 32),
              // El selector estilo Pro (HSV)
              ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) {
                  setInternalState(() => _selectedColor = color);
                  setState(() {}); // Actualiza el editor principal
                },
                colorPickerWidth: 300,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hsvWithHue,
                labelTypes: const [], // Quita las etiquetas de texto para que sea más limpio
                pickerAreaBorderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l10n.confirmColor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSlot(int index, Map<String, dynamic> schedule, bool isDark, AppLocalizations l10n) {
    final List<String> weekDays = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    final List<String> fullDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_day_rounded, size: 18, color: _selectedColor),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: schedule['day'],
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
                  items: fullDays.map((d) => 
                    DropdownMenuItem(value: d, child: Text(l10n.localeName == 'es' ? d : _translateDay(d), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold)))
                  ).toList(),
                  onChanged: (v) => setState(() => _schedules[index]['day'] = v),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _schedules.removeAt(index)),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _buildTimeBtn(index, true, isDark),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey)),
              _buildTimeBtn(index, false, isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) => schedule['room'] = v,
                    controller: TextEditingController(text: schedule['room'])..selection = TextSelection.fromPosition(TextPosition(offset: (schedule['room'] as String).length)),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: l10n.roomLabel,
                      hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateDay(String day) {
    switch (day) {
      case 'Lunes': return 'Monday';
      case 'Martes': return 'Tuesday';
      case 'Miércoles': return 'Wednesday';
      case 'Jueves': return 'Thursday';
      case 'Viernes': return 'Friday';
      case 'Sábado': return 'Saturday';
      case 'Domingo': return 'Sunday';
      default: return day;
    }
  }

  Widget _buildTimeBtn(int index, bool isStart, bool isDark) {
    final time = isStart ? _schedules[index]['start'] as TimeOfDay : _schedules[index]['end'] as TimeOfDay;
    return Expanded(
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: time);
          if (picked != null) setState(() => _schedules[index][isStart ? 'start' : 'end'] = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(time.format(context), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAddScheduleBtn(bool isDark, AppLocalizations l10n) {
    return InkWell(
      onTap: _addSchedule,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _selectedColor.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: _selectedColor, size: 18),
            const SizedBox(width: 8),
            Text(l10n.addScheduleBtn, style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          if (widget.subject != null) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () {
                  _showDeleteConfirmDialog(context, l10n);
                },
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              ),
            ),
            const SizedBox(width: 15),
          ],
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_nameController.text.isNotEmpty && _schedules.isNotEmpty) {
                  final subject = Subject(
                    id: widget.subject?.id ?? DateTime.now().toString(),
                    name: _nameController.text,
                    group: _groupController.text.isEmpty ? null : _groupController.text,
                    teacher: _teacherController.text.isEmpty ? null : _teacherController.text,
                    building: _buildingController.text.isEmpty ? null : _buildingController.text,
                    color: _selectedColor,
                    schedules: _schedules.map((s) => SubjectSchedule(
                      id: s['id'] ?? Uuid().v4(),
                      day: s['day'],
                      startTime: s['start'],
                      endTime: s['end'],
                      room: s['room']?.toString().isEmpty == true ? null : s['room']?.toString(),
                    )).toList(),
                  );
                  final ds = Provider.of<DataService>(context, listen: false);
                  widget.subject != null ? ds.updateSubject(subject) : ds.addSubject(subject);
                  Navigator.pop(context);
                }
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.subject != null ? l10n.updateLabel : l10n.saveSubjectBtn,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSubjectConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancelLabel)),
          TextButton(
            onPressed: () {
              Provider.of<DataService>(context, listen: false).deleteSubject(widget.subject!.id);
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Sheet
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
