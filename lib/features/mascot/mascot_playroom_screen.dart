import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../services/settings_service.dart';
import '../../services/progress_service.dart';
import 'mascot_widget.dart';

class MascotPlayroomScreen extends StatefulWidget {
  const MascotPlayroomScreen({super.key});

  @override
  State<MascotPlayroomScreen> createState() => _MascotPlayroomScreenState();
}

class _MascotPlayroomScreenState extends State<MascotPlayroomScreen> with TickerProviderStateMixin {
  final SettingsService _settings = SettingsService();
  final ProgressService _progress = ProgressService();
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();

  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  String _currentMascot = '🐱';
  String _speechBubble = 'Hi! Tap me to play, or feed me a snack!';
  bool _isHappy = false;
  int _stars = 0;

  final List<Map<String, String>> _foods = [
    {'emoji': '🍎', 'name': 'Apple', 'sound': 'Yummy apple! Thank you!'},
    {'emoji': '🍪', 'name': 'Cookie', 'sound': 'Ooh, a chocolate cookie! Delicious!'},
    {'emoji': '🍌', 'name': 'Banana', 'sound': 'Sweet banana! Monch monch!'},
    {'emoji': '🍉', 'name': 'Watermelon', 'sound': 'Cool and refreshing watermelon!'},
    {'emoji': '🥕', 'name': 'Carrot', 'sound': 'Crunchy carrot! Healthy and good!'},
  ];

  final List<String> _mascotQuotes = [
    'You are doing super-duper great today!',
    'Shall we play a learning game together?',
    'Wow, look at all the stars you earned!',
    'I love learning with you! You are so smart!',
    'Remember to stretch and drink some water!',
    'Yay! You are my best friend!',
  ];

  @override
  void initState() {
    super.initState();
    _currentMascot = _settings.avatar;
    _stars = _progress.totalStarsAcrossModules;

    // Set up springy jump controller
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 50),
    ]).animate(_jumpController);

    // Set up spin controller
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _spinAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeInOutBack),
    );

    _speakGreeting();
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _spinController.dispose();
    _audio.dispose();
    super.dispose();
  }

  void _speakGreeting() {
    _audio.speakEnglish('Welcome to my playroom! Let\'s have some fun!');
  }

  void _triggerMascotTap() {
    if (_jumpController.isAnimating || _spinController.isAnimating) return;

    final rand = Random().nextInt(3);
    if (rand == 0) {
      _sfx.playPop();
      _jumpController.forward(from: 0.0);
      setState(() {
        _speechBubble = 'Boing! Bouncing is fun!';
      });
      _audio.speakEnglish('Boing! Bouncing is fun!');
    } else if (rand == 1) {
      _sfx.playFanfare();
      _spinController.forward(from: 0.0);
      setState(() {
        _speechBubble = 'Wheee! I am spinning!';
      });
      _audio.speakEnglish('Wheee! I am spinning!');
    } else {
      _sfx.playTap();
      final quote = _mascotQuotes[Random().nextInt(_mascotQuotes.length)];
      setState(() {
        _speechBubble = quote;
      });
      _audio.speakEnglish(quote);
    }
  }

  void _feedMascot(Map<String, String> food) {
    _sfx.playCorrect();
    setState(() {
      _isHappy = true;
      _speechBubble = food['sound']!;
    });
    _audio.speakEnglish(food['sound']!);
    _jumpController.forward(from: 0.0);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isHappy = false;
          _speechBubble = 'I\'m full and happy! Let\'s learn some more!';
        });
      }
    });
  }

  void _changeMascot(String emoji) {
    _sfx.playPop();
    _settings.setAvatar(emoji);
    setState(() {
      _currentMascot = emoji;
      _speechBubble = 'Yay! I am now a $emoji character!';
    });
    _audio.speakEnglish('I love my new character look!');
    _spinController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildSpeechBubble(),
              const Spacer(),
              _buildInteractiveArea(),
              const Spacer(),
              _buildMascotSelector(),
              _buildFoodShelf(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 32, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text(
            '🏡 Mascot Playroom',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⭐ ', style: TextStyle(fontSize: 18)),
                Text('$_stars', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              _speechBubble,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            child: Container(
              width: 16,
              height: 16,
              transform: Matrix4.rotationZ(pi / 4),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveArea() {
    return GestureDetector(
      onTap: _triggerMascotTap,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_jumpController, _spinController]),
          builder: (ctx, child) {
            return Transform.scale(
              scale: _jumpAnimation.value,
              child: Transform.rotate(
                angle: _spinAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isHappy ? '😋' : _currentMascot,
                style: const TextStyle(fontSize: 120),
              ),
              if (_isHappy)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Crunch! Monch!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.green)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMascotSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            'Change my look:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: availableAvatars.length,
            itemBuilder: (ctx, idx) {
              final emoji = availableAvatars[idx];
              final isCurrent = emoji == _currentMascot;
              return GestureDetector(
                onTap: () => _changeMascot(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.warning : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent ? AppColors.orange : Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoodShelf() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🥫 Feed the Mascot shelf 🥫',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _foods.map((food) {
              return GestureDetector(
                onTap: () => _feedMascot(food),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade200, width: 2),
                      ),
                      child: Text(food['emoji']!, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food['name']!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
