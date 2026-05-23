import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';

class BalloonPopGame extends StatefulWidget {
  const BalloonPopGame({super.key});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame> with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final Random _random = Random();

  final List<_Balloon> _balloons = [];
  final List<_Particle> _particles = [];
  int _nextId = 0;

  final List<String> _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  int _currentIndex = 0;
  int _stars = 0;
  int _level = 1;

  Timer? _gameLoopTimer;
  Timer? _spawnTimer;
  double _areaW = 400;
  double _areaH = 600;

  // Mascot state
  String _mascotReaction = '🐶';
  String _mascotTalk = 'Pop the matching letter!';

  final List<List<Color>> _balloonGradients = [
    [const Color(0xFFFF5252), const Color(0xFFFF1744)], // Bright Red
    [const Color(0xFFFF4081), const Color(0xFFF50057)], // Hot Pink
    [const Color(0xFFE040FB), const Color(0xFFD500F9)], // Magic Purple
    [const Color(0xFF651FFF), const Color(0xFF3D5AFE)], // Indigo Blue
    [const Color(0xFF00E5FF), const Color(0xFF00B0FF)], // Sky Cyan
    [const Color(0xFF1DE9B6), const Color(0xFF00BFA5)], // Teal Green
    [const Color(0xFF00E676), const Color(0xFF00C853)], // Neon Green
    [const Color(0xFFFFEA00), const Color(0xFFFFD600)], // Gold Yellow
    [const Color(0xFFFF9100), const Color(0xFFFF6D00)], // Orange
  ];

