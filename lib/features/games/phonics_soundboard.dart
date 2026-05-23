import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../core/audio/hindi_voice_data.dart';
import '../../services/progress_service.dart';

class PhonicsSoundboard extends StatefulWidget {
  const PhonicsSoundboard({super.key});

  @override
  State<PhonicsSoundboard> createState() => _PhonicsSoundboardState();
}

class _PhonicsSoundboardState extends State<PhonicsSoundboard> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();

  bool _isEnglish = true;
  int _stars = 0;

  // Quiz Mode state
  bool _quizMode = false;
  String _quizTarget = '';
  String _quizPrompt = '';
  int _streak = 0;

  final Map<String, String> _englishPhonics = {
    'A': 'ah, ah, Apple',
    'B': 'buh, buh, Ball',
    'C': 'cuh, cuh, Cat',
    'D': 'duh, duh, Dog',
    'E': 'eh, eh, Elephant',
    'F': 'fuh, fuh, Fish',
    'G': 'guh, guh, Goat',
    'H': 'huh, huh, Hat',
    'I': 'ih, ih, Ice cream',
    'J': 'juh, juh, Jug',
    'K': 'kuh, kuh, Kite',
    'L': 'luh, luh, Lion',
    'M': 'muh, muh, Monkey',
    'N': 'nuh, nuh, Nest',
    'O': 'ah, ah, Orange',
    'P': 'puh, puh, Penguin',
    'Q': 'quah, quah, Queen',
    'R': 'ruh, ruh, Rabbit',
    'S': 'suh, suh, Sun',
    'T': 'tuh, tuh, Tiger',
    'U': 'uh, uh, Umbrella',
    'V': 'vuh, vuh, Violin',
    'W': 'wuh, wuh, Watch',
    'X': 'ks, ks, Xylophone',
    'Y': 'yuh, yuh, Yak',
    'Z': 'zuh, zuh, Zebra',
  };

  final Map<String, String> _englishSounds = {
    'A': 'ah', 'B': 'buh', 'C': 'cuh', 'D': 'duh', 'E': 'eh', 'F': 'fuh', 'G': 'guh', 'H': 'huh',
    'I': 'ih', 'J': 'juh', 'K': 'kuh', 'L': 'luh', 'M': 'muh', 'N': 'nuh', 'O': 'ah', 'P': 'puh',
    'Q': 'quah', 'R': 'ruh', 'S': 'suh', 'T': 'tuh', 'U': 'uh', 'V': 'vuh', 'W': 'wuh', 'X': 'ks',
    'Y': 'yuh', 'Z': 'zuh'
  };

  List<String> get _currentList {
    if (_isEnglish) {
      return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    } else {
      return HindiVoiceData.letterSounds.keys.toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _stars = _progress.totalStarsAcrossModules;
    _speakIntro();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _speakIntro() {
    _audio.speakEnglish('Welcome to Phonics Explorer! Press any letter to hear its sound!');
  }

  void _onLetterTapped(String letter) {
    if (_quizMode) {
      _checkAnswer(letter);
      return;
    }

    _sfx.playPop();
    if (_isEnglish) {
      final phonicsStr = _englishPhonics[letter] ?? letter;
      _audio.speakEnglish('$letter says $phonicsStr');
    } else {
      final soundObj = HindiVoiceData.objectNames[letter] ?? '';
      _audio.speakHindi('$letter से $soundObj');
    }
  }

  void _toggleLanguage(bool isEnglish) {
    _sfx.playTap();
    setState(() {
      _isEnglish = isEnglish;
      _quizMode = false;
      _streak = 0;
    });
    if (isEnglish) {
      _audio.speakEnglish('English Alphabet letters!');
    } else {
      _audio.speakHindi('हिंदी वर्णमाला!');
    }
  }

  void _startQuiz() {
    _sfx.playTap();
    final items = _currentList;
    final target = items[Random().nextInt(items.length)];
    setState(() {
      _quizMode = true;
      _quizTarget = target;
    });

    _speakQuizPrompt();
  }

  void _speakQuizPrompt() {
    if (_isEnglish) {
      final sound = _englishSounds[_quizTarget] ?? _quizTarget;
      _quizPrompt = 'Find the letter that says: $sound';
      _audio.speakEnglish('Find the letter that says $sound');
    } else {
      final obj = HindiVoiceData.objectNames[_quizTarget] ?? '';
      _quizPrompt = 'ढूंढो अक्षर: $obj से शुरू होने वाला';
      _audio.speakHindi('ढूंढो अक्षर जो $obj बनाता है');
    }
    setState(() {});
  }

  void _checkAnswer(String clickedLetter) {
    if (clickedLetter == _quizTarget) {
      _sfx.playCorrect();
      _progress.addStar('games');
      setState(() {
        _stars++;
        _streak++;
      });

      _audio.playEncouragement(hindi: !_isEnglish);
      
      // Auto trigger next question
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _startQuiz();
      });
    } else {
      _sfx.playWrong();
      setState(() {
        _streak = 0;
      });
      _audio.playTryAgain(hindi: !_isEnglish);
    }
  }

  void _stopQuiz() {
    _sfx.playTap();
    setState(() {
      _quizMode = false;
      _streak = 0;
    });
    _audio.speakEnglish('Soundboard mode!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildControlPanel(),
              if (_quizMode) _buildQuizBanner(),
              Expanded(child: _buildSoundboardGrid()),
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
            '🗣️ Phonics Soundboard',
            style: TextStyle(
              fontSize: 22,
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

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Toggle row
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLanguage(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isEnglish ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('🔤 ABC', style: TextStyle(fontWeight: FontWeight.bold, color: _isEnglish ? Colors.white : AppColors.textDark)),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleLanguage(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isEnglish ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('🕉️ हिंदी', style: TextStyle(fontWeight: FontWeight.bold, color: !_isEnglish ? Colors.white : AppColors.textDark)),
                  ),
                ),
              ],
            ),
          ),
          // Quiz button
          ElevatedButton.icon(
            onPressed: _quizMode ? _stopQuiz : _startQuiz,
            icon: Icon(_quizMode ? Icons.stop : Icons.play_arrow),
            label: Text(_quizMode ? 'Stop Quiz' : 'Phonics Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _quizMode ? Colors.redAccent : AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _quizPrompt,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _speakQuizPrompt,
                child: const Icon(Icons.volume_up, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          if (_streak >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🔥 Streak: $_streak in a row!',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSoundboardGrid() {
    final list = _currentList;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isEnglish ? 4 : 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final letter = list[i];

        return GestureDetector(
          onTap: () => _onLetterTapped(letter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.transparent,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter,
                  style: TextStyle(
                    fontSize: _isEnglish ? 32 : 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                if (!_quizMode && _isEnglish)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _englishSounds[letter] ?? '',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark.withValues(alpha: 0.5)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
