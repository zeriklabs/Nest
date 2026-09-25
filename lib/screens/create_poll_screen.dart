import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nest/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/group_poll.dart';
import '../services/data_service.dart';

class CreatePollScreen extends StatefulWidget {
  final String groupId;

  const CreatePollScreen({super.key, required this.groupId});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();
  
  Duration? _selectedDuration;
  final List<Map<String, dynamic>> _durations = [
    {'label': '1 hora', 'duration': const Duration(hours: 1)},
    {'label': '12 horas', 'duration': const Duration(hours: 12)},
    {'label': '1 día', 'duration': const Duration(days: 1)},
    {'label': '3 días', 'duration': const Duration(days: 3)},
    {'label': '7 días', 'duration': const Duration(days: 7)},
    {'label': 'Sin límite', 'duration': null},
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 7) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  void _submit() {
    final question = _questionController.text.trim();
    final validOptions = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (question.isEmpty || validOptions.length < 2) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pollMinOptionsError)),
      );
      return;
    }

    final dataService = Provider.of<DataService>(context, listen: false);
    final poll = GroupPoll(
      id: const Uuid().v4(),
      author: dataService.userName,
      question: question,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      images: _imagePaths,
      options: validOptions.map((text) => PollOption(text: text)).toList(),
      timestamp: DateTime.now(),
      expiresAt: _selectedDuration != null ? DateTime.now().add(_selectedDuration!) : null,
    );

    dataService.addPollToGroup(widget.groupId, poll);
    Navigator.pop(context, poll);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newPoll, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text(l10n.create, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('PREGUNTA', isDark),
            TextField(
              controller: _questionController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '¿Qué quieres preguntar?',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('DESCRIPCIÓN (OPCIONAL)', isDark),
            TextField(
              controller: _descriptionController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Añade más contexto...',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionLabel('DURACIÓN DE LA VOTACIÓN', isDark),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _durations.length,
                itemBuilder: (context, index) {
                  final item = _durations[index];
                  final isSelected = _selectedDuration == item['duration'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item['label']),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedDuration = item['duration']);
                      },
                      selectedColor: colorScheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? colorScheme.primary : (isDark ? Colors.white60 : Colors.black54),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            if (_imagePaths.isNotEmpty) ...[
              _buildSectionLabel('IMÁGENES', isDark),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      return _buildAddImageButton(colorScheme, isDark);
                    }
                    return _buildImageItem(index);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(l10n.addImages),
              ),
              const SizedBox(height: 16),
            ],
            _buildSectionLabel(l10n.options, isDark),
            const SizedBox(height: 12),
            ..._optionControllers.asMap().entries.map((entry) => _buildOptionInput(entry.key, entry.value, colorScheme, isDark)),
            if (_optionControllers.length < 7)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addOption),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildOptionInput(int index, TextEditingController controller, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Opción ${index + 1}',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_optionControllers.length > 2)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.redAccent),
                onPressed: () => _removeOption(index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: kIsWeb ? NetworkImage(_imagePaths[index]) : FileImage(File(_imagePaths[index])) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _imagePaths.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton(ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Icon(Icons.add_a_photo_rounded, color: colorScheme.primary.withOpacity(0.5)),
      ),
    );
  }
}
