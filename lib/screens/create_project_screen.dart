import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/project.dart';
import '../services/data_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String? _selectedGroupId;
  bool _isIndependent = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: start ? DateTime(2000) : _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterProjectTitleError)),
      );
      return;
    }

    final dataService = Provider.of<DataService>(context, listen: false);
    final userId = dataService.userId;
    if (userId == null) return;

    final newProject = Project(
      id: Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      createdAt: DateTime.now(),
      isIndependent: _isIndependent,
      groupId: _isIndependent ? null : _selectedGroupId,
      members: _isIndependent ? [userId] : (dataService.groups.where((g) => g.id == _selectedGroupId).firstOrNull?.members ?? []),
      phases: [
        ProjectPhase(id: Uuid().v4(), title: AppLocalizations.of(context)!.initialPhase, tasks: []),
      ],
    );

    dataService.addProject(newProject);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataService = Provider.of<DataService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newProject, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(l10n.projectTitleLabel),
            TextField(
              controller: _titleController,
              autofocus: false,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: l10n.projectTitleHint,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel(l10n.descriptionLabel),
            TextField(
              controller: _descriptionController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: l10n.descriptionHint,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 30),
            _buildLabel(l10n.projectTypeLabel),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    l10n.personal, 
                    Icons.person_outline_rounded, 
                    _isIndependent, 
                    () => setState(() => _isIndependent = true),
                    colorScheme
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTypeCard(
                    l10n.groupLabel, 
                    Icons.groups_rounded, 
                    !_isIndependent, 
                    () => setState(() => _isIndependent = false),
                    colorScheme
                  ),
                ),
              ],
            ),
            if (!_isIndependent) ...[
              const SizedBox(height: 20),
              _buildLabel(l10n.selectGroupLabel),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGroupId,
                    hint: Text(l10n.chooseGroupHint),
                    items: dataService.groups.map((group) {
                      return DropdownMenuItem(
                        value: group.id,
                        child: Text(group.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedGroupId = val),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
            _buildLabel(l10n.dates),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePickerTile(
                    l10n.start, 
                    DateFormat('dd/MM/yyyy', l10n.localeName).format(_startDate), 
                    () => _selectDate(true),
                    isDark
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePickerTile(
                    l10n.endOptional, 
                    _endDate != null ? DateFormat('dd/MM/yyyy', l10n.localeName).format(_endDate!) : l10n.undefined, 
                    () => _selectDate(false),
                    isDark
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(l10n.createProject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTypeCard(String label, IconData icon, bool isSelected, VoidCallback onTap, ColorScheme colorScheme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? colorScheme.primary : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(String label, String value, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
