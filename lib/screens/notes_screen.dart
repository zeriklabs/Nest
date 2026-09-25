import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../utils/date_utils.dart';
import 'note_editor_screen.dart';
import 'note_search_screen.dart';
import 'create_notebook_screen.dart';
import 'notebook_details_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final dataService = Provider.of<DataService>(context);
    final isNotebooksView = dataService.notesTabIndex == 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(dataService, isDark, colorScheme, l10n),
            _buildToggle(colorScheme, isDark, l10n, dataService),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isNotebooksView
                    ? _buildNotebooksGrid(colorScheme, isDark, l10n)
                    : _buildQuickNotesGrid(colorScheme, isDark, l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: dataService.homeLayout.value == HomeLayout.simplified ? null : Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          heroTag: 'notes_fab',
          onPressed: () {
            if (isNotebooksView) {
              _showCreateNotebookScreen(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
              );
            }
          },
          backgroundColor: colorScheme.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void _showCreateNotebookScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNotebookScreen()),
    );
  }

  Widget _buildHeader(DataService dataService, bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    final isSimplified = dataService.homeLayout.value == HomeLayout.simplified;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                l10n.myNotes,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search_rounded, 
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4), size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NoteSearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(ColorScheme colorScheme, bool isDark, AppLocalizations l10n, DataService dataService) {
    final isNotebooksView = dataService.notesTabIndex == 1;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton(l10n.quick, !isNotebooksView, () => dataService.notesTabIndex = 0, colorScheme, isDark)),
          Expanded(child: _buildToggleButton(l10n.notebooks, isNotebooksView, () => dataService.notesTabIndex = 1, colorScheme, isDark)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isSelected, VoidCallback onTap, ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNotesGrid(ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;
    
    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final notes = dataService.notes.where((n) => n.isQuickNote).toList();
        if (notes.isEmpty) return Center(child: Text(l10n.noQuickNotes, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4))));

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2, 
            mainAxisSpacing: 12, 
            crossAxisSpacing: 12, 
            childAspectRatio: isTablet ? 1.0 : 0.9,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final String previewText = note.previewText.isEmpty ? l10n.noContent : note.previewText;

            final bool hasCustomBg = note.backgroundColor != null;
            final bool isCardDark = hasCustomBg 
                ? note.backgroundColor!.computeLuminance() < 0.5 
                : isDark;

            final Color textColor = isCardDark ? Colors.white : Colors.black;

            return Container(
              decoration: BoxDecoration(
                color: note.backgroundColor ?? (isDark ? const Color(0xFF18181B) : Colors.white),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note))),
                  onLongPress: () => _showDeleteDialog(context, note),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            previewText, 
                            style: TextStyle(
                              color: textColor.withOpacity(0.8), 
                              fontSize: 13, 
                              height: 1.3,
                            ), 
                            maxLines: isTablet ? 10 : 8,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight, 
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (note.sharedWithList.isNotEmpty) ...[
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 12,
                                  color: textColor.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                DateUtilsFormatter.formatDynamicDate(context, note.updatedAt), 
                                style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                )
                              ),
                            ],
                          )
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotebooksGrid(ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 720;

    return Consumer<DataService>(
      builder: (context, dataService, child) {
        final notebooks = dataService.notebooks;
        if (notebooks.isEmpty) return Center(child: Text(l10n.noNotebooksYet, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4))));

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2, 
            mainAxisSpacing: 15, 
            crossAxisSpacing: 15, 
            childAspectRatio: 0.85,
          ),
          itemCount: notebooks.length,
          itemBuilder: (context, index) {
            final notebook = notebooks[index];
            final noteCount = dataService.getNotesForNotebook(notebook.id).length;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: notebook.color.withOpacity(0.2)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotebookDetailsScreen(notebook: notebook))),
                  onLongPress: () => _showDeleteNotebookDialog(context, notebook),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: notebook.color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(notebook.icon, color: notebook.color, size: 24)),
                        const Spacer(),
                        Text(notebook.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(l10n.notesCount(noteCount), style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Note note) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.deleteNoteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(onPressed: () { Provider.of<DataService>(context, listen: false).deleteNote(note.id); Navigator.pop(context); }, child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showDeleteNotebookDialog(BuildContext context, Notebook notebook) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNotebook),
        content: Text(l10n.deleteNotebookConfirm(notebook.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(onPressed: () { Provider.of<DataService>(context, listen: false).deleteNotebook(notebook.id); Navigator.pop(context); }, child: Text(l10n.deleteAll, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
