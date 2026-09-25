import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/subject.dart';
import 'schedule_screen.dart';
import 'package:intl/intl.dart';

class ScheduleManagerScreen extends StatefulWidget {
  const ScheduleManagerScreen({super.key});

  @override
  State<ScheduleManagerScreen> createState() => _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState extends State<ScheduleManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context);

    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;
    final bool isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      appBar: AppBar(
        title: Text(l10n.scheduleManagement),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
              child: TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l10n.localeName == 'es' ? 'Materias' : 'Subjects'),
                  Tab(text: l10n.localeName == 'es' ? 'Planificador' : 'Planner'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isTablet && isLandscape ? 1200 : 900),
          child: Column(
            children: [
              _buildGlobalActionsRow(context, dataService, isDark, colorScheme, l10n, isTablet),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSubjectsTab(dataService, isDark, colorScheme, l10n, isTablet, isLandscape),
                    _buildPlannerTab(dataService, isDark, colorScheme, l10n, isTablet, isLandscape),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubjectEditorSheet(subject: null),
              fullscreenDialog: true,
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(l10n.newSubject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildSubjectsTab(DataService dataService, bool isDark, ColorScheme colorScheme, AppLocalizations l10n, bool isTablet, bool isLandscape) {
    final subjects = dataService.subjects;

    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_calendar_rounded, size: 64, color: colorScheme.primary.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(l10n.noSubjectsYet, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4))),
          ],
        ),
      );
    }

    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLandscape ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 100,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) => _buildSubjectCard(subjects[index], isDark, colorScheme, l10n),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: subjects.length,
      itemBuilder: (context, index) => _buildSubjectCard(subjects[index], isDark, colorScheme, l10n),
    );
  }

  Widget _buildSubjectCard(Subject subject, bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: subject.color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: subject.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.book_rounded, color: subject.color, size: 20),
        ),
        title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${subject.schedules.length} ${l10n.localeName == 'es' ? 'sesiones' : 'sessions'}', 
          style: TextStyle(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4))
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.primary.withOpacity(0.3)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectEditorSheet(subject: subject),
              fullscreenDialog: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlannerTab(DataService dataService, bool isDark, ColorScheme colorScheme, AppLocalizations l10n, bool isTablet, bool isLandscape) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<dynamic> plannerItems = [];
    final currentHour = now.hour + now.minute / 60.0;

    for (int i = 0; i < 14; i++) {
      final date = today.add(Duration(days: i));
      var classes = dataService.getClassesForDate(date, includeDiscarded: true);

      if (i == 0) {
        classes = classes.where((c) => c.endHour > currentHour).toList();
      }

      if (classes.isNotEmpty) {
        plannerItems.add(date); // Header
        plannerItems.addAll(classes);
      }
    }

    if (plannerItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, size: 64, color: colorScheme.primary.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              l10n.noClassesProgrammed, 
              style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3))
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      // On tablet, we can show days in a grid if we want, but a single column list is also fine if constrained.
      // However, let's try a 2-column layout for sessions if in landscape.
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: plannerItems.length,
        itemBuilder: (context, index) {
          final item = plannerItems[index];
          if (item is DateTime) {
            return _buildDateHeader(item, colorScheme, isDark, l10n);
          } else if (item is ClassInstance) {
            // For tablet session cards, we can make them wider or show more info.
            return _buildClassSessionCard(item, dataService, isDark, colorScheme, l10n, isTablet: true);
          }
          return const SizedBox.shrink();
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: plannerItems.length,
      itemBuilder: (context, index) {
        final item = plannerItems[index];
        if (item is DateTime) {
          return _buildDateHeader(item, colorScheme, isDark, l10n);
        } else if (item is ClassInstance) {
          return _buildClassSessionCard(item, dataService, isDark, colorScheme, l10n);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGlobalActionsRow(BuildContext context, DataService dataService, bool isDark, ColorScheme colorScheme, AppLocalizations l10n, bool isTablet) {
    final bool isCurrentlyPaused = dataService.hasFutureDiscarded();
    final now = DateTime.now();
    final todayClasses = dataService.getClassesForDate(now);
    final currentHour = now.hour + now.minute / 60.0;
    final bool hasNextClassToday = todayClasses.any((c) => c.startHour > currentHour + 0.05);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(isTablet ? 24 : 20, 15, isTablet ? 24 : 20, 10),
      child: Column(
        children: [
          if (hasNextClassToday) ...[
            _buildGlobalActionChip(
              l10n.advanceClass,
              Icons.fast_forward_rounded,
              colorScheme.primary,
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
              },
              isDark,
              isFullWidth: true,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _buildGlobalActionChip(
                  isCurrentlyPaused ? l10n.resumeSchedule : l10n.pauseSchedule,
                  isCurrentlyPaused ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                  isCurrentlyPaused ? Colors.green : Colors.orange,
                  () async {
                    if (isCurrentlyPaused) {
                      final now = DateTime.now();
                      final maxDate = now.add(const Duration(days: 365));
                      dataService.resumePeriod(now, maxDate);
                    } else {
                      final now = DateTime.now();
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: now.add(const Duration(days: 1)),
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
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
                      }
                    }
                  },
                  isDark
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlobalActionChip(
                  l10n.discardLabel,
                  Icons.block_flipped,
                  Colors.redAccent,
                  () => _showGlobalDiscardOptions(context, dataService, isDark, l10n),
                  isDark
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGlobalActionChip(
            'Aviso de clase: ${dataService.classRemindersEnabled ? (dataService.classReminderMinutesBefore == 0 ? "Al comenzar" : "${dataService.classReminderMinutesBefore} min antes") : "Desactivado"}',
            dataService.classRemindersEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            dataService.classRemindersEnabled ? colorScheme.primary : colorScheme.onSurface.withAlpha(120),
            () => _showClassReminderDialog(context, dataService, colorScheme, isDark),
            isDark,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  void _showClassReminderDialog(BuildContext context, DataService dataService, ColorScheme colorScheme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final enabled = dataService.classRemindersEnabled;
            final currentMinutes = dataService.classReminderMinutesBefore;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withAlpha(50),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.school_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Avisos de inicio de clase',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: enabled,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (val) {
                          dataService.setClassRemindersEnabled(val);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Te enviará una notificación antes de que empiece cada clase.',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withAlpha(140)),
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Anticipación del aviso:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [0, 5, 10, 15, 20, 30, 45, 60].map((minutes) {
                        final isSelected = currentMinutes == minutes;
                        final label = minutes == 0
                            ? 'Al comenzar'
                            : (minutes == 60 ? '1 hora antes' : '$minutes min antes');
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
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalActionChip(String label, IconData icon, Color color, VoidCallback onTap, bool isDark, {bool isFullWidth = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlobalDiscardOptions(BuildContext context, DataService dataService, bool isDark, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(l10n.discardLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            _buildActionTile(context, l10n.thisClass, Icons.block_flipped, Colors.redAccent, () {
              final now = DateTime.now();
              final classes = dataService.getClassesForDate(now);
              final currentHour = now.hour + now.minute / 60.0;
              try {
                final current = classes.firstWhere((c) => currentHour >= c.startHour && currentHour <= c.endHour);
                dataService.discardClassForDate(current.subject.id, now);
              } catch (_) {}
              Navigator.pop(context);
            }),
            const SizedBox(height: 10),
            _buildActionTile(context, l10n.todayLabel, Icons.calendar_today_rounded, Colors.redAccent, () {
              final now = DateTime.now();
              dataService.discardPeriod(now, now);
              Navigator.pop(context);
            }),
            const SizedBox(height: 10),
            _buildActionTile(context, l10n.tomorrowLabel, Icons.wb_sunny_outlined, Colors.redAccent, () {
              final tomorrow = DateTime.now().add(const Duration(days: 1));
              dataService.discardPeriod(tomorrow, tomorrow);
              Navigator.pop(context);
            }),
            const SizedBox(height: 10),
            _buildActionTile(context, l10n.weekLabel, Icons.date_range_rounded, Colors.redAccent, () {
              final now = DateTime.now();
              final endOfWeek = now.add(Duration(days: 7 - now.weekday));
              dataService.discardPeriod(now, endOfWeek);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showCustomTimeAndDurationDialog(BuildContext context, ClassInstance item, DataService dataService, AppLocalizations l10n) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              _buildSettingRow(
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
              _buildSettingRow(
                l10n.localeName == 'es' ? 'Duración' : 'Duration',
                '${selectedDuration.toStringAsFixed(1)} h',
                Icons.timer_outlined,
                () => _showDurationPicker(context, selectedDuration, (val) => setInternalState(() => selectedDuration = val), isDark),
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

  Widget _buildSettingRow(String label, String value, IconData icon, VoidCallback onTap, bool isDark) {
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

  void _showDurationPicker(BuildContext context, double current, Function(double) onSelected, bool isDark) {
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

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? l10n.today.toUpperCase() : DateFormat('EEEE, d MMMM', l10n.localeName).format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSessionCard(ClassInstance instance, DataService dataService, bool isDark, ColorScheme colorScheme, AppLocalizations l10n, {bool isTablet = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: instance.subject.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.class_rounded, color: instance.subject.color, size: 24),
            ),
            title: Text(
              instance.subject.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: instance.isDiscarded ? TextDecoration.lineThrough : null,
                color: instance.isDiscarded ? (isDark ? Colors.white30 : Colors.black26) : null,
              ),
            ),
            subtitle: Text(
              '${instance.formattedTime}${instance.schedule.room != null ? " | ${instance.schedule.room}" : ""}',
              style: TextStyle(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontWeight: FontWeight.w500),
            ),
            trailing: instance.isDiscarded 
              ? Icon(Icons.block_flipped, color: Colors.redAccent.withOpacity(0.6), size: 20)
              : (instance.offsetHours != 0 || instance.customDurationHours != null ? Icon(Icons.event_repeat_rounded, color: Colors.orange.withOpacity(0.6), size: 20) : null),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                _buildSessionAction(
                  instance.isDiscarded ? l10n.restoreSession : l10n.discardLabel,
                  instance.isDiscarded ? Icons.restore_rounded : Icons.delete_outline_rounded,
                  instance.isDiscarded ? Colors.green : Colors.redAccent,
                  () {
                    if (instance.isDiscarded) {
                      dataService.removeOverride(instance.subject.id, instance.date, instance.schedule.startTime);
                    } else {
                      dataService.addOverride(ScheduleOverride(
                        subjectId: instance.subject.id,
                        date: instance.date,
                        originalStartTime: instance.schedule.startTime,
                        isDiscarded: true,
                      ));
                    }
                  },
                  isDark
                ),
                const SizedBox(width: 12),
                if (!instance.isDiscarded)
                  _buildSessionAction(
                    l10n.reprogramClass,
                    Icons.event_repeat_rounded,
                    Colors.orange,
                    () => _showReprogramOptions(instance, dataService, isDark, l10n),
                    isDark
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionAction(String label, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReprogramOptions(ClassInstance item, DataService dataService, bool isDark, AppLocalizations l10n) {
    _showReprogramOptionsInternal(context, item, dataService, isDark, l10n);
  }

  void _showReprogramOptionsInternal(BuildContext context, ClassInstance item, DataService dataService, bool isDark, AppLocalizations l10n) {
    final duration = item.customDurationHours ?? item.schedule.durationHours;
    final recommendedSlots = dataService.getRecommendedSlots(item.date, duration);
    final range = dataService.getNormalClassRange();
    final colorScheme = Theme.of(context).colorScheme;

    final normalSlots = recommendedSlots.where((s) => s.startHour >= range['start']! && s.endHour <= range['end']!).toList();
    final extraSlots = recommendedSlots.where((s) => !normalSlots.contains(s)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(l10n.selectFreeSlot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('EEEE d', l10n.localeName).format(item.date)} | ${duration.toStringAsFixed(1)}h',
                style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (normalSlots.isNotEmpty) ...[
                      _buildSmallSubheader(l10n.localeName == 'es' ? 'HORARIO NORMAL' : 'NORMAL HOURS', context),
                      const SizedBox(height: 10),
                      ...normalSlots.map((slot) => _buildSlotTile(context, slot, item, dataService, colorScheme, isDark, true)),
                      const SizedBox(height: 20),
                    ],
                    if (extraSlots.isNotEmpty) ...[
                      _buildSmallSubheader(l10n.localeName == 'es' ? 'HORARIO EXTRACURRICULAR' : 'EXTRACURRICULAR HOURS', context),
                      const SizedBox(height: 10),
                      ...extraSlots.map((slot) => _buildSlotTile(context, slot, item, dataService, colorScheme, isDark, false)),
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
                              customDurationHours: item.customDurationHours,
                            );
                            _showReprogramOptionsInternal(context, newItem, dataService, isDark, l10n);
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
                        onPressed: () => _showCustomTimeAndDurationDialog(context, item, dataService, l10n),
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

  Widget _buildSlotTile(BuildContext context, TimeSlot slot, ClassInstance item, DataService dataService, ColorScheme colorScheme, bool isDark, bool isNormal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: (isNormal ? colorScheme.primary : Colors.orange).withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: (isNormal ? colorScheme.primary : Colors.orange).withOpacity(0.1)),
        ),
        leading: Icon(isNormal ? Icons.schedule_rounded : Icons.history_toggle_off_rounded, color: isNormal ? colorScheme.primary : Colors.orange),
        title: Text(slot.formattedRange, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
        onTap: () {
          final targetStart = slot.startHour;
          final originalStart = item.schedule.startHourDouble;
          final offset = targetStart - originalStart;
          final duration = slot.endHour - slot.startHour;

          dataService.addOverride(ScheduleOverride(
            subjectId: item.subject.id,
            date: item.date,
            originalStartTime: item.schedule.startTime,
            offsetHours: offset,
            customDurationHours: duration,
          ));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSmallSubheader(String text, BuildContext context) {
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

  String _formatHour(double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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
}
