import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nest/services/data_service.dart';
import 'package:nest/models/note.dart';
import 'package:nest/models/notebook.dart';
import 'package:nest/screens/note_editor_screen.dart';
import 'package:nest/screens/notebook_details_screen.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'package:nest/utils/date_utils.dart';

class NoteSearchScreen extends StatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  State<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends State<NoteSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
          decoration: InputDecoration(
            hintText: l10n.searchNotesHint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _query = value.toLowerCase();
            });
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          final filteredNotes = dataService.notes.where((note) {
            final titleMatch = note.title.toLowerCase().contains(_query);
            final contentMatch = note.previewText.toLowerCase().contains(_query);
            return titleMatch || contentMatch;
          }).toList();

          final filteredNotebooks = dataService.notebooks.where((notebook) {
            return notebook.name.toLowerCase().contains(_query);
          }).toList();

          final List<dynamic> combinedResults = [...filteredNotes, ...filteredNotebooks];
          // Sort by date (updatedAt for notes, createdAt for notebooks)
          combinedResults.sort((a, b) {
            final dateA = a is Note ? a.updatedAt : (a as Notebook).createdAt;
            final dateB = b is Note ? b.updatedAt : (b as Notebook).createdAt;
            return dateB.compareTo(dateA);
          });

          if (_query.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    l10n.startTypingToSearch,
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          if (combinedResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noResultsFound,
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: combinedResults.length,
            itemBuilder: (context, index) {
              final item = combinedResults[index];
              if (item is Note) {
                return _buildNoteResult(context, item, isDark, l10n);
              } else {
                return _buildNotebookResult(context, item as Notebook, isDark, l10n);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteResult(BuildContext context, Note note, bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          note.title.isNotEmpty 
              ? note.title 
              : (note.previewText.isNotEmpty 
                  ? (note.previewText.split('\n').first.length > 35 
                      ? '${note.previewText.split('\n').first.substring(0, 35)}...' 
                      : note.previewText.split('\n').first)
                  : l10n.untitledNote),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            note.title.isEmpty && note.previewText.contains('\n')
                ? note.previewText.substring(note.previewText.indexOf('\n')).trim().replaceAll('\n', ' ')
                : note.previewText.replaceAll('\n', ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateUtilsFormatter.formatDynamicDate(context, note.updatedAt),
              style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (note.notebookId != null) ...[
              const SizedBox(height: 4),
              Icon(Icons.book_rounded, size: 12, color: isDark ? Colors.white24 : Colors.black26),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)));
        },
      ),
    );
  }

  Widget _buildNotebookResult(BuildContext context, Notebook notebook, bool isDark, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: notebook.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            notebook.icon,
            color: notebook.color,
            size: 20,
          ),
        ),
        title: Text(
          notebook.name,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          l10n.notebooks,
          style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12),
        ),
        trailing: Text(
          DateUtilsFormatter.formatDynamicDate(context, notebook.createdAt),
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotebookDetailsScreen(notebook: notebook),
            ),
          );
        },
      ),
    );
  }
}
