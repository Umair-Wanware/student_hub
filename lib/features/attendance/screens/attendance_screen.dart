import 'package:flutter/material.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../data/services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _api = ApiService.instance;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final records = await _api.getAttendance();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double _percentage(Map<String, dynamic> item) {
    final total = int.tryParse('${item['total']}') ?? 0;
    final attended = int.tryParse('${item['attended']}') ?? 0;
    return total <= 0 ? 0 : attended * 100 / total;
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final formKey = GlobalKey<FormState>();
    final subjectController =
        TextEditingController(text: item?['subject']?.toString() ?? '');
    final attendedController =
        TextEditingController(text: '${item?['attended'] ?? 0}');
    final totalController =
        TextEditingController(text: '${item?['total'] ?? 1}');

    final values = await showDialog<List<Object>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Add subject' : 'Edit subject'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a subject' : null,
                ),
                TextFormField(
                  controller: attendedController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Classes attended'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter a valid number';
                    return null;
                  },
                ),
                TextFormField(
                  controller: totalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total classes'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Enter at least 1';
                    final attended = int.tryParse(attendedController.text);
                    if (attended != null && attended > n) {
                      return 'Total must be >= attended';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, <Object>[
                subjectController.text.trim(),
                int.parse(attendedController.text),
                int.parse(totalController.text),
              ]);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // Wait for the dialog's reverse transition so its TextFields are detached
    // before disposing the controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    subjectController.dispose();
    attendedController.dispose();
    totalController.dispose();

    if (values == null || !mounted) return;

    try {
      if (item == null) {
        await _api.createAttendance(
          subject: values[0] as String,
          attended: values[1] as int,
          total: values[2] as int,
        );
      } else {
        await _api.updateAttendance(
          '${item['id']}',
          subject: values[0] as String,
          attended: values[1] as int,
          total: values[2] as int,
        );
      }
      await _load();
    } catch (e) {
      _message('Could not save attendance: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text('Remove ${item['subject']} from attendance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.deleteAttendance('${item['id']}');
      if (mounted) await _load();
    } catch (e) {
      _message('Could not delete subject: $e');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final average = _records.isEmpty
        ? 0.0
        : _records.fold<double>(
              0,
              (sum, item) => sum + _percentage(item),
            ) /
            _records.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Add subject'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      children: [
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Average attendance',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${average.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Average of your subject percentages',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(30),
                            child: Center(
                              child: Text(
                                'No subjects yet. Tap Add subject to begin.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ..._records.map((item) {
                          final percentage = _percentage(item);
                          final color = percentage >= 75
                              ? const Color(0xFF63DDC6)
                              : const Color(0xFFFFC477);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item['subject']}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') _edit(item);
                                          if (value == 'delete') {
                                            _delete(item);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${item['attended']} / ${item['total']} classes',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: LinearProgressIndicator(
                                      value: (percentage / 100).clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}% attendance',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }
}
