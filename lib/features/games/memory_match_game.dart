import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../models/bubble_letter.dart';
import '../../services/progress_service.dart';

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();

  static const _pairCount = 6;
  final List<_MatchCard> _cards = [];
  int _flippedIndex = -1;
  int _matches = 0;
  int _stars = 0;
  int _attempts = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _cards.clear();
    _flippedIndex = -1;
    _matches = 0;
    _attempts = 0;
    _checking = false;

    final selected = [...BubbleLetter.abcLetters]..shuffle();
    final pairs = selected.take(_pairCount).toList();

    for (int i = 0; i < _pairCount; i++) {
      final letter = pairs[i];
      _cards.add(_MatchCard(
        id: i * 2,
        pairId: i,
        display: letter.letter,
        emoji: _letterEmoji(letter.letter),
        isLetter: true,
      ));
      _cards.add(_MatchCard(
        id: i * 2 + 1,
        pairId: i,
        display: letter.objectName.isNotEmpty
            ? letter.objectName.substring(0, 1)
            : letter.letter,
        emoji: _letterEmoji(letter.letter),
        isLetter: false,
      ));
    }

    _cards.shuffle();
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

  void _onTapCard(int index) {
    if (_checking) return;
    final card = _cards[index];
    if (card.matched || card.flipped) return;

    setState(() => card.flipped = true);
    _sfx.playTap();

    if (_flippedIndex == -1) {
      _flippedIndex = index;
      return;
    }

    _checking = true;
    _attempts++;
    final first = _cards[_flippedIndex];
    final second = card;

    if (first.pairId == second.pairId) {
      _matches++;
      _stars++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish('Match!');

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          first.matched = true;
          second.matched = true;
          _flippedIndex = -1;
          _checking = false;
        });
        if (_matches >= _pairCount) {
          _audio.speakEnglish('You did it! All matched!');
          showRewardOverlay(context, message: 'All\nMatched!');
        }
      });
    } else {
      _sfx.playWrong();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          first.flipped = false;
          second.flipped = false;
          _flippedIndex = -1;
          _checking = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMatched = _matches >= _pairCount;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1BEE7), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              if (allMatched) _buildWinScreen(),
              if (!allMatched) ..._buildGameContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 28, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _badge('⭐ $_stars'),
          const SizedBox(width: 6),
          _badge('🎯 $_matches/$_pairCount'),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark)),
    );
  }

  List<Widget> _buildGameContent() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Match letter with picture!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: List.generate(_cards.length, (i) =>
                _buildCard(i)),
          ),
        ),
      ),
    ];
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    final show = card.flipped || card.matched;

    return GestureDetector(
      onTap: () => _onTapCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.matched
              ? AppColors.success.withValues(alpha: 0.3)
              : show
                  ? Colors.white
                  : AppColors.accent.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: card.matched
              ? Border.all(color: AppColors.success, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: show
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.display,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                )
              : const Icon(Icons.help_outline,
                  color: Colors.white, size: 36),
        ),
      ),
    );
  }

  Widget _buildWinScreen() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'All Matched!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '✨ $_stars stars in $_attempts tries',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(_initGame),
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard {
  final int id;
  final int pairId;
  final String display;
  final String emoji;
  final bool isLetter;
  bool flipped = false;
  bool matched = false;

  _MatchCard({
    required this.id,
    required this.pairId,
    required this.display,
    required this.emoji,
    required this.isLetter,
  });
}
