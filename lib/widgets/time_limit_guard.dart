import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';
import '../services/usage_service.dart';

/// Wraps the whole app (via MaterialApp.builder) and covers it with a
/// friendly break screen once the daily screen-time limit is reached.
/// Also pauses usage tracking while the app is backgrounded.
class TimeLimitGuard extends StatefulWidget {
  final Widget child;

  const TimeLimitGuard({super.key, required this.child});

  @override
  State<TimeLimitGuard> createState() => _TimeLimitGuardState();
}

class _TimeLimitGuardState extends State<TimeLimitGuard>
    with WidgetsBindingObserver {
  final UsageService _usage = UsageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _usage.addListener(_onUsageChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usage.removeListener(_onUsageChanged);
    super.dispose();
  }

  void _onUsageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _usage.resume();
    } else {
      _usage.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_usage.limitReached) return widget.child;
    return Stack(
      children: [
        widget.child,
        const Positioned.fill(child: _BreakScreen()),
      ],
    );
  }
}

/// Full-screen "time for a break" cover. This widget lives above the
/// Navigator, so the parent unlock is built inline instead of a dialog.
class _BreakScreen extends StatefulWidget {
  const _BreakScreen();

  @override
  State<_BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<_BreakScreen> {
  final UsageService _usage = UsageService();
  final _random = Random();
  final _controller = TextEditingController();
  bool _gateOpen = false;
  bool _unlocked = false;
  bool _showError = false;
  late int _a;
  late int _b;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _newQuestion() {
    _a = _random.nextInt(7) + 3;
    _b = _random.nextInt(7) + 3;
    _controller.clear();
  }

  void _check() {
    if (int.tryParse(_controller.text.trim()) == _a * _b) {
      setState(() {
        _unlocked = true;
        _showError = false;
      });
    } else {
      setState(() {
        _showError = true;
        _newQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  const Text(
                    'Time for a break!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Great job playing today!\nCome back tomorrow for more fun. ⭐',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_unlocked)
                    _buildParentActions()
                  else if (_gateOpen)
                    _buildInlineGate()
                  else
                    TextButton.icon(
                      onPressed: () => setState(() => _gateOpen = true),
                      icon: const Icon(Icons.lock_outline,
                          color: Colors.white70, size: 18),
                      label: const Text(
                        'For Parents',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineGate() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔒 Parents Only',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_a × $_b = ?',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Answer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              onSubmitted: (_) => _check(),
            ),
          ),
          if (_showError) ...[
            const SizedBox(height: 8),
            const Text(
              'Not quite — try this new one!',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _check,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Widget _buildParentActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Extend play time?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _usage.grantExtraMinutes(15),
            icon: const Icon(Icons.add_alarm),
            label: const Text('Add 15 minutes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _usage.disableForToday(),
            child: const Text('Turn off limit for today'),
          ),
        ],
      ),
    );
  }
}
