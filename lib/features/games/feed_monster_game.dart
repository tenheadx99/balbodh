import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../models/bubble_letter.dart';

class FeedMonsterGame extends StatefulWidget {
  const FeedMonsterGame({super.key});

  @override
  State<FeedMonsterGame> createState() => _FeedMonsterGameState();
}

class _FeedMonsterGameState extends State<FeedMonsterGame> with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final Random _random = Random();

  int _stars = 0;
  int _streak = 0;
  int _level = 1;
  int _fed = 0;
  String _targetLetter = 'A';
  String _targetObject = 'Apple';

  final List<_FoodOption> _options = [];
  int _nextId = 0;
  bool _waiting = false;

  final List<BubbleLetter> _pool = [];
  int _poolIndex = 0;

  // Monster visual expressions: '👾' (Resting), '😮' (Hungry Open Mouth), '😋' (Chewing), '🥰' (Super Happy), '🤢' (Yuck/Wrong)
  String _monsterExpression = '👾';
  String _monsterSpeech = 'Mmm! I am so hungry! Drag me some food!';
  bool _isDraggingOver = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pool.addAll(BubbleLetter.abcLetters);
    _pool.shuffle();

    // Soft organic breathing pulse for the monster
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _nextRound();
  }

  void _nextRound() {
    if (_poolIndex >= _pool.length) {
      _pool.shuffle();
      _poolIndex = 0;
    }

    final target = _pool[_poolIndex];
    _poolIndex++;
    _targetLetter = target.letter;
    _targetObject = target.objectName;
    _waiting = false;
    _monsterExpression = '👾';
    _monsterSpeech = 'Feed me the letter $_targetLetter for $_targetObject!';

    _options.clear();
    _options.add(_FoodOption(
      id: _nextId++,
      letter: target.letter,
      emoji: _letterEmoji(target.letter),
      isCorrect: true,
    ));

    final distractorCount = min(2 + _level, 4);
    final distractors = _pool.where((l) => l.letter != target.letter).toList();
    distractors.shuffle();

    for (int i = 0; i < distractorCount && i < distractors.length; i++) {
      _options.add(_FoodOption(
        id: _nextId++,
        letter: distractors[i].letter,
        emoji: _letterEmoji(distractors[i].letter),
        isCorrect: false,
      ));
    }

    _options.shuffle();

    _audio.speakEnglish('Feed me $_targetLetter for $_targetObject!');
    setState(() {});
  }

  String _letterEmoji(String letter) {
    final map = {
      'A': '🍎', 'B': '⚽', 'C': '🐱', 'D': '🐶', 'E': '🐘',
      'F': '🐟', 'G': '🐐', 'H': '🎩', 'I': '🍦', 'J': '🏺',
      'K': '🪁', 'L': '🦁', 'M': '🐵', 'N': '🪺', 'O': '🍊',
      'P': '🐧', 'Q': '👑', 'R': '🐰', 'S': '☀️', 'T': '🐯',
      'U': '☂️', 'V': '🎻', 'W': '⌚', 'X': '🎵', 'Y': '🐃',
      'Z': '🦓',
    };
    return map[letter] ?? '🍎';
  }

  void _feedMonster(_FoodOption option) {
    if (_waiting) return;
    _waiting = true;

    if (option.isCorrect) {
      _fed++;
      _streak++;
      _stars++;
      _sfx.playCorrect();

      // Chewing sequence animation
      setState(() {
        option.caught = true;
        _monsterExpression = '😮'; // Mouth opens as food drops in
        _monsterSpeech = 'Nom nom nom! Tasty!';
      });

      // Quick state delay chain to make the chewing look dynamic
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _monsterExpression = '😋'; // Chewing
          });
        }
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _monsterExpression = '🥰'; // Happy satisfy
            if (_streak >= 3) {
              _stars++;
              _monsterSpeech = 'Yum! $_targetLetter is amazing! Bonus Star!';
              _audio.speakEnglish('Double yummy! That\'s amazing!');
            } else {
              _monsterSpeech = 'Yum! Perfect $_targetLetter!';
              _audio.speakEnglish('Yum! $_targetLetter!');
            }
          });
        }
      });

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        if (_fed >= 5) {
          _fed = 0;
          _level++;
          _audio.speakEnglish('Level $_level! More choices on plate!');
        }
        _nextRound();
      });
    } else {
      _streak = 0;
      _sfx.playWrong();
      _audio.playTryAgain();
      setState(() {
        option.wrong = true;
        _monsterExpression = '🤢'; // Yucky look
        _monsterSpeech = 'Blehh! That is not $_targetLetter!';
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            option.wrong = false;
            _monsterExpression = '👾';
            _monsterSpeech = 'Please feed me the correct letter $_targetLetter!';
            _waiting = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // Premium kids play garden colors
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              _buildMonsterArea(),
              _buildPlatePrompt(),
              const SizedBox(height: 12),
              Expanded(child: _buildFoodPlatter()),
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
          _badge('⭐ $_stars Stars'),
          const SizedBox(width: 8),
          if (_streak >= 2) _badge('🔥 $_streak Streak'),
          const SizedBox(width: 8),
          _badge('Level $_level'),
        ],
      ),
    );
  }

  Widget _badge(String text) {
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
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildMonsterArea() {
    return Column(
      children: [
        // Monster speech bubble
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _monsterSpeech,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w850,
              color: AppColors.textDark,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Drag Target Monster mouth
        DragTarget<_FoodOption>(
          onWillAcceptWidget: (data) {
            setState(() {
              _isDraggingOver = true;
              _monsterExpression = '😮'; // Opens mouth in anticipation!
            });
            return true;
          },
          onLeave: (data) {
            setState(() {
              _isDraggingOver = false;
              _monsterExpression = '👾'; // Closes mouth
            });
          },
          onAcceptWithDetails: (details) {
            setState(() {
              _isDraggingOver = false;
            });
            _feedMonster(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            return ScaleTransition(
              scale: _pulseAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDraggingOver ? Colors.orange.shade100 : Colors.white24,
                  border: Border.all(
                    color: _isDraggingOver ? Colors.orange : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    _monsterExpression,
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlatePrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Target: ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            '$_targetLetter ',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w950, color: AppColors.primary),
          ),
          Text(
            '($_targetObject)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodPlatter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8), // Wooden platter table color
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF8D6E63), width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🍽️ DRAG TO THE MONSTER\'S MOUTH 🍽️',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5D4037),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final opt = _options[index];
                
                // Set appropriate card bg based on status
                Color cardColor = Colors.white;
                if (opt.caught) cardColor = AppColors.success.withValues(alpha: 0.85);
                if (opt.wrong) cardColor = AppColors.primary.withValues(alpha: 0.85);

                final cardWidget = Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: opt.caught
                        ? Border.all(color: Colors.green, width: 4)
                        : opt.wrong
                            ? Border.all(color: Colors.red, width: 4)
                            : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        opt.emoji,
                        style: const TextStyle(fontSize: 42),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt.letter,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: opt.caught ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );

                // If already caught, do not drag
                if (opt.caught || _waiting) {
                  return cardWidget;
                }

                // Make food draggable!
                return Draggable<_FoodOption>(
                  data: opt,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.15,
                      child: Opacity(
                        opacity: 0.9,
                        child: SizedBox(
                          width: 130,
                          height: 105,
                          child: cardWidget,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.25,
                    child: cardWidget,
                  ),
                  child: cardWidget,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodOption {
  final int id;
  final String letter;
  final String emoji;
  final bool isCorrect;
  bool caught;
  bool wrong;

  _FoodOption({
    required this.id,
    required this.letter,
    required this.emoji,
    required this.isCorrect,
    this.caught = false,
    this.wrong = false,
  });
}
