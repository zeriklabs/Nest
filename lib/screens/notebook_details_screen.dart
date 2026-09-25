import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/notebook.dart';
import '../models/note.dart';
import '../services/data_service.dart';
import '../utils/date_utils.dart';
import 'note_editor_screen.dart';

class NotebookDetailsScreen extends StatelessWidget {
  final Notebook notebook;

  const NotebookDetailsScreen({super.key, required this.notebook});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(notebook.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          final notebookNotes = dataService.getNotesForNotebook(notebook.id);

          if (notebookNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 64,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.emptyNotebook,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: notebookNotes.length,
            itemBuilder: (context, index) {
              final note = notebookNotes[index];

              String previewText = note.previewText;
              if (previewText.isEmpty) previewText = note.title;

              return _NotePreviewCard(
                note: note,
                previewText: previewText,
                notebookColor: notebook.color,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'notebook_details_fab',
        onPressed: () => _showNewPageSheet(context),
        label: Text(l10n.newPage),
        icon: const Icon(Icons.add),
        backgroundColor: notebook.color,
      ),
    );
  }

  void _showNewPageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _NewPageSheet(notebook: notebook),
    );
  }
}

class _NotePreviewCard extends StatelessWidget {
  final Note note;
  final String previewText;
  final Color notebookColor;

  const _NotePreviewCard({
    required this.note,
    required this.previewText,
    required this.notebookColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(
              note: note,
              notebookId: note.notebookId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Cabecera" de la página con el color de la libreta
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: notebookColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateUtilsFormatter.formatDynamicDate(context, note.updatedAt),
                    style: TextStyle(
                      fontSize: 10, 
                      color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    previewText,
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPageSheet extends StatefulWidget {
  final Notebook notebook;
  const _NewPageSheet({required this.notebook});

  @override
  State<_NewPageSheet> createState() => _NewPageSheetState();
}

class _NewPageSheetState extends State<_NewPageSheet> {
  PageType _selectedType = PageType.plain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.newPageTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(l10n.choosePageStyle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypeOption(
                label: l10n.pageStylePlain,
                icon: Icons.description_outlined,
                isSelected: _selectedType == PageType.plain,
                onTap: () => setState(() => _selectedType = PageType.plain),
              ),
              _TypeOption(
                label: l10n.pageStyleRuled,
                icon: Icons.view_headline_rounded,
                isSelected: _selectedType == PageType.ruled,
                onTap: () => setState(() => _selectedType = PageType.ruled),
              ),
              _TypeOption(
                label: l10n.pageStyleGrid,
                icon: Icons.grid_4x4_rounded,
                isSelected: _selectedType == PageType.grid,
                onTap: () => setState(() => _selectedType = PageType.grid),
              ),
              _TypeOption(
                label: l10n.pageStyleDotted,
                icon: Icons.more_horiz_rounded,
                isSelected: _selectedType == PageType.dotted,
                onTap: () => setState(() => _selectedType = PageType.dotted),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.notebook.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(
                      notebookId: widget.notebook.id,
                      pageType: _selectedType,
                    ),
                  ),
                );
              },
              child: Text(l10n.startWriting),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