  @override
  void initState() {
    super.initState();
    _audio.speakEnglish('Pop the balloons A to Z!');
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  void _startGame() {
    _spawnBalloons();
    // Spawns balloons every 2.5 seconds
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) _spawnBalloons();
    });

    // Unified game tick loop (60 FPS) for floating balloons and exploding particles physics
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() {
        // 1. Move balloons upwards with gentle side wave
        for (final b in _balloons) {
          b.y -= 0.9 + _level * 0.08;
          b.wobblePhase += 0.04;
          b.x += sin(b.wobblePhase + b.phase) * 0.6;
        }
        _balloons.removeWhere((b) => b.y < -120);

        // 2. Physics logic for particles (velocity, gravity, fade)
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.18; // gravity
          p.opacity -= 0.024; // fade rate
        }
        _particles.removeWhere((p) => p.opacity <= 0);
      });
    });
  }

  void _spawnBalloons() {
    if (_currentIndex >= _letters.length) return;
    
    // Spawn 2 to 4 balloons
    final count = 2 + _random.nextInt(3);
    for (int i = 0; i < count && _balloons.length < 12; i++) {
      // Ensure at least one target balloon is on screen or spawn it
      final isTarget = _balloons.every((b) => !b.isTarget);
      final gradient = _balloonGradients[_random.nextInt(_balloonGradients.length)];
      
      _balloons.add(_Balloon(
        id: _nextId++,
        letter: isTarget ? _letters[_currentIndex] : _letters[_random.nextInt(_letters.length)],
        x: 40 + _random.nextDouble() * (_areaW - 120),
        y: _areaH + 50 + _random.nextDouble() * 120,
        phase: _random.nextDouble() * 10,
        wobblePhase: _random.nextDouble() * 5,
        isTarget: isTarget,
        gradient: gradient,
      ));
    }
  }

  void _triggerPopParticles(double startX, double startY, List<Color> colors) {
    // Generate star sparkle particle blast
    for (int i = 0; i < 18; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 2.0 + _random.nextDouble() * 5.0;
      _particles.add(_Particle(
        x: startX,
        y: startY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 2.0, // Initial upward blast boost
        size: 8.0 + _random.nextDouble() * 12.0,
        color: colors[_random.nextInt(colors.length)],
      ));
    }
  }

  void _popBalloon(int id) {
    final idx = _balloons.indexWhere((b) => b.id == id);
    if (idx == -1) return;

    final balloon = _balloons[idx];
    
    // Calculate center of balloon for explosion origin
    final popX = balloon.x + 35; 
    final popY = balloon.y + 40;

    if (balloon.isTarget) {
      _triggerPopParticles(popX, popY, balloon.gradient);
      _balloons.removeAt(idx);
      _stars++;
      _sfx.playCorrect();
      _audio.speakEnglish(_letters[_currentIndex]);
      
      setState(() {
        _mascotReaction = '🥳';
        _mascotTalk = 'Yay! You got ${_letters[_currentIndex]}!';
        _currentIndex++;
      });

      // Quick mascot reset delay
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _mascotReaction = '🐶';
            if (_currentIndex < _letters.length) {
              _mascotTalk = 'Find and pop ${_letters[_currentIndex]}!';
            }
          });
        }
      });

      if (_currentIndex >= _letters.length) {
        _sfx.playFanfare();
        _audio.speakEnglish('Fantastic job! You popped all letters A to Z!');
        // Throw massive win particle burst!
        for (int i = 0; i < 50; i++) {
          _triggerPopParticles(_areaW / 2, _areaH / 3, [Colors.red, Colors.yellow, Colors.blue, Colors.green, Colors.pink]);
        }
        setState(() {});
        return;
      }

      if (_currentIndex % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level! Speeding up!');
      }
      
      // Auto pop any other targets left to keep game logic crisp
      _balloons.removeWhere((b) => b.isTarget);
      _spawnBalloons();
    } else {
      _sfx.playWrong();
      setState(() {
        _mascotReaction = '😮';
        _mascotTalk = 'That is ${balloon.letter}. Find ${_letters[_currentIndex]}!';
      });
      
      // Mild shake/flash animation feedback can be handled in UI or speech
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _mascotReaction == '😮') {
          setState(() {
            _mascotReaction = '🐶';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _currentIndex >= _letters.length;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)], // High aesthetics sky-blue
          ),
        ),
        child: SafeArea(
          child: done ? _buildWin() : Column(
            children: [
              _buildTopBar(),
              _buildMascotGuide(),
              Expanded(child: _buildPlayField()),
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
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          _badge('⭐ $_stars Stars'),
          const SizedBox(width: 8),
          _badge('🎈 Level $_level'),
          const SizedBox(width: 8),
          _badge('🎯 ABC: ${_currentIndex}/26'),
        ],
      ),
    );
  }

  Widget _badge(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildMascotGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          children: [
            Text(
              _mascotReaction,
              style: const TextStyle(fontSize: 44),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mascotTalk,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text(
                        'Target Balloon: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _letters[_currentIndex],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayField() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        _areaW = constraints.maxWidth;
        _areaH = constraints.maxHeight;

        return Stack(
          children: [
            // 1. Interactive Balloons Layer
            ..._balloons.map((b) => Positioned(
                  left: b.x,
                  top: b.y,
                  child: GestureDetector(
                    onTap: () => _popBalloon(b.id),
                    child: _buildGlossyBalloon(b),
                  ),
                )),

            // 2. Real-time Particle Explosion Overlay Layer
            IgnorePointer(
              child: CustomPaint(
                size: Size(_areaW, _areaH),
                painter: _ParticlePainter(_particles),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlossyBalloon(_Balloon b) {
    return SizedBox(
      width: 76,
      height: 120,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Balloon Wavy String
          Positioned(
            top: 76,
            child: CustomPaint(
              size: const Size(12, 40),
              painter: _StringPainter(),
            ),
          ),
          
          // Glossy Balloon Body
          Container(
            width: 72,
            height: 84,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.25, -0.3),
                radius: 0.95,
                colors: [
                  b.gradient[0].withValues(alpha: 0.95),
                  b.gradient[1],
                ],
              ),
              borderRadius: const BorderRadius.all(Radius.elliptical(36, 42)),
              boxShadow: [
                BoxShadow(
                  color: b.gradient[1].withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Highlight Reflection Specular
                Positioned(
                  left: 12,
                  top: 10,
                  child: Container(
                    width: 14,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.all(Radius.elliptical(7, 4)),
                    ),
                  ),
                ),
                
                // Balloon Letter Text
                Center(
                  child: Text(
                    b.letter,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Little balloon knot tie at base
          Positioned(
            top: 82,
            child: Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: b.gradient[1],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWin() {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF1F8E9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              const Text(
                'A to Z Champ!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w950,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You popped all 26 balloons!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _winStat('⭐ $_stars', 'Stars Earned'),
                  const SizedBox(width: 24),
                  _winStat('🎉 Lv $_level', 'Level Reached'),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home, size: 24),
                label: const Text('Back to Games Hub'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _winStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey),
        ),
      ],
    );
  }
}

class _Balloon {
  final int id;
  final String letter;
  double x;
  double y;
  final double phase;
  double wobblePhase;
  final bool isTarget;
  final List<Color> gradient;

  _Balloon({
    required this.id,
    required this.letter,
    required this.x,
    required this.y,
    required this.phase,
    required this.wobblePhase,
    required this.isTarget,
    required this.gradient,
  });
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      
      // Draw sparkle/star using path
      final path = Path();
      final halfSize = p.size / 2;
      path.moveTo(p.x, p.y - halfSize);
      path.quadraticBezierTo(p.x, p.y, p.x + halfSize, p.y);
      path.quadraticBezierTo(p.x, p.y, p.x, p.y + halfSize);
      path.quadraticBezierTo(p.x, p.y, p.x - halfSize, p.y);
      path.quadraticBezierTo(p.x, p.y, p.x, p.y - halfSize);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    // Draw curvy wave string
    path.quadraticBezierTo(
      size.width / 2 - 4,
      size.height * 0.3,
      size.width / 2 + 2,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width / 2 - 2,
      size.height * 0.85,
      size.width / 2,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
