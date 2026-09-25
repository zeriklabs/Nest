import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/reminder.dart';
import '../services/data_service.dart';
import '../models/group.dart';
import '../models/recurrence.dart';

class AddReminderScreen extends StatefulWidget {
  final Reminder? reminderToEdit;
  final DateTime? initialDate;
  final List<String>? initialSharedWith;
  const AddReminderScreen({super.key, this.reminderToEdit, this.initialDate, this.initialSharedWith});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  final TextEditingController _searchController = TextEditingController();

  late DateTime _selectedDate;
  late DateTime? _selectedEndDate;
  late TimeOfDay _selectedTime;
  TimeOfDay? _selectedEndTime;
  late String _selectedCategory;
  String _selectedRepeat = 'Nunca';
  RecurrenceConfig? _recurrenceConfig;
  String? _selectedSubjectId;
  late bool _isUrgent;
  late bool _isAllDay;
  
  final List<String> _categories = ['Recordatorio', 'Tarea', 'Proyecto', 'Examen', 'Evento'];
  final List<String> _earlyAlerts = ['15 min antes'];
  
  // Mock users for sharing
  final List<String> _allContacts = ['Javier', 'María García', 'Carlos Pérez', 'Ana López', 'Luis Martínez', 'Sofía Rodríguez'];
  final List<String> _selectedContacts = [];
  final List<String> _attachments = [];
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    final edit = widget.reminderToEdit;
    
    _titleController = TextEditingController(text: edit?.title ?? '');
    _locationController = TextEditingController(text: edit?.location ?? '');
    _descriptionController = TextEditingController(text: edit?.description ?? '');
    
    _selectedDate = edit?.dateTime ?? widget.initialDate ?? DateTime.now();
    _selectedEndDate = edit?.endDate;
    _selectedTime = TimeOfDay.fromDateTime(edit?.dateTime ?? DateTime.now());
    if (edit?.endDate != null) {
      _selectedEndTime = TimeOfDay.fromDateTime(edit!.endDate!);
    }
    _selectedCategory = edit?.category ?? 'Recordatorio';
    _isUrgent = edit?.isUrgent ?? false;
    _isAllDay = edit?.isAllDay ?? false;
    
    if (edit?.sharedWith != null) {
      _selectedContacts.addAll(edit!.sharedWith);
    } else if (widget.initialSharedWith != null) {
      _selectedContacts.addAll(widget.initialSharedWith!);
    }
    
    if (edit?.attachments != null) {
      _attachments.addAll(edit!.attachments);
    }
    
    _selectedSubjectId = edit?.subjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    final results = _allContacts
        .where((c) => c.toLowerCase().contains(query.toLowerCase()))
        .where((c) => !_selectedContacts.contains(c))
        .toList();
    
