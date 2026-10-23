import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../data/services/api_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final _api = ApiService.instance;
  Timer? _timer;

  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _running = false;
  bool _saving = false;
  List<Map<String, dynamic>> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _api.getFocusSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _selectDuration(int minutes) {
    if (_running || _saving) return;
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  void _start() {
    if (_running || _saving) return;
    setState(() => _running = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _running = false;
          _saving = true;
        });
        _completeSession();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  Future<void> _completeSession() async {
    try {
      await _api.saveFocusSession(
        durationMinutes: _selectedMinutes,
        completedAt: DateTime.now(),
      );
      await _loadSessions();
      _message('Focus session completed. Great work!');
    } catch (e) {
      _message('Timer completed, but saving failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    try {
      await _api.deleteFocusSession('${session['id']}');
      await _loadSessions();
    } catch (e) {
      _message('Could not delete session: $e');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        1 - (_remainingSeconds / (_selectedMinutes * 60)).clamp(0.0, 1.0);
    final totalMinutes = _sessions.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse('${item['durationMinutes']}') ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Focus Zone'),
        actions: [
          IconButton(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'TIME TO FOCUS',
                    style: TextStyle(
                      color: Color(0xFFFFC477),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFFFC477),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timeText,
                              style: const TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'FOCUS SESSION',
                              style: TextStyle(
                                color: Colors.white60,
                                letterSpacing: 1.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose duration',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [15, 25, 45, 60].map((minutes) {
                      return ChoiceChip(
                        label: Text('$minutes min'),
                        selected: _selectedMinutes == minutes,
                        onSelected: (_) => _selectDuration(minutes),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : _running
                                  ? _pause
                                  : _start,
                          icon: Icon(
                            _running ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(_running ? 'Pause' : 'Start'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _reset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                  if (_saving) ...[
                    const SizedBox(height: 14),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Saving completed session...'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassPanel(
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_outlined,
                    size: 32,
                    color: Color(0xFFFFC477),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total focus time',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalMinutes minutes',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Completed sessions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
            if (_sessions.isEmpty)
              const GlassPanel(
                child: Text(
                  'No completed sessions yet. Start a timer to begin.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ..._sessions.map((session) {
              final date = DateTime.tryParse(
                '${session['completedAt'] ?? ''}',
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassPanel(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF63DDC6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${session['durationMinutes']} minutes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (date != null)
                              Text(
                                '${date.toLocal()}'.split('.').first,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete session',
                        onPressed: () => _deleteSession(session),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
