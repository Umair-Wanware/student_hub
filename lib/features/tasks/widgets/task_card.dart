import 'package:flutter/material.dart';

import '../../../core/widgets/glass_panel.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final ValueChanged<bool> onCompletedChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onCompletedChanged,
    required this.onEdit,
    required this.onDelete,
  });

  String get _title => task['title']?.toString() ?? 'Untitled task';
  String get _subject => task['subject']?.toString() ?? '';
  String get _priority => task['priority']?.toString() ?? 'Medium';
  bool get _completed => task['completed'] == true;

  Color get _priorityColor {
    switch (_priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF8585);
      case 'low':
        return const Color(0xFF70DFC3);
      default:
        return const Color(0xFFFFC477);
    }
  }

  String? get _dueDate {
    final raw = task['dueDate'] ?? task['due_date'];
    if (raw == null || raw.toString().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _completed,
            onChanged: (value) {
              if (value != null) onCompletedChanged(value);
            },
            activeColor: const Color(0xFF8797FF),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: _completed ? TextDecoration.lineThrough : null,
                    color: _completed ? Colors.white54 : Colors.white,
                  ),
                ),
                if (_subject.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(_subject, style: const TextStyle(color: Colors.white60)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(
                      text: _priority,
                      color: _priorityColor,
                    ),
                    if (_dueDate != null)
                      _Tag(
                        text: 'Due $_dueDate',
                        color: const Color(0xFFB7C1FF),
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit task')),
              PopupMenuItem(value: 'delete', child: Text('Delete task')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
