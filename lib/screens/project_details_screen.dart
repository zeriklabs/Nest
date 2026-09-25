import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:nest/l10n/app_localizations.dart';
import '../models/project.dart';
import '../services/data_service.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;
  final VoidCallback? onBack;

  const ProjectDetailsScreen({super.key, required this.projectId, this.onBack});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> with SingleTickerProviderStateMixin {
  final _taskController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addNewTask(String projectId, DataService dataService, {String? assignedTo}) {
    if (_taskController.text.trim().isEmpty) return;

    final project = dataService.projects.firstWhereOrNull((p) => p.id == projectId);
    if (project == null) return;
    final currentPhase = project.currentPhase;
    if (currentPhase == null) return;

    final newTask = ProjectTask(
      id: const Uuid().v4(),
      title: _taskController.text.trim(),
      assignedTo: assignedTo,
    );

    final updatedPhases = List<ProjectPhase>.from(project.phases);
    final updatedTasks = List<ProjectTask>.from(currentPhase.tasks)..add(newTask);
    updatedPhases[project.currentPhaseIndex] = currentPhase.copyWith(tasks: updatedTasks);

    // Recalculate global progress
    int totalTasks = 0;
    int completedTasks = 0;
    for (var phase in updatedPhases) {
      totalTasks += phase.tasks.length;
      completedTasks += phase.tasks.where((t) => t.isCompleted).length;
    }
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    dataService.updateProject(project.copyWith(
      phases: updatedPhases,
      progress: progress,
    ));

    _taskController.clear();
    setState(() {});
  }

  void _showFinishPhaseDialog(Project project, DataService dataService) {
    final l10n = AppLocalizations.of(context)!;
    final nextPhaseController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.finishPhase),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.finishPhaseConfirm(project.currentPhase?.title ?? '')),
            const SizedBox(height: 16),
            TextField(
              controller: nextPhaseController,
              decoration: InputDecoration(
                labelText: l10n.nextPhaseLabel,
                hintText: l10n.nextPhaseHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              dataService.finishCurrentPhase(project.id, nextPhaseController.text.trim());
              Navigator.pop(context);
            },
            child: Text(l10n.finish),
          ),
        ],
      ),
    );
  }

  void _showFinishProjectDialog(Project project, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Proyecto'),
        content: const Text('¿Estás seguro de que quieres dar por terminado este proyecto? El progreso se marcará al 100%.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              dataService.finishProject(project.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Completar Proyecto'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate(Project project, DataService dataService) async {
    if (!project.canEditStartDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya ha pasado el tiempo límite (1 día) para editar la fecha de inicio.')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: project.startDate,
      firstDate: DateTime(2000),
      lastDate: project.endDate ?? DateTime(2100),
    );

    if (picked != null) {
      dataService.updateProject(project.copyWith(startDate: picked));
    }
  }

  Future<void> _pickEndDate(Project project, DataService dataService) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: project.endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: project.startDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      dataService.updateProject(project.copyWith(endDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final project = dataService.projects.firstWhereOrNull((p) => p.id == widget.projectId);

    if (project == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.maybePop(context);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currentPhaseTasks = project.currentPhase?.tasks ?? [];
    final bool isCompleted = project.status == ProjectStatus.completed;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null 
          ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: widget.onBack)
          : null,
        title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!isCompleted && !project.isArchived)
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
              tooltip: 'Finalizar Proyecto',
              onPressed: () => _showFinishProjectDialog(project, dataService),
            ),
        ],
        bottom: project.isIndependent 
          ? null 
          : TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tareas'),
                Tab(text: 'Equipo'),
              ],
            ),
      ),
      body: project.isIndependent 
        ? _buildTasksList(currentPhaseTasks, project, dataService, colorScheme, isDark)
        : TabBarView(
            controller: _tabController,
            children: [
              _buildTasksList(currentPhaseTasks, project, dataService, colorScheme, isDark),
              _buildMembersTaskView(project, dataService, colorScheme, isDark),
            ],
          ),
      bottomNavigationBar: isCompleted || project.isArchived ? null : _buildAddTaskInput(project, dataService, colorScheme, isDark),
    );
  }

  Widget _buildProjectHeader(Project project, ColorScheme colorScheme, bool isDark) {
    final df = DateFormat('dd MMM yyyy');
    final dataService = Provider.of<DataService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: project.isArchived 
                    ? Colors.grey.withOpacity(0.1)
                    : (project.isIndependent ? Colors.orange : colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.isArchived ? l10n.archived : (project.isIndependent ? l10n.individual : l10n.groupLabelShort),
                  style: TextStyle(
                    color: project.isArchived ? Colors.grey : (project.isIndependent ? Colors.orange : colorScheme.primary),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l10n.completedPercentage((project.progress * 100).toInt()),
                style: TextStyle(
                  color: project.status == ProjectStatus.completed ? Colors.green : colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 10,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(project.status == ProjectStatus.completed ? Colors.green : colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          if (project.currentPhase != null && project.status != ProjectStatus.completed && !project.isArchived) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FASE ACTUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(project.currentPhase!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showFinishPhaseDialog(project, dataService),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Terminar Fase', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    foregroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _pickStartDate(project, dataService),
                child: _buildDateInfo(
                  'INICIO', 
                  df.format(project.startDate), 
                  Icons.play_arrow_rounded,
                  isDark,
                  editable: project.canEditStartDate,
                ),
              ),
              GestureDetector(
                onTap: () => _pickEndDate(project, dataService),
                child: _buildDateInfo(
                  'CIERRE', 
                  project.endDate != null ? df.format(project.endDate!) : 'Sin definir', 
                  Icons.flag_rounded,
                  isDark,
                  editable: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date, IconData icon, bool isDark, {bool editable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
            if (editable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 10, color: Colors.grey),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildTasksList(List<ProjectTask> tasks, Project project, DataService dataService, ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: tasks.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _buildProjectHeader(project, colorScheme, isDark);
        if (index == 1) return const Divider(height: 1);
        
        final task = tasks[index - 2];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            elevation: 0,
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: project.status == ProjectStatus.completed || project.isArchived 
                  ? null 
                  : (_) => dataService.toggleTaskInProject(project.id, task.id),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                activeColor: colorScheme.primary,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: !project.isIndependent && task.assignedTo != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.assignedTo!,
                      style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskInput(Project project, DataService dataService, ColorScheme colorScheme, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final members = project.members;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!project.isIndependent && members.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: CircleAvatar(radius: 10, child: Text(member[0], style: const TextStyle(fontSize: 10))),
                          label: Text(member, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            _addNewTask(project.id, dataService, assignedTo: member);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: l10n.addTaskHint,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addNewTask(project.id, dataService),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'project_details_fab',
                  onPressed: () => _addNewTask(project.id, dataService),
                  elevation: 0,
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTaskView(Project project, DataService dataService, ColorScheme colorScheme, bool isDark) {
    final members = project.members;
    
    if (members.isEmpty) {
      return const Center(child: Text('No hay miembros en este equipo.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final memberTasks = project.tasks.where((t) => t.assignedTo == member).toList();
        final completedCount = memberTasks.where((t) => t.isCompleted).length;
        final progress = memberTasks.isEmpty ? 0.0 : completedCount / memberTasks.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(member[0], style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(member, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: colorScheme.primary.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$completedCount de ${memberTasks.length} tareas terminadas', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: memberTasks.isEmpty 
                    ? [const Text('Sin tareas asignadas', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))]
                    : memberTasks.map((task) => CheckboxListTile(
                        value: task.isCompleted,
                        onChanged: project.status == ProjectStatus.completed || project.isArchived
                          ? null 
                          : (_) => dataService.toggleTaskInProject(project.id, task.id),
                        title: Text(task.title, style: TextStyle(
                          fontSize: 14,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        )),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
