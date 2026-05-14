import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';

class PizzaChefGame extends StatefulWidget {
  const PizzaChefGame({super.key});

  @override
  State<PizzaChefGame> createState() => _PizzaChefGameState();
}

class _PizzaChefGameState extends State<PizzaChefGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final Random _random = Random();

  static const _toppings = [
    ('C', '🧀', 'Cheese'), ('M', '🍄', 'Mushroom'), ('O', '🫒', 'Olive'),
    ('P', '🫑', 'Pepper'), ('S', '🌭', 'Sausage'), ('T', '🍅', 'Tomato'),
    ('B', '🥓', 'Bacon'), ('H', '🌶️', 'Chilli'), ('A', '🧅', 'Onion'),
    ('E', '🥚', 'Egg'),
  ];

  final List<String> _addedToppings = [];
  int _currentIdx = 0;
  int _stars = 0;
  int _level = 1;
  int _pizzasMade = 0;

  @override
  void initState() {
    super.initState();
    _nextTopping();
  }

  void _nextTopping() {
    if (_currentIdx >= _toppings.length) {
      _pizzasMade++;
      _sfx.playFanfare();
      _audio.speakEnglish('Pizza complete!');
      setState(() {});
      return;
    }
    final t = _toppings[_currentIdx];
    _audio.speakEnglish('Add ${t.$3} for letter ${t.$1}');
    setState(() {});
  }

  void _pickTopping(String letter) {
    if (_currentIdx >= _toppings.length) return;
    final t = _toppings[_currentIdx];
    if (letter == t.$1) {
      _stars++;
      _addedToppings.add(t.$2);
      _currentIdx++;
      _sfx.playCorrect();
      if (_currentIdx % 5 == 0) { _level++; _audio.speakEnglish('Level $_level!'); }
      _nextTopping();
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
    }
  }

  List<String> _options() {
    if (_currentIdx >= _toppings.length) return [];
    final target = _toppings[_currentIdx].$1;
    final opts = <String>{target};
    final pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.replaceAll(target, '');
    for (int i = 0; i < 3; i++) opts.add(pool[_random.nextInt(pool.length)]);
    return opts.toList()..shuffle();
  }

  @override
  void dispose() { _audio.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final done = _currentIdx >= _toppings.length;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFCCBC), Color(0xFFFFF3E0)]),
        ),
        child: SafeArea(child: done ? _buildWin() : Column(children: [
          _buildTopBar(),
          _buildPizza(),
          _buildOrder(),
          const Spacer(),
          _buildOptions(),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      const Spacer(), _badge('⭐ $_stars'), const SizedBox(width: 6), _badge('🍕 $_pizzasMade'),
    ]),
  );

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
    child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
  );

  Widget _buildPizza() => Padding(
    padding: const EdgeInsets.all(12),
    child: Container(
      width: 160, height: 160,
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), shape: BoxShape.circle, border: Border.all(color: AppColors.orange.withValues(alpha: 0.5), width: 4)),
      child: Center(child: Wrap(
        alignment: WrapAlignment.center,
        children: _addedToppings.map((e) => Text(e, style: const TextStyle(fontSize: 28))).toList(),
      )),
    ),
  );

  Widget _buildOrder() {
    if (_currentIdx >= _toppings.length) return const SizedBox.shrink();
    final t = _toppings[_currentIdx];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('👨‍🍳 ', style: const TextStyle(fontSize: 28)),
        Text('Add: ${t.$3}  (letter ${t.$1})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ]),
    );
  }

  Widget _buildOptions() {
    final opts = _options();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Wrap(
        spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
        children: opts.map((l) => GestureDetector(
          onTap: () => _pickTopping(l),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 4))]),
            child: Center(child: Text(l, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textDark))),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildWin() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🍕', style: TextStyle(fontSize: 72)),
    const SizedBox(height: 16),
    const Text('Pizza Ready!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark)),
    Text('⭐ $_stars stars  •  $_pizzasMade pizzas made', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home), label: const Text('Home'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14))),
  ]));
}
