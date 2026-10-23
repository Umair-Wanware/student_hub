import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class TaskFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initialTask;
  final Future<void> Function({
    required String title,
    required String subject,
    String? dueDate,
    required String priority,
  }) onSave;

  const TaskFormSheet({
    super.key,
    this.initialTask,
    required this.onSave,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subject;

  String _priority = 'Medium';
  DateTime? _dueDate;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _title = TextEditingController(text: task?['title']?.toString() ?? '');
    _subject = TextEditingController(text: task?['subject']?.toString() ?? '');
    _priority = task?['priority']?.toString() ?? 'Medium';

    final rawDate = task?['dueDate'] ?? task?['due_date'];
    if (rawDate != null) _dueDate = DateTime.tryParse(rawDate.toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (!mounted) return;
    if (selected != null) setState(() => _dueDate = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        title: _title.text.trim(),
        subject: _subject.text.trim(),
        dueDate: _dueDate == null
            ? null
            : '${_dueDate!.year.toString().padLeft(4, '0')}-'
                '${_dueDate!.month.toString().padLeft(2, '0')}-'
                '${_dueDate!.day.toString().padLeft(2, '0')}',
        priority: _priority,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _editing ? 'Edit task' : 'Create a task',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Break your study goals into manageable steps.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 22),
                AppTextField(
                  controller: _title,
                  label: 'Task title',
                  prefixIcon: Icons.task_alt_rounded,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter a task title'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _subject,
                  label: 'Subject (optional)',
                  prefixIcon: Icons.menu_book_outlined,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.045),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _dueDate == null
                        ? 'Choose due date (optional)'
                        : 'Due ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                ),
                if (_dueDate != null)
                  TextButton(
                    onPressed: () => setState(() => _dueDate = null),
                    child: const Text('Clear due date'),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _editing ? 'Save Changes' : 'Create Task',
                  loading: _saving,
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
