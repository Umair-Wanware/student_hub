import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../data/services/api_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _api = ApiService.instance;
  final _searchController = TextEditingController();

  Timer? _debounce;
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notes = await _api.getNotes(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _notes = notes;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      _loadNotes,
    );
  }

  Future<void> _edit([Map<String, dynamic>? note]) async {
    final formKey = GlobalKey<FormState>();
    final titleController =
        TextEditingController(text: note?['title']?.toString() ?? '');
    final contentController =
        TextEditingController(text: note?['content']?.toString() ?? '');

    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(note == null ? 'Create note' : 'Edit note'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Operating Systems revision',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentController,
                    maxLines: 7,
                    minLines: 4,
                    maxLength: 10000,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      alignLabelWithHint: true,
                      hintText: 'Write your notes here...',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter some content'
                        : null,
                  ),
                ],
              ),
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
              Navigator.pop(dialogContext, [
                titleController.text.trim(),
                contentController.text.trim(),
              ]);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // showDialog completes as soon as pop starts; its reverse transition may
    // still have TextFields attached to these controllers. Let the route finish
    // disposing its subtree before disposing the controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    titleController.dispose();
    contentController.dispose();

    if (values == null || !mounted) return;

    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    try {
      if (note == null) {
        await _api.createNote(
          title: values[0],
          content: values[1],
          date: date,
        );
      } else {
        await _api.updateNote(
          '${note['id']}',
          title: values[0],
          content: values[1],
          date: date,
        );
      }
      if (mounted) await _loadNotes();
    } catch (e) {
      _message('Could not save note: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Delete "${note['title']}" permanently?'),
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
      await _api.deleteNote('${note['id']}');
      if (mounted) await _loadNotes();
    } catch (e) {
      _message('Could not delete note: $e');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Notes'),
        actions: [
          IconButton(
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _loadNotes();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _loadNotes,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _notes.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No notes found. Create a note to get started.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotes,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 96),
                                itemCount: _notes.length,
                                itemBuilder: (context, index) {
                                  final note = _notes[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: GlassPanel(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.sticky_note_2_outlined,
                                                color: Color(0xFFD9A5FF),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  '${note['title']}',
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _edit(note);
                                                  }
                                                  if (value == 'delete') {
                                                    _delete(note);
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
                                          const SizedBox(height: 10),
                                          Text(
                                            '${note['content']}',
                                            maxLines: 7,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Date: ${note['date'] ?? 'Today'}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
