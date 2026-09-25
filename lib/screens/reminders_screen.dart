import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/reminder.dart';
import '../models/project.dart';
import 'add_reminder_screen.dart';
import 'reminder_details_screen.dart';
import 'project_details_screen.dart';
import 'recurring_reminders_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  DateTime selectedDate = DateTime.now();
  late DateTime currentMonth;
  late PageController _monthPageController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  static final DateTime _calendarAnchor = DateTime(2020, 1, 1);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentMonth = DateTime(now.year, now.month);
    final initialPage = _getIndexForMonth(currentMonth);
    _monthPageController = PageController(initialPage: initialPage);
  }

  DateTime _getMonthForIndex(int index) {
    final year = _calendarAnchor.year + (index ~/ 12);
    final month = (index % 12) + 1;
    return DateTime(year, month);
  }

  int _getIndexForMonth(DateTime date) {
    final yearDiff = date.year - _calendarAnchor.year;
    final monthDiff = date.month - _calendarAnchor.month;
    return yearDiff * 12 + monthDiff;
  }
  
  dynamic _selectedItem;

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  final List<String> categoryKeys = [
    'all',
    'urgent',
    'Recordatorio',
    'Tarea',
    'Examen',
    'Evento',
    'completed'
  ];

  String _getCategoryLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'all': return l10n.all;
      case 'urgent': return l10n.urgent;
      case 'pending': return "Sin completar";
      case 'overdue': return l10n.overdue;
      case 'Recordatorio': return l10n.reminder;
      case 'Tarea': return l10n.task;
      case 'Proyecto': return l10n.project;
      case 'Examen': return l10n.exam;
      case 'Evento': return l10n.event;
      case 'completed': return l10n.completed;
      default: return key;
    }
  }

  List<dynamic> get filteredReminders {
    final dataService = Provider.of<DataService>(context, listen: false);
    final reminders = dataService.reminders;
    final viewMode = dataService.reminderViewMode;
    final selectedCategory = dataService.reminderSelectedCategory;
    final selectedFilter = dataService.reminderSelectedFilter;
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final twoWeeksLimit = todayStart.add(const Duration(days: 14));

    List<dynamic> list = [];

    if (viewMode == ReminderViewMode.calendar) {
      list.addAll(reminders.where((r) => r.isHappeningOn(selectedDate)));
    } else {
      if (selectedCategory == 'completed') {
        list.addAll(reminders.where((r) => r.isCompleted));
        list.addAll(reminders.where((r) {
          if (r.isCompleted || r.category != 'Evento') return false;
          final eventEnd = r.endDate ?? r.dateTime;
          return eventEnd.isBefore(todayStart);
        }));
      } else {
        if (selectedCategory == 'all' || selectedCategory == 'urgent') {
          List<Reminder> pendingReminders = reminders.where((r) {
            if (r.isCompleted) return false;
            if (r.category == 'Evento') {
              final eventEnd = r.endDate ?? r.dateTime;
              return !eventEnd.isBefore(todayStart) && r.dateTime.isBefore(twoWeeksLimit);
            }
            if (selectedCategory == 'urgent') return r.isUrgent;
            return true;
          }).toList();
          list.addAll(pendingReminders);
        } else if (selectedCategory == 'Evento') {
          list.addAll(reminders.where((r) => !r.isCompleted && r.category == 'Evento' && !r.dateTime.isBefore(todayStart)));
        } else {
          list.addAll(reminders.where((r) => !r.isCompleted && r.category == selectedCategory));
        }
      }
    }

    if (selectedFilter == 'by_date') {
      list.sort((a, b) {
        final dtA = a is Reminder ? a.dateTime : (a as Project).endDate ?? a.startDate;
        final dtB = b is Reminder ? b.dateTime : (b as Project).endDate ?? b.startDate;
        return dtA.compareTo(dtB);
      });
    } else if (selectedFilter == 'alphabetical') {
      list.sort((a, b) {
        final titleA = a is Reminder ? a.title : (a as Project).title;
        final titleB = b is Reminder ? b.title : (b as Project).title;
        return titleA.toLowerCase().compareTo(titleB.toLowerCase());
      });
    } else {
      list.sort((a, b) {
        int priority(dynamic item) {
          if (item is Project) return 3;
          final cat = (item as Reminder).category;
          if (cat == 'Evento') return 1;
          if (cat == 'Examen') return 2;
          return 4;
        }
        int pA = priority(a);
        int pB = priority(b);
        if (pA != pB) return pA.compareTo(pB);
        final dtA = a is Reminder ? a.dateTime : (a as Project).endDate ?? a.startDate;
        final dtB = b is Reminder ? b.dateTime : (b as Project).endDate ?? b.startDate;
        return dtA.compareTo(dtB);
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context);
    final bool isSelectedTab = dataService.mainTabIndex == 1;
    
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;
    final bool isLandscape = size.width > size.height;

    final bool isSimplified = dataService.homeLayout.value == HomeLayout.simplified;

    if (isTablet) {
      return PopScope(
        canPop: !isSelectedTab || _selectedItem == null,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_selectedItem != null) {
            setState(() {
              _selectedItem = null;
            });
          }
        },
        child: _buildTabletLayout(context, dataService, colorScheme, isDark, l10n, isLandscape),
      );
    }

    return PopScope(
      canPop: !isSelectedTab || _selectedItem == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedItem != null) {
          setState(() {
            _selectedItem = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context, dataService, isDark, colorScheme, l10n),
              if (dataService.reminderViewMode == ReminderViewMode.list || dataService.reminderViewMode == ReminderViewMode.board) _buildCategoriesAndFilter(context, colorScheme, isDark, l10n, dataService),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentView(dataService.reminderViewMode, colorScheme, isDark, l10n),
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: (dataService.reminderViewMode == ReminderViewMode.calendar || isSimplified) ? null : Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton(
            heroTag: 'reminders_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddReminderScreen(initialDate: selectedDate)),
            ),
            backgroundColor: colorScheme.primary,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, DataService dataService, ColorScheme colorScheme, bool isDark, AppLocalizations l10n, bool isLandscape) {
    final viewMode = dataService.reminderViewMode;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, dataService, isDark, colorScheme, l10n),
            if (viewMode == ReminderViewMode.list || viewMode == ReminderViewMode.board) _buildCategoriesAndFilter(context, colorScheme, isDark, l10n, dataService),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: isLandscape ? 3 : 2,
                    child: _buildCurrentView(viewMode, colorScheme, isDark, l10n, isTablet: true, isLandscape: isLandscape),
                  ),
                  if (viewMode == ReminderViewMode.list) ...[
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      flex: isLandscape ? 2 : 3,
                      child: _selectedItem != null
                        ? (_selectedItem is Reminder 
                            ? ReminderDetailsScreen(
                                reminder: _selectedItem as Reminder,
                                onBack: () {
                                  setState(() {
                                    _selectedItem = null;
                                  });
                                },
                              )
                            : ProjectDetailsScreen(
                                projectId: (_selectedItem as Project).id,
                                onBack: () {
                                  setState(() {
                                    _selectedItem = null;
                                  });
                                },
                              ))
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 64, color: colorScheme.primary.withOpacity(0.1)),
                                const SizedBox(height: 16),
                                Text(
                                  "Selecciona un elemento para ver detalles",
                                  style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (viewMode == ReminderViewMode.calendar || dataService.homeLayout.value == HomeLayout.simplified) ? null : FloatingActionButton(
        heroTag: 'reminders_fab_tablet',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddReminderScreen(initialDate: selectedDate)),
        ),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCurrentView(ReminderViewMode mode, ColorScheme colorScheme, bool isDark, AppLocalizations l10n, {bool isTablet = false, bool isLandscape = false}) {
    switch (mode) {
      case ReminderViewMode.calendar:
        return _buildCalendarContent(colorScheme, isDark, l10n, isTablet: isTablet, isLandscape: isLandscape);
      case ReminderViewMode.board:
        return _buildTimelineContent(colorScheme, isDark, l10n);
      case ReminderViewMode.list:
      default:
        return _buildRemindersList(colorScheme, isDark, l10n, isTablet: isTablet);
    }
  }

  Widget _buildHeader(BuildContext context, DataService dataService, bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    final viewMode = dataService.reminderViewMode;
    final isSimplified = dataService.homeLayout.value == HomeLayout.simplified;
    
    String title = l10n.myReminders;
    if (viewMode == ReminderViewMode.calendar) title = l10n.calendar;
    if (viewMode == ReminderViewMode.board) title = l10n.board;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isSimplified)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => dataService.mainTabIndex = 0,
                  color: isDark ? Colors.white : Colors.black,
                  iconSize: 22,
                ),
              const SizedBox(width: 8),
              Text(
                title,
                key: ValueKey(viewMode),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    if (value == 'view_list') {
                      dataService.reminderViewMode = ReminderViewMode.list;
                    } else if (value == 'view_calendar') {
                      dataService.reminderViewMode = ReminderViewMode.calendar;
                    } else if (value == 'view_board') {
                      dataService.reminderViewMode = ReminderViewMode.board;
                    } else if (value == 'programs') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecurringRemindersScreen()),
                      );
                    }
                  });
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view_list',
                    child: Row(
                      children: [
                        Icon(Icons.format_list_bulleted_rounded, 
                          size: 20, color: viewMode == ReminderViewMode.list ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black87)),
                        const SizedBox(width: 12),
                        Text(l10n.viewAsList, style: TextStyle(color: viewMode == ReminderViewMode.list ? colorScheme.primary : null)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_calendar',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, 
                          size: 20, color: viewMode == ReminderViewMode.calendar ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black87)),
                        const SizedBox(width: 12),
                        Text(l10n.viewAsCalendar, style: TextStyle(color: viewMode == ReminderViewMode.calendar ? colorScheme.primary : null)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_board',
                    child: Row(
                      children: [
                        Icon(Icons.view_timeline_rounded, 
                          size: 20, color: viewMode == ReminderViewMode.board ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black87)),
                        const SizedBox(width: 12),
                        Text(l10n.viewAsBoard, style: TextStyle(color: viewMode == ReminderViewMode.board ? colorScheme.primary : null)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'programs',
                    child: Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                        const SizedBox(width: 12),
                        Text(l10n.programs),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesAndFilter(BuildContext context, ColorScheme colorScheme, bool isDark, AppLocalizations l10n, DataService dataService) {
    final isTimeline = dataService.reminderViewMode == ReminderViewMode.board;
    final keys = isTimeline
        ? const ['all', 'pending', 'completed']
        : categoryKeys;

    final selectedCategory = dataService.reminderSelectedCategory;
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 15, top: 10),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final categoryKey = keys[index];
                final categoryLabel = _getCategoryLabel(categoryKey, l10n);
                final isSelected = selectedCategory == categoryKey;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => dataService.reminderSelectedCategory = categoryKey,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? colorScheme.primary.withOpacity(0.15) 
                            : (isDark ? const Color(0xFF0A0A0A) : Colors.black.withOpacity(0.04)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected 
                              ? colorScheme.primary.withOpacity(0.4) 
                              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          categoryLabel,
                          style: TextStyle(
                            color: isSelected 
                                ? colorScheme.primary 
                                : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.tune_rounded, 
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4), size: 22),
              onPressed: () => _showFilterDialog(context, l10n, dataService),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent(ColorScheme colorScheme, bool isDark, AppLocalizations l10n, {bool isTablet = false, bool isLandscape = false}) {
    if (isTablet) {
      final dayReminders = filteredReminders;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isLandscape ? 3 : 1,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isLandscape ? 32 : 24),
              child: Column(
                children: [
                  _buildCalendarHeader(colorScheme, isDark, l10n, isTablet: true),
                  const SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(isLandscape ? 32 : 24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildWeekDays(isDark, l10n, isTablet: true),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: isLandscape ? 420 : 400,
                          child: PageView.builder(
                            controller: _monthPageController,
                            onPageChanged: (index) {
                              setState(() {
                                currentMonth = _getMonthForIndex(index);
                              });
                            },
                            itemBuilder: (context, index) {
                              final month = _getMonthForIndex(index);
                              return _buildCalendarGrid(month, colorScheme, isDark, isTablet: true, childAspectRatio: isLandscape ? 1.4 : 1.2);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildMonthlyStats(colorScheme, isDark, l10n),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: isLandscape ? 2 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.dayTasks.toUpperCase(), style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text(DateFormat(l10n.datePattern, l10n.localeName).format(selectedDate), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: dayReminders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 48, color: colorScheme.primary.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(l10n.freeDay, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: dayReminders.length,
                        itemBuilder: (context, index) => _buildReminderCard(dayReminders[index], colorScheme, isDark, isTablet: true),
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => _showAddOptions(context, colorScheme),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [const Icon(Icons.add_rounded), const SizedBox(width: 8), Text(l10n.addReminder)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final dayReminders = filteredReminders;
    final total = dayReminders.length;
    final completed = dayReminders.where((r) => r is Project ? r.status == ProjectStatus.completed : (r as Reminder).isCompleted).length;
    final pending = total - completed;

    return Stack(
      key: const ValueKey('calendar_view'),
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendarHeader(colorScheme, isDark, l10n),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildWeekDays(isDark, l10n),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 330, 
                          child: PageView.builder(
                            controller: _monthPageController,
                            onPageChanged: (index) {
                              setState(() {
                                currentMonth = _getMonthForIndex(index);
                              });
                            },
                            itemBuilder: (context, index) {
                              final month = _getMonthForIndex(index);
                              return _buildCalendarGrid(month, colorScheme, isDark);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 140), 
                ],
              ),
            ),
          ),
        ),

        ListenableBuilder(
          listenable: _sheetController,
          builder: (context, child) {
            double size = 0.22;
            try {
              if (_sheetController.isAttached) {
                size = _sheetController.size;
              }
            } catch (_) {}
            double t = ((size - 0.5) / (0.85 - 0.5)).clamp(0.0, 1.0);
            if (t == 0) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8 * t, sigmaY: 8 * t),
                  child: Container(
                    color: (isDark ? Colors.black : Colors.white).withOpacity(0.1 * t),
                  ),
                ),
              ),
            );
          },
        ),

        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.22,
          minChildSize: 0.22,
          maxChildSize: 0.85,
          snap: true,
          snapSizes: const [0.22, 0.85],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF050505) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onVerticalDragUpdate: (_) {},
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 40, height: 5,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity == null) return;
                        if (details.primaryVelocity! > 500) {
                          setState(() {
                            selectedDate = selectedDate.subtract(const Duration(days: 1));
                            _monthPageController.jumpToPage(_getIndexForMonth(selectedDate));
                          });
                        } else if (details.primaryVelocity! < -500) {
                          setState(() {
                            selectedDate = selectedDate.add(const Duration(days: 1));
                            _monthPageController.jumpToPage(_getIndexForMonth(selectedDate));
                          });
                        }
                      },
                      child: ListenableBuilder(
                        listenable: _sheetController,
                        builder: (context, child) {
                          final ds = Provider.of<DataService>(context, listen: false);
                          final bool isSimplified = ds.homeLayout.value == HomeLayout.simplified;

                          double size = 0.22;
                          try { if (_sheetController.isAttached) size = _sheetController.size; } catch (_) {}
                          double contentOpacity = ((size - 0.22) / (0.4 - 0.22)).clamp(0.0, 1.0);

                          return ListView(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(28, 0, 24, isSimplified ? 120 : 200),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.dayTasks, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                      const SizedBox(height: 4),
                                      Text(DateFormat(l10n.datePattern, l10n.localeName).format(selectedDate), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => _showMonthlyStatsSheet(context, colorScheme, isDark, l10n),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                      child: Text('${l10n.total[0]}: $total | ${l10n.completed[0]}: $completed | ${l10n.pending[0]}: $pending', style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              if (contentOpacity > 0)
                                Opacity(
                                  opacity: contentOpacity,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 30),
                                      if (dayReminders.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 40),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.auto_awesome_rounded, size: 64, color: colorScheme.primary.withOpacity(0.15)),
                                                const SizedBox(height: 16),
                                                Text(l10n.freeDay, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                                                const SizedBox(height: 8),
                                                Text(l10n.noScheduledTasks, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        ...dayReminders.map((reminder) => _buildReminderCard(reminder, colorScheme, isDark)).toList(),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeekDays(bool isDark, AppLocalizations l10n, {bool isTablet = false}) {
    final weekDays = [l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) => Expanded(
        child: Center(
          child: Text(day, style: TextStyle(color: day == l10n.sun ? Colors.red.withOpacity(0.7) : (isDark ? Colors.white38 : Colors.black38), fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarHeader(ColorScheme colorScheme, bool isDark, AppLocalizations l10n, {bool isTablet = false}) {
    String monthName = DateFormat('MMMM yyyy', l10n.localeName).format(currentMonth);
    monthName = monthName[0].toUpperCase() + monthName.substring(1);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isTablet ? 20 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.chevron_left, color: colorScheme.primary, size: isTablet ? 28 : 24), onPressed: () => _monthPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
          Text(monthName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: isTablet ? 24 : 18, fontWeight: FontWeight.bold)),
          IconButton(icon: Icon(Icons.chevron_right, color: colorScheme.primary, size: isTablet ? 28 : 24), onPressed: () => _monthPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month, ColorScheme colorScheme, bool isDark, {bool isTablet = false, double childAspectRatio = 1.0}) {
    final reminders = Provider.of<DataService>(context).reminders;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1).weekday;
    int startOffset = firstDayOfMonth % 7; 

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, 
        mainAxisSpacing: 0, 
        crossAxisSpacing: 0,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: daysInMonth + startOffset,
      itemBuilder: (context, index) {
        if (index < startOffset) return const SizedBox();
        int day = index - startOffset + 1;
        DateTime date = DateTime(month.year, month.month, day);
        bool isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
        bool isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
        
        final dayReminders = reminders.where((r) => r.isHappeningOn(date)).toList();
        final multiDayEvents = dayReminders.where((r) => r.endDate != null).toList();
        bool hasReminders = dayReminders.isNotEmpty;
        bool hasPending = dayReminders.any((r) => !r.isCompleted);

        bool isFirstDayOfRow = (index % 7) == 0;

        return GestureDetector(
          onTap: () => setState(() => selectedDate = date),
          onDoubleTap: () {
            setState(() => selectedDate = date);
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddReminderScreen(initialDate: date)));
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? colorScheme.primary.withOpacity(0.1) 
                  : (isToday ? colorScheme.primary.withOpacity(0.05) : Colors.transparent),
              border: isSelected 
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(isToday ? 0.2 : 0.03), width: isToday ? 1 : 0.5),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (multiDayEvents.isNotEmpty)
                  ...multiDayEvents.map((event) {
                    final bool isStart = date.year == event.dateTime.year && date.month == event.dateTime.month && date.day == event.dateTime.day;
                    final bool isEnd = event.endDate != null && date.year == event.endDate!.year && date.month == event.endDate!.month && date.day == event.endDate!.day;
                    final bool showTitle = isStart || isFirstDayOfRow;
                    
                    return Positioned(
                      left: isStart ? 4 : -1.0,
                      right: isEnd ? 4 : -1.0,
                      bottom: 6,
                      height: 16,
                      child: Container(
                        padding: EdgeInsets.only(left: isStart ? 6 : (isFirstDayOfRow ? 4 : 2)),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(event.isCompleted ? 0.3 : 0.9),
                          borderRadius: BorderRadius.horizontal(
                            left: isStart ? const Radius.circular(4) : Radius.zero,
                            right: isEnd ? const Radius.circular(4) : Radius.zero,
                          ),
                        ),
                        child: showTitle ? Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 8, 
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ) : null,
                      ),
                    );
                  }).toList(),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day.toString(), 
                        style: TextStyle(
                          color: (isSelected || isToday) ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black87), 
                          fontWeight: (isSelected || isToday) ? FontWeight.w900 : FontWeight.w600, 
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                      if (hasReminders && dayReminders.length > multiDayEvents.length)
                        Text(
                          '+${dayReminders.length - multiDayEvents.length}',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (hasReminders && multiDayEvents.isEmpty)
                  Positioned(
                    right: 8, bottom: 8,
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: hasPending ? colorScheme.primary.withOpacity(0.6) : Colors.grey.withOpacity(0.5), 
                        shape: BoxShape.circle
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthlyStatsSheet(BuildContext context, ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    showModalBottomSheet(context: context, backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(padding: const EdgeInsets.all(28.0), child: _buildMonthlyStats(colorScheme, isDark, l10n, isPopup: true)));
  }

  Widget _buildMonthlyStats(ColorScheme colorScheme, bool isDark, AppLocalizations l10n, {bool isPopup = false}) {
    final dataService = Provider.of<DataService>(context);
    final reminders = dataService.reminders;
    
    final monthReminders = reminders.where((r) => r.dateTime.year == currentMonth.year && r.dateTime.month == currentMonth.month).toList();
    final total = monthReminders.length;
    final completed = monthReminders.where((r) => r.isCompleted).length;
    final pending = total - completed;
    final double performance = total == 0 ? 0 : (completed / total) * 100;

    return Container(
      padding: isPopup ? EdgeInsets.zero : const EdgeInsets.all(24),
      decoration: isPopup ? null : BoxDecoration(color: isDark ? const Color(0xFF0A0A0A) : Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPopup) ...[
            Center(child: Container(width: 45, height: 4.5, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 28),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(l10n.total, total.toString(), colorScheme.primary, isDark),
              _buildStatItem(l10n.completed, completed.toString(), Colors.green, isDark),
              _buildStatItem(l10n.pending, pending.toString(), Colors.orange, isDark),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.monthlyPerformance, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(l10n.performanceDesc(DateFormat('MMMM', AppLocalizations.of(context)!.localeName).format(currentMonth), performance.toStringAsFixed(0)), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 60, height: 60, child: CircularProgressIndicator(value: performance / 100, strokeWidth: 8, backgroundColor: colorScheme.primary.withOpacity(0.1), color: colorScheme.primary, strokeCap: StrokeCap.round)),
                  Text('${performance.toStringAsFixed(0)}%', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(children: [Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold))]);
  }

  Widget _buildRemindersList(ColorScheme colorScheme, bool isDark, AppLocalizations l10n, {bool isTablet = false}) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final list = filteredReminders;
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final upcomingForCount = dataService.reminders.where((r) => 
      !r.isCompleted && 
      r.category == 'Evento' && 
      r.dateTime.isAfter(now)
    ).length;

    final upcomingEvents = dataService.reminders.where((r) => 
      !r.isCompleted && 
      r.category == 'Evento' && 
      !r.dateTime.isBefore(todayStart)
    ).toList();

    final todayEvents = upcomingEvents.where((r) => 
      r.dateTime.year == now.year && r.dateTime.month == now.month && r.dateTime.day == now.day
    ).toList();

    return Column(
      children: [
        if (upcomingForCount > 0 && dataService.reminderSelectedCategory == 'all')
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: InkWell(
              onTap: () {
                dataService.reminderSelectedCategory = 'Evento';
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      l10n.localeName == 'es' 
                        ? 'Próximos eventos: $upcomingForCount' 
                        : 'Upcoming events: $upcomingForCount',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: colorScheme.primary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        
        if (todayEvents.isNotEmpty && dataService.reminderSelectedCategory == 'all')
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.today.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: todayEvents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildSpecialTodayEventCard(todayEvents[index], colorScheme, isDark),
                ),
              ],
            ),
          ),

        Expanded(
          child: list.isEmpty
              ? Center(
                  key: const ValueKey('list_empty'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all_rounded, size: 64, color: colorScheme.primary.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text(l10n.noRemindersHere, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('list_view'),
                  padding: EdgeInsets.fromLTRB(20, 0, 20, isTablet ? 20 : 120),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    if (dataService.reminderSelectedCategory == 'all' && 
                        item is Reminder && 
                        item.category == 'Evento' && 
                        item.dateTime.year == now.year && 
                        item.dateTime.month == now.month && 
                        item.dateTime.day == now.day) {
                      return const SizedBox.shrink();
                    }
                    return _buildReminderCard(item, colorScheme, isDark, isTablet: isTablet);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSpecialTodayEventCard(Reminder reminder, ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderDetailsScreen(reminder: reminder))),
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 4, color: colorScheme.primary.withOpacity(0.8)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 13, color: colorScheme.primary.withOpacity(0.7)),
                              const SizedBox(width: 8),
                              Text(
                                reminder.time ?? (AppLocalizations.of(context)!.allDayLabel),
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
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
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colorScheme.primary.withOpacity(0.4), size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(dynamic item, ColorScheme colorScheme, bool isDark, {VoidCallback? onToggle, bool isTablet = false}) {
    if (item is Project) {
      return _buildProjectCard(item, colorScheme, isDark, isTablet: isTablet);
    }
    
    final reminder = item as Reminder;
    final isSelected = _selectedItem?.id == reminder.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.primary.withOpacity(0.1) 
            : (isDark ? const Color(0xFF0A0A0A).withOpacity(0.5) : Colors.black.withOpacity(0.02)), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.5) 
              : colorScheme.primary.withOpacity(isDark ? 0.08 : 0.1)
        )
      ),
      child: InkWell(
        onTap: () async {
          if (isTablet) {
            setState(() {
              _selectedItem = reminder;
            });
          } else {
            if (_selectedItem != null) {
              setState(() {
                if (_selectedItem?.id == reminder.id) {
                  _selectedItem = null;
                } else {
                  _selectedItem = reminder;
                }
              });
            } else {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderDetailsScreen(reminder: reminder)));
              if (result == 'delete') {
                Provider.of<DataService>(context, listen: false).deleteReminder(reminder.id);
              }
            }
          }
        },
        onLongPress: () {
          if (_selectedItem?.id == reminder.id) {
            setState(() {
              _selectedItem = null;
            });
          } else {
            setState(() {
              _selectedItem = reminder;
            });
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (reminder.category == 'Evento')
                Container(
                  width: 26, 
                  height: 26, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9), 
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.primary),
                )
              else
                GestureDetector(
                  onTap: () {
                    final isCompleting = !reminder.isCompleted;
                    final updatedReminder = reminder.copyWith(
                      isCompleted: isCompleting,
                      completedAt: isCompleting ? DateTime.now() : null,
                      clearCompletedAt: !isCompleting,
                    );
                    Provider.of<DataService>(context, listen: false).updateReminder(updatedReminder);
                    if (onToggle != null) onToggle();
                  },
                  child: Container(width: 26, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: reminder.isCompleted ? colorScheme.primary : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1)), width: 2), color: reminder.isCompleted ? colorScheme.primary : Colors.transparent), child: reminder.isCompleted ? const Icon(Icons.check, size: 18, color: Colors.white) : null),
                ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w700, decoration: reminder.isCompleted ? TextDecoration.lineThrough : null, decorationColor: isDark ? Colors.white38 : Colors.black38)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                        const SizedBox(width: 6),
                        Text(reminder.date, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.35), fontSize: 12, fontWeight: FontWeight.w600)),
                        if (reminder.sharedWith.isNotEmpty) ...[const SizedBox(width: 10), Icon(Icons.people_outline_rounded, size: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3))],
                      ],
                    ),
                  ],
                ),
              ),
              if (!reminder.isCompleted)
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: colorScheme.primary.withOpacity(0.1))), child: Text(_getCategoryLabel(reminder.category, AppLocalizations.of(context)!), style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project, ColorScheme colorScheme, bool isDark, {bool isTablet = false}) {
    final isSelected = _selectedItem?.id == project.id;
    final bool isCompleted = project.status == ProjectStatus.completed;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.primary.withOpacity(0.1) 
            : (isDark ? const Color(0xFF0A0A0A).withOpacity(0.5) : Colors.black.withOpacity(0.02)), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.5) 
              : (isCompleted ? Colors.green : colorScheme.primary).withOpacity(isDark ? 0.08 : 0.1)
        )
      ),
      child: InkWell(
        onTap: () {
          if (isTablet) {
            setState(() {
              _selectedItem = project;
            });
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailsScreen(projectId: project.id)));
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: (project.isIndependent ? Colors.orange : (isCompleted ? Colors.green : colorScheme.primary)).withAlpha(25), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Icon(
                      project.isIndependent ? Icons.person_outline_rounded : Icons.folder_special_rounded, 
                      color: project.isIndependent ? Colors.orange : (isCompleted ? Colors.green : colorScheme.primary), 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          project.isIndependent ? l10n.personal : l10n.project, 
                          style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 12)
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: project.progress, 
                        backgroundColor: (isCompleted ? Colors.green : colorScheme.primary).withAlpha(30), 
                        valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : colorScheme.primary), 
                        minHeight: 6
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(project.progress * 100).toInt()}%', style: TextStyle(color: isCompleted ? Colors.green : colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineContent(ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final dataService = Provider.of<DataService>(context);
    final reminders = dataService.reminders;
    final projects = dataService.projects;
    final selectedCategory = dataService.reminderSelectedCategory;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));

    List<dynamic> allItems = [];
    final Set<String> addedIds = {};

    // Filter reminders based on selectedCategory
    for (var r in reminders) {
      if (addedIds.contains(r.id)) continue;
      final eventEnd = r.endDate ?? r.dateTime;
      final isEvtPassed = r.category == 'Evento' && eventEnd.isBefore(today);
      final isCompleted = r.isCompleted || isEvtPassed;

      if (selectedCategory == 'completed') {
        if (isCompleted) { allItems.add(r); addedIds.add(r.id); }
      } else if (selectedCategory == 'pending') {
        if (!isCompleted) { allItems.add(r); addedIds.add(r.id); }
      } else if (selectedCategory == 'overdue') {
        final isEvtOngoing = r.category == 'Evento' && r.dateTime.isBefore(today) && !eventEnd.isBefore(today);
        final itemDay = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
        final isOverdue = !isCompleted && !isEvtOngoing && itemDay.isBefore(today);
        if (isOverdue) { allItems.add(r); addedIds.add(r.id); }
      } else if (selectedCategory == 'urgent') {
        if (!isCompleted && r.isUrgent) { allItems.add(r); addedIds.add(r.id); }
      } else if (selectedCategory == 'all') {
        allItems.add(r);
        addedIds.add(r.id);
      } else {
        if (r.category == selectedCategory) { allItems.add(r); addedIds.add(r.id); }
      }
    }

    // Filter projects based on selectedCategory
    for (var p in projects) {
      if (addedIds.contains(p.id)) continue;
      final isProjectCompleted = p.progress >= 1.0;
      if (selectedCategory == 'completed') {
        if (isProjectCompleted) { allItems.add(p); addedIds.add(p.id); }
      } else if (selectedCategory == 'pending') {
        if (!isProjectCompleted) { allItems.add(p); addedIds.add(p.id); }
      } else if (selectedCategory == 'overdue') {
        final dt = p.endDate ?? p.startDate;
        final itemDay = DateTime(dt.year, dt.month, dt.day);
        final isOverdue = !isProjectCompleted && itemDay.isBefore(today);
        if (isOverdue) { allItems.add(p); addedIds.add(p.id); }
      } else if (selectedCategory == 'all' || selectedCategory == 'Proyecto') {
        allItems.add(p);
        addedIds.add(p.id);
      } else if (selectedCategory == 'urgent' && p.status == ProjectStatus.inProgress) {
        if (!isProjectCompleted) { allItems.add(p); addedIds.add(p.id); }
      }
    }

    final List<dynamic> overdue = [];
    final List<dynamic> todayList = [];
    final List<dynamic> tomorrowList = [];
    final List<dynamic> thisWeek = [];
    final List<dynamic> later = [];
    final List<dynamic> noDate = [];
    final List<dynamic> completedList = [];

    for (var item in allItems) {
      bool isCompleted = false;
      DateTime? itemDate;

      if (item is Reminder) {
        final eventEnd = item.endDate ?? item.dateTime;
        final isEvtPassed = item.category == 'Evento' && eventEnd.isBefore(today);
        isCompleted = item.isCompleted || isEvtPassed;
        itemDate = item.dateTime;

        // Ongoing events (started before today, ends today or later) are grouped under Today
        if (!isCompleted && item.category == 'Evento' && item.dateTime.isBefore(today) && !eventEnd.isBefore(today)) {
          itemDate = today;
        }
      } else if (item is Project) {
        isCompleted = item.progress >= 1.0;
        itemDate = item.endDate ?? item.startDate;

        // Ongoing projects (started before today, ends today or later) are grouped under Today
        if (!isCompleted && item.startDate.isBefore(today) && itemDate != null && !itemDate.isBefore(today)) {
          itemDate = today;
        }
      }

      if (isCompleted) {
        completedList.add(item);
        continue;
      }

      if (itemDate == null || itemDate.year < 2000) {
        noDate.add(item);
        continue;
      }

      final itemDay = DateTime(itemDate.year, itemDate.month, itemDate.day);

      if (itemDay.isBefore(today)) {
        overdue.add(item);
      } else if (itemDay.isAtSameMomentAs(today)) {
        todayList.add(item);
      } else if (itemDay.isAtSameMomentAs(tomorrow)) {
        tomorrowList.add(item);
      } else if (!itemDay.isAfter(endOfWeek)) {
        thisWeek.add(item);
      } else {
        later.add(item);
      }
    }

    void sortItems(List<dynamic> list) {
      list.sort((a, b) {
        final dtA = a is Reminder ? a.dateTime : (a as Project).endDate ?? a.startDate;
        final dtB = b is Reminder ? b.dateTime : (b as Project).endDate ?? b.startDate;
        return dtA.compareTo(dtB);
      });
    }

    sortItems(overdue);
    sortItems(todayList);
    sortItems(tomorrowList);
    sortItems(thisWeek);
    sortItems(later);
    sortItems(completedList);

    final bool showAll = selectedCategory == 'all';
    final bool showPendingOnly = selectedCategory == 'pending';
    final bool showCompletedOnly = selectedCategory == 'completed';

    final sections = <_TimelineSectionData>[
      if (showPendingOnly) ...[
        _TimelineSectionData(
          id: 'overdue',
          title: l10n.overdue,
          icon: Icons.warning_amber_rounded,
          color: Colors.redAccent,
          items: overdue,
          isAlert: true,
          alwaysShow: true,
        ),
      ],
      if (showAll || (!showPendingOnly && !showCompletedOnly)) ...[
        _TimelineSectionData(
          id: 'today',
          title: l10n.today,
          icon: Icons.star_rounded,
          color: colorScheme.primary,
          items: todayList,
          targetDate: today,
          alwaysShow: true,
        ),
        _TimelineSectionData(
          id: 'tomorrow',
          title: l10n.tomorrow,
          icon: Icons.wb_sunny_rounded,
          color: Colors.orangeAccent,
          items: tomorrowList,
          targetDate: tomorrow,
          alwaysShow: true,
        ),
        if (thisWeek.isNotEmpty)
          _TimelineSectionData(
            id: 'thisWeek',
            title: l10n.thisWeek,
            icon: Icons.date_range_rounded,
            color: Colors.blueAccent,
            items: thisWeek,
          ),
        if (later.isNotEmpty)
          _TimelineSectionData(
            id: 'later',
            title: l10n.later,
            icon: Icons.rocket_launch_rounded,
            color: Colors.purpleAccent,
            items: later,
          ),
        if (noDate.isNotEmpty)
          _TimelineSectionData(
            id: 'noDate',
            title: l10n.noDate,
            icon: Icons.push_pin_rounded,
            color: Colors.grey,
            items: noDate,
          ),
      ],
      if (showCompletedOnly)
        _TimelineSectionData(
          id: 'completed',
          title: l10n.completed,
          icon: Icons.check_circle_rounded,
          color: Colors.green,
          items: completedList,
          isCompletedSection: true,
          alwaysShow: true,
        ),
    ];

    final totalActiveCount = todayList.length + tomorrowList.length + thisWeek.length + later.length + noDate.length;

    return SingleChildScrollView(
      key: const ValueKey('board_view'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineSummaryCard(
            totalPending: totalActiveCount,
            todayCount: todayList.length,
            tomorrowCount: tomorrowList.length,
            colorScheme: colorScheme,
            isDark: isDark,
            l10n: l10n,
          ),
          const SizedBox(height: 20),
          ...sections.map((sec) => _buildTimelineSectionWidget(
            sec,
            colorScheme,
            isDark,
            l10n,
            dataService,
          )),
        ],
      ),
    );
  }

  Widget _buildTimelineSummaryCard({
    required int totalPending,
    required int todayCount,
    required int tomorrowCount,
    required ColorScheme colorScheme,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : colorScheme.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryStat(
            icon: Icons.star_rounded,
            iconColor: colorScheme.primary,
            label: l10n.today,
            value: todayCount.toString(),
            isDark: isDark,
          ),
          Container(
            height: 30,
            width: 1,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          _buildSummaryStat(
            icon: Icons.wb_sunny_rounded,
            iconColor: Colors.orangeAccent,
            label: l10n.tomorrow,
            value: tomorrowCount.toString(),
            isDark: isDark,
          ),
          Container(
            height: 30,
            width: 1,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          _buildSummaryStat(
            icon: Icons.schedule_rounded,
            iconColor: Colors.blueAccent,
            label: l10n.all,
            value: totalPending.toString(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isHighlight ? Colors.redAccent : (isDark ? Colors.white : Colors.black),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineSectionWidget(
    _TimelineSectionData sec,
    ColorScheme colorScheme,
    bool isDark,
    AppLocalizations l10n,
    DataService dataService,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sec.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sec.icon, color: sec.color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                sec.title,
                style: TextStyle(
                  color: sec.isAlert ? Colors.redAccent : (isDark ? Colors.white : Colors.black),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (sec.isAlert ? Colors.redAccent : sec.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sec.items.length.toString(),
                  style: TextStyle(
                    color: sec.isAlert ? Colors.redAccent : sec.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sec.items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.25),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Sin pendientes",
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sec.items.length,
              itemBuilder: (context, index) {
                final item = sec.items[index];
                final isLast = index == sec.items.length - 1;
                return _buildTimelineItemRow(
                  item: item,
                  sectionColor: sec.color,
                  isLast: isLast,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  l10n: l10n,
                  dataService: dataService,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItemRow({
    required dynamic item,
    required Color sectionColor,
    required bool isLast,
    required ColorScheme colorScheme,
    required bool isDark,
    required AppLocalizations l10n,
    required DataService dataService,
  }) {
    final bool isCompleted = item is Reminder ? item.isCompleted : (item as Project).progress >= 1.0;
    final bool isUrgent = item is Reminder ? item.isUrgent : false;

    final dotColor = isCompleted
        ? Colors.green
        : (isUrgent ? Colors.redAccent : sectionColor);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTimelineCard(
                item,
                colorScheme,
                isDark,
                l10n,
                dataService,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    dynamic item,
    ColorScheme colorScheme,
    bool isDark,
    AppLocalizations l10n,
    DataService dataService,
  ) {
    final bool isReminder = item is Reminder;
    final Reminder? reminder = isReminder ? item as Reminder : null;
    final Project? project = !isReminder ? item as Project : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventEnd = isReminder ? (reminder!.endDate ?? reminder.dateTime) : null;
    final bool isEvtPassed = isReminder && reminder!.category == 'Evento' && eventEnd!.isBefore(today);
    final bool isOngoing = isReminder
        ? (reminder!.category == 'Evento' && reminder.dateTime.isBefore(today) && !eventEnd!.isBefore(today))
        : (project != null && project.startDate.isBefore(today) && project.endDate != null && !project.endDate!.isBefore(today));

    final String title = isReminder ? reminder!.title : project!.title;
    final bool isCompleted = isReminder ? (reminder!.isCompleted || isEvtPassed) : project!.progress >= 1.0;
    final bool isUrgent = isReminder ? reminder!.isUrgent : false;
    final String category = isReminder ? _getCategoryLabel(reminder!.category, l10n) : l10n.project;
    final String? location = isReminder ? reminder!.location : null;
    final String? description = isReminder ? reminder!.description : project!.description;

    String dateStr = '';
    String? timeStr;
    if (isReminder) {
      if (reminder!.endDate != null) {
        final formattedEnd = DateFormat('dd MMM', l10n.localeName).format(reminder.endDate!);
        dateStr = 'Hasta el $formattedEnd';
      } else {
        dateStr = reminder.date;
      }
      timeStr = reminder.time;
    } else {
      dateStr = project!.endDate != null ? 'Hasta el ${DateFormat('dd MMM', l10n.localeName).format(project.endDate!)}' : 'Sin fecha';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent && !isCompleted
              ? Colors.redAccent.withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          width: isUrgent && !isCompleted ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isReminder) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReminderDetailsScreen(reminder: reminder!),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailsScreen(projectId: project!.id),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isReminder
                            ? colorScheme.primary.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: isReminder ? colorScheme.primary : Colors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isOngoing && !isCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "EN CURSO",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    if (isUrgent && !isCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.urgent.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _toggleCompletion(item, dataService),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? Colors.green : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green
                                : (isDark ? Colors.white38 : Colors.black38),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (project != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: project.progress,
                            backgroundColor: colorScheme.primary.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${(project.progress * 100).toInt()}%",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.35),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (timeStr != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (location != null && location.isNotEmpty) ...[
                      const Spacer(),
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Colors.redAccent.withOpacity(0.7),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCompletion(dynamic item, DataService dataService) {
    if (item is Reminder) {
      final updated = item.copyWith(
        isCompleted: !item.isCompleted,
        completedAt: !item.isCompleted ? DateTime.now() : null,
        clearCompletedAt: item.isCompleted,
      );
      dataService.updateReminder(updated);
    } else if (item is Project) {
      final newProgress = item.progress >= 1.0 ? 0.0 : 1.0;
      final updated = item.copyWith(progress: newProgress);
      dataService.updateProject(updated);
    }
  }

  void _showFilterDialog(BuildContext context, AppLocalizations l10n, DataService dataService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.orderBy,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(context, l10n.defaultOrder, 'default', Icons.auto_awesome_rounded, colorScheme, dataService),
              const SizedBox(height: 10),
              _buildFilterOption(context, l10n.byDate, 'by_date', Icons.calendar_month_rounded, colorScheme, dataService),
              const SizedBox(height: 10),
              _buildFilterOption(context, l10n.alphabetically, 'alphabetical', Icons.sort_by_alpha_rounded, colorScheme, dataService),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String label, String key, IconData icon, ColorScheme colorScheme, DataService dataService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = dataService.reminderSelectedFilter == key;
    return InkWell(onTap: () { dataService.reminderSelectedFilter = key; Navigator.pop(context); }, borderRadius: BorderRadius.circular(20),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: isSelected ? colorScheme.primary.withOpacity(0.05) : Colors.transparent, border: Border.all(color: isSelected ? colorScheme.primary.withOpacity(0.2) : (isDark ? Colors.white38 : Colors.black38).withOpacity(0.03)), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isSelected ? colorScheme.primary.withOpacity(0.1) : (isDark ? Colors.white38 : Colors.black38).withOpacity(0.03), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isSelected ? colorScheme.primary : (isDark ? Colors.white38 : Colors.black38), size: 20)),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white70 : Colors.black54), fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 16)),
          const Spacer(),
          if (isSelected) Icon(Icons.check_circle_rounded, size: 20, color: colorScheme.primary),
        ]),
      ),
    );
  }

  void _showAddOptions(BuildContext context, ColorScheme colorScheme) {
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
            _buildOptionItem(context, icon: Icons.notification_add_rounded, title: l10n.newReminder, subtitle: "Crea una tarea simple con fecha y hora", onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddReminderScreen(initialDate: DateTime.now()))); }),
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
}

class _TimelineSectionData {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> items;
  final DateTime? targetDate;
  final bool isAlert;
  final bool isCompletedSection;
  final bool alwaysShow;

  _TimelineSectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.targetDate,
    this.isAlert = false,
    this.isCompletedSection = false,
    this.alwaysShow = false,
  });
}
