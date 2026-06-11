import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';

/// Shows a multiplication challenge that young children can't solve,
/// so parent-only screens stay out of reach. Returns true when passed.
Future<bool> showParentGate(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const ParentGateDialog(),
  );
  return result ?? false;
}

class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key});

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  final _random = Random();
  final _controller = TextEditingController();
  late int _a;
  late int _b;
  bool _showError = false;

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
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _showError = true;
        _newQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Text('🔒', style: TextStyle(fontSize: 26)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Parents Only',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solve to continue:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_a × $_b = ?',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          if (_showError) ...[
            const SizedBox(height: 8),
            const Text(
              'Not quite — try this new one!',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _check,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