    setState(() => _searchResults = results);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedDate.add(const Duration(days: 1)),
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedEndDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay(hour: (_selectedTime.hour + 1) % 24, minute: _selectedTime.minute),
    );
    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF050505) : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark, colorScheme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTitleInput(isDark, l10n),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(child: _buildDateTimePicker(l10n.date, DateFormat('dd/MM/yyyy', l10n.localeName).format(_selectedDate), Icons.calendar_today_rounded, _selectDate, isDark)),
                          if (_selectedCategory == 'Evento') ...[
                            const SizedBox(width: 16),
                            Expanded(child: _buildDateTimePicker(l10n.endDate, _selectedEndDate == null ? 'Opcional' : DateFormat('dd/MM/yyyy', l10n.localeName).format(_selectedEndDate!), Icons.calendar_month_rounded, _selectEndDate, isDark)),
                          ],
                        ],
                      ),
                      if (_selectedCategory == 'Evento') ...[
                        const SizedBox(height: 16),
                        _buildAllDayToggle(isDark, colorScheme, l10n),
                      ],
                      if (!_isAllDay) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildDateTimePicker(l10n.startTime, _selectedTime.format(context), Icons.access_time_rounded, _selectTime, isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDateTimePicker(l10n.endTime, _selectedEndTime == null ? 'Opcional' : _selectedEndTime!.format(context), Icons.access_time_filled_rounded, _selectEndTime, isDark)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 25),
                      _buildSectionLabel(l10n.place, isDark),
                      _buildIconInput(_locationController, l10n.locationHint, Icons.location_on_outlined, isDark),
                      const SizedBox(height: 25),
                      _buildSectionLabel(l10n.categoryLabel, isDark),
                      _buildCategoryChips(colorScheme, isDark, l10n),
                      const SizedBox(height: 25),
                      _buildSectionLabel(l10n.linkSubject, isDark),
                      _buildSubjectTags(isDark, colorScheme, l10n),
                      const SizedBox(height: 25),
                      _buildSectionLabel(l10n.repeat, isDark),
                      _buildSelector(_selectedRepeat == 'Nunca' ? l10n.never : _selectedRepeat, Icons.sync_rounded, () {
                        _showRecurrencePicker(context, isDark, colorScheme, l10n);
                      }, isDark),
                      const SizedBox(height: 25),
                      _buildSectionLabel(l10n.earlyAlerts, isDark),
                      _buildAlertChips(colorScheme, isDark, l10n),
                      const SizedBox(height: 25),
                      _buildSectionLabel(l10n.description, isDark),
                      _buildDescriptionInput(isDark, colorScheme, l10n),
                      const SizedBox(height: 25),
                      /*
                      _buildSectionLabel(l10n.shareWithOthers, isDark),
                      if (_searchResults.isNotEmpty) _buildSearchResults(isDark, colorScheme),
                      if (_selectedContacts.isNotEmpty) _buildSelectedContacts(isDark, colorScheme),
                      _buildShareSearchBar(isDark, colorScheme, l10n),
                      const SizedBox(height: 25),
                      */
                      _buildUrgentToggle(isDark, colorScheme, l10n),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          ),
          Text(
            widget.reminderToEdit != null ? l10n.editReminder : l10n.newReminder,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterTitle)),
                );
                return;
              }

              final dataService = Provider.of<DataService>(context, listen: false);
              
              if (_recurrenceConfig != null && widget.reminderToEdit == null) {
                // Handle Recurring Program
                final program = RecurringProgram(
                  id: const Uuid().v4(),
                  title: title,
                  category: _selectedCategory,
                  location: _locationController.text.trim(),
                  description: _descriptionController.text.trim(),
                  subjectId: _selectedSubjectId,
                  config: _recurrenceConfig!,
                  startDate: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                  isUrgent: _isUrgent,
                );
                dataService.addRecurringProgram(program);
              } else {
                // Handle Single Reminder
                final finalDateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _isAllDay ? 0 : _selectedTime.hour,
                  _isAllDay ? 0 : _selectedTime.minute,
                );

                DateTime? finalEndDateTime;
                if (_selectedEndDate != null || _selectedEndTime != null) {
                  final refDate = _selectedEndDate ?? _selectedDate;
                  final endHour = _selectedEndTime?.hour ?? (_isAllDay ? 23 : (_selectedTime.hour + 1) % 24);
                  final endMinute = _selectedEndTime?.minute ?? (_isAllDay ? 59 : _selectedTime.minute);
                  finalEndDateTime = DateTime(
                    refDate.year,
                    refDate.month,
                    refDate.day,
                    endHour,
                    endMinute,
                  );
                }

                String? formattedTimeString;
                if (!_isAllDay) {
                  final startTimeStr = _selectedTime.format(context);
                  if (_selectedEndTime != null) {
                    final endTimeStr = _selectedEndTime!.format(context);
                    formattedTimeString = '$startTimeStr - $endTimeStr';
                  } else {
                    formattedTimeString = startTimeStr;
                  }
                }

                final reminder = Reminder(
                  id: widget.reminderToEdit?.id ?? const Uuid().v4(),
                  author: dataService.userId ?? dataService.userName,
                  title: title,
                  date: DateFormat('dd/MM/yyyy', l10n.localeName).format(_selectedDate),
                  time: formattedTimeString,
                  category: _selectedCategory,
                  location: _locationController.text.trim(),
                  description: _descriptionController.text.trim(),
                  subjectId: _selectedSubjectId,
                  sharedWith: _selectedContacts,
                  attachments: _attachments,
                  isUrgent: _isUrgent,
                  isAllDay: _isAllDay,
                  endDate: finalEndDateTime,
                  isCompleted: widget.reminderToEdit?.isCompleted ?? false,
                  completedAt: widget.reminderToEdit?.completedAt,
                  dateTime: finalDateTime,
                );

                if (widget.reminderToEdit != null) {
                  dataService.updateReminder(reminder);
                } else {
                  dataService.addReminder(reminder);
                  
                  // Share with groups if selected (Temporarily disabled)
                  /*
                  for (var contact in _selectedContacts) {
                    final group = dataService.groups.where((g) => g.name == contact).firstOrNull;
                    if (group != null) {
                      dataService.addReminderToGroup(group.id, reminder);
                    }
                  }
                  */
                }
              }
              Navigator.pop(context, true);
            },
            child: Text(
              l10n.save,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTitleInput(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: TextField(
        controller: _titleController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: l10n.enterTitle,
          hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(String label, String value, IconData icon, VoidCallback onTap, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, isDark),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconInput(TextEditingController controller, String hint, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
          prefixIcon: Icon(icon, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    final List<String> translatedCategories = [
      l10n.reminder,
      l10n.task,
      l10n.project,
      l10n.exam,
      l10n.event,
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final label = translatedCategories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = cat);
              },
              selectedColor: colorScheme.primary.withOpacity(0.2),
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelector(String value, IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertChips(ColorScheme colorScheme, bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        ..._earlyAlerts.map((alert) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert, style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Icon(Icons.close_rounded, size: 16, color: colorScheme.primary),
            ],
          ),
        )),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Text(
              l10n.addAlert,
              style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
            decoration: InputDecoration(
              hintText: l10n.writeNoteHint,
              hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            ),
          ),
          if (_attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _attachments.map((path) {
                  final fileName = path.split('/').last;
                  final isImage = ['.jpg', '.jpeg', '.png'].any((ext) => fileName.toLowerCase().endsWith(ext));
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined, 
                          size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            fileName,
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _attachments.remove(path)),
                          child: Icon(Icons.close_rounded, size: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _pickFiles,
                    icon: Icon(Icons.attach_file_rounded, 
                      size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: _takePhoto,
                    icon: Icon(Icons.add_a_photo_outlined, 
                      size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.paths.whereType<String>());
      });
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _attachments.add(photo.path);
      });
    }
  }

  Widget _buildShareSearchBar(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      key: const ValueKey('share_search_field_container'),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: TextField(
        key: const ValueKey('share_search_field'),
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
        decoration: InputDecoration(
          hintText: l10n.searchUsersHint,
          hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF121212) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final contact = _searchResults[index];
          final dataService = Provider.of<DataService>(context, listen: false);
          final isGroup = dataService.groups.any((g) => g.name == contact);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isGroup ? Colors.blue.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
              child: Icon(
                isGroup ? Icons.groups_rounded : Icons.person_rounded,
                size: 18,
                color: isGroup ? Colors.blue : colorScheme.primary,
              ),
            ),
            title: Text(contact, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            onTap: () {
              setState(() {
                _selectedContacts.add(contact);
                _searchResults.remove(contact);
                _searchController.clear();
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedContacts(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedContacts.map((contact) {
          final dataService = Provider.of<DataService>(context, listen: false);
          final isGroup = dataService.groups.any((g) => g.name == contact);
          
          return Chip(
            avatar: CircleAvatar(
              backgroundColor: isGroup ? Colors.blue : colorScheme.primary,
              child: Icon(
                isGroup ? Icons.groups_rounded : Icons.person_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
            label: Text(contact, style: const TextStyle(fontSize: 12)),
            onDeleted: () {
              setState(() {
                _selectedContacts.remove(contact);
              });
            },
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            backgroundColor: (isGroup ? Colors.blue : colorScheme.primary).withOpacity(0.1),
            side: BorderSide(color: (isGroup ? Colors.blue : colorScheme.primary).withOpacity(0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectTags(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    final subjects = context.watch<DataService>().subjects;
    
    if (subjects.isEmpty) {
      return Text(
        l10n.noSubjectsYet,
        style: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), fontSize: 13),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final isSelected = _selectedSubjectId == subject.id;
          final tagName = _getTagName(subject.name);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('#$tagName'),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedSubjectId = val ? subject.id : null;
                });
              },
              selectedColor: subject.color.withOpacity(0.2),
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
              labelStyle: TextStyle(
                color: isSelected ? subject.color : (isDark ? Colors.white : Colors.black).withOpacity(0.4),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? subject.color.withOpacity(0.4) : Colors.transparent,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  String _getTagName(String name) {
    if (name.length <= 15) return name;
    
    // Create abbreviation
    final words = name.split(' ');
    if (words.length == 1) return name.substring(0, 8);
    
    return words
        .where((w) => w.length > 2) // Ignore small words like "de", "la"
        .map((w) => w[0].toUpperCase())
        .join();
  }

  Widget _buildUrgentToggle(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
          const SizedBox(width: 12),
          Text(
            l10n.markAsUrgent,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Switch(
            value: _isUrgent,
            onChanged: (val) => setState(() => _isUrgent = val),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showRecurrencePicker(BuildContext context, bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return _RecurrenceConfigurationSheet(
          initialConfig: _recurrenceConfig,
          onSave: (config) {
            setState(() {
              _recurrenceConfig = config;
              _selectedRepeat = config?.humanReadable ?? l10n.never;
            });
          },
        );
      },
    );
  }

  Widget _buildAllDayToggle(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.today_rounded, size: 20, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
          const SizedBox(width: 12),
          Text(
            l10n.allDay,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Switch(
            value: _isAllDay,
            onChanged: (val) => setState(() => _isAllDay = val),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _RecurrenceConfigurationSheet extends StatefulWidget {
  final RecurrenceConfig? initialConfig;
  final Function(RecurrenceConfig?) onSave;

  const _RecurrenceConfigurationSheet({this.initialConfig, required this.onSave});

  @override
  State<_RecurrenceConfigurationSheet> createState() => _RecurrenceConfigurationSheetState();
}

class _RecurrenceConfigurationSheetState extends State<_RecurrenceConfigurationSheet> {
  late RecurrenceFrequency _frequency;
  late int _interval;
  List<TimeOfDay> _times = [];
  DateTime? _endDate;
  int? _occurrences;
  List<int> _daysOfWeek = []; // 1-7
  bool _useSpecificTimes = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _frequency = widget.initialConfig!.frequency;
      _interval = widget.initialConfig!.interval;
      _times = List.from(widget.initialConfig!.timesOfDay ?? []);
      _endDate = widget.initialConfig!.endDate;
      _occurrences = widget.initialConfig!.occurrences;
      _daysOfWeek = List.from(widget.initialConfig!.daysOfWeek ?? []);
      _useSpecificTimes = _times.isNotEmpty;
    } else {
      _frequency = RecurrenceFrequency.daily;
      _interval = 1;
      _useSpecificTimes = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 12, 28, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 4.5,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(l10n.setupRepeat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20),
            _buildFrequencySelector(isDark, colorScheme, l10n),
            const SizedBox(height: 25),
            
            if (_frequency == RecurrenceFrequency.hourly || _frequency == RecurrenceFrequency.daily) ...[
              _buildMethodSelector(isDark, colorScheme, l10n),
              const SizedBox(height: 20),
            ],

            if (_useSpecificTimes)
              _buildTimesSection(isDark, colorScheme, l10n)
            else
              _buildIntervalInput(isDark, colorScheme, l10n),

            if (_frequency == RecurrenceFrequency.weekly) ...[
              const SizedBox(height: 20),
              _buildDaysOfWeekSelector(isDark, colorScheme, l10n),
            ],
            
            const SizedBox(height: 25),
            _buildEndConditionSection(isDark, colorScheme, l10n),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.onSave(null);
                      Navigator.pop(context);
                    },
                    child: Text(l10n.removeRepeat, style: TextStyle(color: Colors.redAccent.withOpacity(0.6))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(RecurrenceConfig(
                        frequency: _frequency,
                        interval: _useSpecificTimes ? 1 : _interval,
                        timesOfDay: _useSpecificTimes && _times.isNotEmpty ? _times : null,
                        endDate: _endDate,
                        occurrences: _occurrences,
                        daysOfWeek: _daysOfWeek.isNotEmpty ? _daysOfWeek : null,
                      ));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.scheduleType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildMethodChip(l10n.fixedInterval, !_useSpecificTimes, colorScheme, isDark, () => setState(() => _useSpecificTimes = false)),
            const SizedBox(width: 12),
            _buildMethodChip(l10n.specificHours, _useSpecificTimes, colorScheme, isDark, () => setState(() => _useSpecificTimes = true)),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodChip(String label, bool isSelected, ColorScheme colorScheme, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? colorScheme.primary : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : (isDark ? Colors.white60 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfWeekSelector(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    final days = [l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat]; // Sun is index 0 in some calendars but weekday 7 in DateTime? Let's check Recurrence logic.
    // In Recurrence logic: weekday 1 is Monday.
    final List<String> weekLabels = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.repeatOnDays, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            Row(
              children: [
                _buildSmallPreset(l10n.monFri, () => setState(() => _daysOfWeek = [1, 2, 3, 4, 5]), colorScheme),
                const SizedBox(width: 8),
                _buildSmallPreset(l10n.weekend, () => setState(() => _daysOfWeek = [6, 7]), colorScheme),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayNum = index + 1;
            final isSelected = _daysOfWeek.contains(dayNum);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _daysOfWeek.remove(dayNum);
                  } else {
                    _daysOfWeek.add(dayNum);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    weekLabels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSmallPreset(String label, VoidCallback onTap, ColorScheme colorScheme) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEndConditionSection(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.ends, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.neverEnd, style: const TextStyle(fontSize: 14)),
          leading: Radio<int>(
            value: 0,
            groupValue: _endDate != null ? 1 : (_occurrences != null ? 2 : 0),
            onChanged: (val) => setState(() { _endDate = null; _occurrences = null; }),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Text(l10n.onDay, style: const TextStyle(fontSize: 14)),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() { _endDate = picked; _occurrences = null; });
                },
                child: Text(_endDate != null ? DateFormat('dd/MM/yyyy', l10n.localeName).format(_endDate!) : l10n.selectDate),
              ),
            ],
          ),
          leading: Radio<int>(
            value: 1,
            groupValue: _endDate != null ? 1 : (_occurrences != null ? 2 : 0),
            onChanged: (val) => setState(() { _endDate = DateTime.now().add(const Duration(days: 7)); _occurrences = null; }),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Text(l10n.after, style: const TextStyle(fontSize: 14)),
              SizedBox(
                width: 50,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (val) => setState(() => _occurrences = int.tryParse(val)),
                ),
              ),
              Text(l10n.times, style: const TextStyle(fontSize: 14)),
            ],
          ),
          leading: Radio<int>(
            value: 2,
            groupValue: _endDate != null ? 1 : (_occurrences != null ? 2 : 0),
            onChanged: (val) => setState(() { _occurrences = 10; _endDate = null; }),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.frequency, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: RecurrenceFrequency.values.map((f) {
            final isSelected = _frequency == f;
            String label = '';
            switch (f) {
              case RecurrenceFrequency.hourly: label = l10n.hours; break;
              case RecurrenceFrequency.daily: label = l10n.days; break;
              case RecurrenceFrequency.weekly: label = l10n.weeks; break;
              case RecurrenceFrequency.monthly: label = l10n.months; break;
              case RecurrenceFrequency.yearly: label = l10n.years; break;
            }
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) => setState(() => _frequency = f),
              selectedColor: colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? colorScheme.primary : (isDark ? Colors.white60 : Colors.black54)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntervalInput(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    String unit = '';
    switch (_frequency) {
      case RecurrenceFrequency.hourly: unit = _interval == 1 ? l10n.hour : l10n.hours.toLowerCase(); break;
      case RecurrenceFrequency.daily: unit = _interval == 1 ? l10n.day : l10n.days.toLowerCase(); break;
      case RecurrenceFrequency.weekly: unit = _interval == 1 ? l10n.week : l10n.weeks.toLowerCase(); break;
      case RecurrenceFrequency.monthly: unit = _interval == 1 ? l10n.month : l10n.months.toLowerCase(); break;
      case RecurrenceFrequency.yearly: unit = _interval == 1 ? l10n.year : l10n.years.toLowerCase(); break;
    }

    return Row(
      children: [
        Text(l10n.repeatEvery, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 16),
        SizedBox(
          width: 50,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _interval = int.tryParse(val) ?? 1),
            controller: TextEditingController(text: _interval.toString())..selection = TextSelection.fromPosition(TextPosition(offset: _interval.toString().length)),
          ),
        ),
        const SizedBox(width: 12),
        Text(unit, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildTimesSection(bool isDark, ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.specificSchedules, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
              onPressed: () async {
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null) setState(() => _times.add(time));
              },
            ),
          ],
        ),
        if (_times.isEmpty)
          Text(l10n.defaultTimeMsg, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            children: _times.map((t) => Chip(
              label: Text(t.format(context)),
              onDeleted: () => setState(() => _times.remove(t)),
              deleteIcon: const Icon(Icons.close, size: 14),
            )).toList(),
          ),
      ],
    );
  }
}
