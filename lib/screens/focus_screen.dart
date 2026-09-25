import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:convert';
import 'package:nest/l10n/app_localizations.dart';
import 'package:nest/utils/date_utils.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import '../models/focus_session.dart';
import '../models/note.dart';
import '../models/group_comment.dart';
import '../models/group_post.dart';
import 'note_editor_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  // Focus Tab State
  int _focusDuration = 25;
  int _breakDuration = 5;
  bool _silenceNotifications = false;
  bool _isStrictMode = false;
  bool _useRingtone = false;
  final bool _isFocusNotePersonal = true;
  
  final TextEditingController _quickNoteController = TextEditingController();
  final ScrollController _focusScrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();
  Timer? _focusTimer;
  
  // Animation for focus start
  late AnimationController _settingsAnimController;
  late AnimationController _progressAnimController;
  bool _isStartingFocus = false;

  @override
  void initState() {
    super.initState();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });

    _settingsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _quickNoteController.dispose();
    _focusScrollController.dispose();
    _chatScrollController.dispose();
    _settingsAnimController.dispose();
    _progressAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final dataService = Provider.of<DataService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.focus),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<DataService>(
          builder: (context, dataService, child) {
            final activeSession = dataService.activeFocusSession;

            if (activeSession != null) {
              return _buildActiveFocusView(
                context, 
                dataService, 
                activeSession, 
                colorScheme, 
                isDark, 
                l10n,
                key: const ValueKey('active_focus_view'),
              );
            }

            return _buildIndividualModeView(
              context, 
              dataService, 
              colorScheme, 
              isDark, 
              l10n,
              key: const ValueKey('idle_focus_view'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIndividualModeView(BuildContext context, DataService dataService, ColorScheme colorScheme, bool isDark, AppLocalizations l10n, {Key? key}) {
    return ListenableBuilder(
      key: key,
      listenable: _progressAnimController,
      builder: (context, child) {
        final double t = _progressAnimController.value;
        final double progress = _isStartingFocus ? t : 0.0;
        
        final double settingsOpacity = (1.0 - t * 2.5).clamp(0.0, 1.0);
        final double settingsTranslation = Curves.easeIn.transform(t) * 150.0;

        return Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildLargeTimerDisplay(
                            progress, 
                            '$_focusDuration:00', 
                            '', 
                            colorScheme, 
                            isDark,
                            action: _isStartingFocus ? null : _buildStartFocusButton(context, dataService, colorScheme, l10n),
                          ),
                          const SizedBox(height: 60),
                          Transform.translate(
                            offset: Offset(0, settingsTranslation),
                            child: Opacity(
                              opacity: settingsOpacity,
                              child: IgnorePointer(
                                ignoring: _isStartingFocus,
                                child: _buildModernFocusConfig(context, dataService, colorScheme, isDark, l10n),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStartFocusButton(BuildContext context, DataService dataService, ColorScheme colorScheme, AppLocalizations l10n) {
    return InkWell(
      onTap: () async {
        _progressAnimController.reset();
        setState(() => _isStartingFocus = true);
        await _progressAnimController.forward();

        final id = const Uuid().v4();
        final curId = dataService.userId ?? dataService.userName;
        final session = FocusSession(
          id: id,
          title: 'Sesión Personal',
          creatorId: curId,
          participants: [curId],
          focusDuration: _focusDuration,
          breakDuration: _breakDuration,
          isPrivate: true,
          silenceNotifications: _silenceNotifications,
          isStrictMode: _isStrictMode,
          useRingtone: _useRingtone,
          status: FocusSessionStatus.focusing,
          startTime: DateTime.now(),
        );
        
        dataService.addFocusSession(session);

        if (mounted) {
          setState(() => _isStartingFocus = false);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.startFocus.toUpperCase(),
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildModernFocusConfig(BuildContext context, DataService dataService, ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactDurationPicker(
            l10n.focusLabel, 
            _focusDuration, 
            (val) => setState(() {
              _focusDuration = val;
              if (val <= 25) _breakDuration = 5;
              else if (val <= 45) _breakDuration = 10;
              else if (val <= 60) _breakDuration = 15;
              else _breakDuration = 30;
            }),
            [15, 25, 45, 60, 90],
            colorScheme
          ),
          const SizedBox(height: 20),
          _buildCompactDurationPicker(
            l10n.breakLabel, 
            _breakDuration, 
            (val) => setState(() => _breakDuration = val),
            [5, 10, 15, 20, 30],
            colorScheme,
            isBreak: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSquareToggle(
                label: l10n.silence,
                icon: Icons.notifications_off_outlined,
                isSelected: _silenceNotifications,
                onTap: () async {
                  final bool isGranted = await dataService.isDNDPermissionGranted();
                  if (!isGranted) {
                    if (!context.mounted) return;
                    _showDNDPermissionDialog(context, l10n);
                  } else {
                    setState(() => _silenceNotifications = !_silenceNotifications);
                  }
                },
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildSquareToggle(
                label: l10n.strict,
                icon: Icons.lock_outline_rounded,
                isSelected: _isStrictMode,
                onTap: () => setState(() => _isStrictMode = !_isStrictMode),
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildSquareToggle(
                label: l10n.alarm,
                icon: Icons.alarm_on,
                isSelected: _useRingtone,
                onTap: () => setState(() => _useRingtone = !_useRingtone),
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareToggle({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap, required ColorScheme colorScheme, required bool isDark}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black38), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black87),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFocusView(BuildContext context, DataService dataService, FocusSession session, ColorScheme colorScheme, bool isDark, AppLocalizations l10n, {Key? key}) {
    int totalSeconds = session.focusDuration * 60;
    if (session.status == FocusSessionStatus.shortBreak) totalSeconds = session.breakDuration * 60;
    
    int elapsedSeconds = 0;
    if (session.startTime != null) {
      elapsedSeconds = DateTime.now().difference(session.startTime!).inSeconds;
    }
    
    final remainingSeconds = totalSeconds - elapsedSeconds;
    final progress = (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
    
    final String timerLabel = session.status == FocusSessionStatus.focusing ? l10n.focus : 
                          (remainingSeconds <= 0 ? l10n.breakFinished : l10n.breakLabel);

    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1.0 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildLargeTimerDisplay(progress, _formatDuration(remainingSeconds), timerLabel.toUpperCase(), colorScheme, isDark),
                const SizedBox(height: 40),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded, size: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                      const SizedBox(width: 8),
                      Text(
                        'Sesión Personal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                        ),
                      ),
                      const Spacer(),
                      _buildStopButton(context, dataService, session, colorScheme, l10n),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: _buildSessionNotes(context, dataService, session, isDark, l10n),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLargeTimerDisplay(double progress, String time, String label, ColorScheme colorScheme, bool isDark, {Widget? action}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth * 0.8;
        if (size > 320) size = 320;
        if (size < 200) size = 200;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: size / 26,
                  backgroundColor: colorScheme.primary.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: size / 3.8,
                      fontWeight: FontWeight.w200,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -size / 80,
                    ),
                  ),
                  if (action != null) ...[
                    SizedBox(height: size / 26),
                    action,
                  ],
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCompactDurationPicker(String label, int current, Function(int) onSelected, List<int> options, ColorScheme colorScheme, {bool isBreak = false}) {
    final Color activeColor = isBreak ? Colors.green : colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activeColor.withOpacity(0.5))),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) {
              final isSel = current == opt;
              Color chipColor = activeColor;
              if (!isBreak && opt == 90) chipColor = Colors.orange;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$opt min'),
                  selected: isSel,
                  onSelected: (val) => onSelected(opt),
                  showCheckmark: false,
                  selectedColor: chipColor,
                  labelStyle: TextStyle(color: isSel ? Colors.white : null, fontWeight: isSel ? FontWeight.bold : null, fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _handleCreateFocusNote(DataService dataService, FocusSession session, AppLocalizations l10n, {String? quickText}) {
    final id = const Uuid().v4();
    final note = Note(
      id: id,
      author: dataService.userName,
      title: quickText != null ? 'Nota de sesión' : l10n.quickNote,
      content: jsonEncode([{"insert": "${quickText ?? ""}\n"}]),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      focusSessionId: session.id,
    );

    dataService.addNote(note);
  }

  Widget _buildSessionNotes(BuildContext context, DataService dataService, FocusSession session, bool isDark, AppLocalizations l10n) {
    final personalNotes = dataService.notes.where((n) => n.focusSessionId == session.id).toList();
    
    final allNotes = personalNotes..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.recentNotes, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  IconButton(
                    onPressed: () => _handleCreateFocusNote(dataService, session, l10n),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: allNotes.isEmpty
            ? Center(child: Text(l10n.noNotesYet, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2))))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: allNotes.length,
                itemBuilder: (context, index) {
                  final note = allNotes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildNoteCard(context, note),
                  );
                },
              ),
        ),
        
        Container(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _quickNoteController,
            decoration: InputDecoration(
              hintText: 'Anotación rápida...',
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                onPressed: () {
                  if (_quickNoteController.text.trim().isEmpty) return;
                  _handleCreateFocusNote(dataService, session, l10n, quickText: _quickNoteController.text.trim());
                  _quickNoteController.clear();
                },
                icon: const Icon(Icons.send_rounded),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = note.backgroundColor ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02));
    final bool isNoteDark = note.backgroundColor != null 
        ? note.backgroundColor!.computeLuminance() < 0.5 
        : isDark;

    final Color textColor = isNoteDark ? Colors.white : Colors.black;

    final bool showPreview = note.isQuickNote && (note.title.isEmpty || note.title == l10n.quickNote);
    final String displayText = showPreview
        ? (note.previewText.isEmpty ? l10n.noContent : note.previewText)
        : (note.title.isEmpty ? l10n.noTitle : note.title);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: (note.backgroundColor == null && !isDark) ? Border.all(color: Colors.black.withOpacity(0.05)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayText,
              style: TextStyle(
                  color: isNoteDark ? textColor.withOpacity(0.8) : textColor.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: showPreview ? FontWeight.normal : FontWeight.bold,
                  height: 1.3
              ),
              maxLines: showPreview ? 5 : 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateUtilsFormatter.formatDynamicDate(context, note.updatedAt),
                style: TextStyle(
                  color: isNoteDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.6),
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

  Widget _buildStopButton(BuildContext context, DataService dataService, FocusSession session, ColorScheme colorScheme, AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: () {
        dataService.updateFocusSessionStatus(session.id, FocusSessionStatus.idle);
      },
      icon: const Icon(Icons.stop_rounded, size: 18),
      label: Text(l10n.finish.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.redAccent,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 0) return "00:00";
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showDNDPermissionDialog(BuildContext context, AppLocalizations l10n) {
    final dataService = Provider.of<DataService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.permissionRequiredTitle),
        content: Text(l10n.dndPermissionDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () { dataService.openDNDSettings(); Navigator.pop(context); }, child: Text(l10n.configureBtn)),
        ],
      ),
    );
  }
}
