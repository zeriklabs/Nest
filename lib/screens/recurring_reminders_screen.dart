import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/recurrence.dart';

class RecurringRemindersScreen extends StatelessWidget {
  const RecurringRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context);
    final programs = dataService.recurringPrograms;
    
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;
    final bool isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context, isDark, l10n, isTablet),
            Expanded(
              child: programs.isEmpty
                  ? _buildEmptyState(isDark, colorScheme, l10n)
                  : _buildContent(context, programs, isDark, colorScheme, dataService, l10n, isTablet, isLandscape),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, bool isDark, AppLocalizations l10n, bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isTablet ? 32 : 24, isTablet ? 32 : 20, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            l10n.recurringPrograms,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: isTablet ? 32 : 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<RecurringProgram> programs, bool isDark, ColorScheme colorScheme, DataService dataService, AppLocalizations l10n, bool isTablet, bool isLandscape) {
    if (isTablet) {
      return GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: isLandscape ? 40 : 32, vertical: 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLandscape ? 3 : 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.2,
        ),
        itemCount: programs.length,
        itemBuilder: (context, index) {
          return _buildProgramCard(context, programs[index], isDark, colorScheme, dataService, l10n, isTablet: true);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        return _buildProgramCard(context, programs[index], isDark, colorScheme, dataService, l10n);
      },
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_problem_rounded, size: 64, color: colorScheme.primary.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            l10n.noProgramsYet,
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

  Widget _buildProgramCard(BuildContext context, RecurringProgram program, bool isDark, ColorScheme colorScheme, DataService dataService, AppLocalizations l10n, {bool isTablet = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 0 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.primary.withOpacity(isDark ? 0.08 : 0.1)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Futura edición de programa
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.auto_awesome_motion_rounded, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            program.category,
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: program.isActive,
                      onChanged: (val) {
                        final updated = program.copyWith(isActive: val);
                        dataService.updateRecurringProgram(updated);
                      },
                      activeColor: colorScheme.primary,
                      activeTrackColor: colorScheme.primary.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_repeat_rounded, size: 16, color: colorScheme.primary.withOpacity(0.7)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          program.config.humanReadable,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(context, program, dataService, l10n),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(l10n.delete),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, RecurringProgram program, DataService dataService, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProgram),
        content: Text(l10n.deleteProgramConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              dataService.deleteRecurringProgram(program.id);
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
