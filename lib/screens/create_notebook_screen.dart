import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/notebook.dart';
import '../services/data_service.dart';

class CreateNotebookScreen extends StatefulWidget {
  const CreateNotebookScreen({super.key});

  @override
  State<CreateNotebookScreen> createState() => _CreateNotebookScreenState();
}

class _CreateNotebookScreenState extends State<CreateNotebookScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF6366F1);
  IconData _selectedIcon = Icons.book_rounded;

  final List<IconData> _availableIcons = [
    Icons.book_rounded,
    Icons.school_rounded,
    Icons.rocket_launch_rounded,
    Icons.favorite_rounded,
    Icons.lightbulb_rounded,
    Icons.work_rounded,
    Icons.brush_rounded,
    Icons.code_rounded,
    Icons.travel_explore_rounded,
    Icons.fitness_center_rounded,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Orange
    const Color(0xFFEF4444), // Red
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF71717A), // Zinc
    const Color(0xFF451a03), // Brown
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveNotebook() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterNotebookName)),
      );
      return;
    }

    final notebook = Notebook(
      id: const Uuid().v4(),
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
      createdAt: DateTime.now(),
    );

    Provider.of<DataService>(context, listen: false).addNotebook(notebook);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newNotebook),
        actions: [
          TextButton(
            onPressed: _saveNotebook,
            child: Text(l10n.createLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview de la libreta
            Center(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 120,
                    height: 150,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Lomo de la libreta
                        Container(
                          width: 12,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(_selectedIcon, color: Colors.white, size: 40),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text.isEmpty ? l10n.myNewNotebook : _nameController.text,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            Text(l10n.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.notebookNameHint,
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            Text(l10n.chooseIcon, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _selectedColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: isSelected ? _selectedColor : (isDark ? Colors.white60 : Colors.black45)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            Text(l10n.coverColor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
