import 'package:flutter/material.dart';

import '../../../core/widgets/glass_panel.dart';
import '../../../data/services/api_service.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_stats.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _search = TextEditingController();

  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = await ApiService.instance.getTasks(
        search: _search.text,
        completed: _filter == 'Completed'
            ? true
            : _filter == 'Pending'
                ? false
                : null,
      );

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? task}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171C30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => TaskFormSheet(
        initialTask: task,
        onSave: ({
          required String title,
          required String subject,
          String? dueDate,
          required String priority,
        }) async {
          if (task == null) {
            await ApiService.instance.createTask(
              title: title,
              subject: subject,
              dueDate: dueDate,
              priority: priority,
            );
          } else {
            final id = _taskId(task);
            if (id == null) {
              throw Exception('This task has no ID, so it cannot be edited.');
            }
            await ApiService.instance.updateTask(
              id,
              title: title,
              subject: subject,
              dueDate: dueDate,
              priority: priority,
            );
          }
        },
      ),
    );

    if (result == true && mounted) await _loadTasks();
  }

  String? _taskId(Map<String, dynamic> task) {
    final id = task['id'] ?? task['taskId'] ?? task['task_id'];
    return id?.toString();
  }

  Future<void> _toggleTask(Map<String, dynamic> task, bool completed) async {
    final id = _taskId(task);
    if (id == null) {
      _showMessage('This task has no ID in the server response.');
      return;
    }

    final oldValue = task['completed'] == true;

    setState(() {
      task['completed'] = completed;
    });

    try {
      await ApiService.instance.updateTask(id, completed: completed);
      await _loadTasks();
    } catch (error) {
      if (!mounted) return;
      setState(() => task['completed'] = oldValue);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final id = _taskId(task);
    if (id == null) {
      _showMessage('This task has no ID in the server response.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202640),
        title: const Text('Delete task?'),
        content: Text('Delete "${task['title'] ?? 'this task'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.instance.deleteTask(id);
      if (mounted) await _loadTasks();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((task) => task['completed'] == true).length;
    final pending = _tasks.length - completed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            onPressed: _loading ? null : _loadTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF8797FF),
        foregroundColor: const Color(0xFF111629),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTasks,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              const Text(
                'Make progress, one task at a time.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              TaskStats(
                total: _tasks.length,
                completed: completed,
                pending: pending,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _search,
                onSubmitted: (_) => _loadTasks(),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _loadTasks,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: ['All', 'Pending', 'Completed'].map((filter) {
                  return ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) {
                      setState(() => _filter = filter);
                      _loadTasks();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8797FF),
                    ),
                  ),
                )
              else if (_error != null)
                GlassPanel(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 36,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadTasks,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (_tasks.isEmpty)
                const GlassPanel(
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        size: 42,
                        color: Color(0xFFB7C1FF),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nothing here yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Add a task to get your study plan started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                )
              else
                ..._tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: task,
                      onCompletedChanged: (value) => _toggleTask(task, value),
                      onEdit: () => _openForm(task: task),
                      onDelete: () => _deleteTask(task),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
