import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/streak_service.dart';
import '../../widgets/ad_banner_widget.dart';
import 'letter_rain_game.dart';
import 'feed_monster_game.dart';
import 'memory_match_game.dart';
import 'balloon_pop_game.dart';
import 'letter_race_game.dart';
import 'sorting_factory_game.dart';
import 'color_shape_splash.dart';
import 'word_worm_game.dart';
import 'number_circus_game.dart';
import 'letter_fishing_game.dart';
import 'pizza_chef_game.dart';
import 'rocket_builder_game.dart';
import 'pattern_puzzle_game.dart';
import 'crayon_canvas_game.dart';
import 'phonics_soundboard.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      ('🎨', 'Crayon Canvas', 'Color Star, Moon, Sun, Apple!', Color(0xFF4DB6AC), const CrayonCanvasGame()),
      ('🗣️', 'Phonics Soundboard', 'English & Hindi Phonics sounds', Color(0xFF9575CD), const PhonicsSoundboard()),
      ('🌧️', 'Letter Rain', 'Tap correct falling letter', Color(0xFF42A5F5), const LetterRainGame()),
      ('👾', 'Feed the Monster', 'Feed the right letter to monster', Color(0xFF66BB6A), const FeedMonsterGame()),
      ('🃏', 'Memory Match', 'Match letter-picture pairs', Color(0xFFAB47BC), const MemoryMatchGame()),
      ('🎈', 'Balloon Pop', 'Pop balloons A to Z in order', Color(0xFFFFCA28), const BalloonPopGame()),
      ('🚗', 'Letter Race', 'Race car to correct letter', Color(0xFF29B6F6), const LetterRaceGame()),
      ('🧸', 'Sorting Factory', 'Sort items into letter bins', Color(0xFFFF8A65), const SortingFactoryGame()),
      ('🎨', 'Color & Shape', 'Find the matching shape & color', Color(0xFFCE93D8), const ColorShapeSplash()),
      ('🐛', 'Word Worm', 'Fill in the missing letter', Color(0xFF81C784), const WordWormGame()),
      ('🎪', 'Number Circus', 'Tap two numbers that add up', Color(0xFFE57373), const NumberCircusGame()),
      ('🌊', 'Letter Fishing', 'Catch the correct fish letter', Color(0xFF4FC3F7), const LetterFishingGame()),
      ('🍕', 'Pizza Chef', 'Add toppings by letter sound', Color(0xFFFFAB91), const PizzaChefGame()),
      ('🚀', 'Rocket Builder', 'Build rocket by finding letters', Color(0xFF78909C), const RocketBuilderGame()),
      ('🧩', 'Pattern Puzzle', 'What comes next in the pattern?', Color(0xFF9575CD), const PatternPuzzleGame()),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFFFCC80), Color(0xFFFFE0B2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
                        const Spacer(),
                      ]),
                      const Text('🎮 Fun Games', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      Text('${games.length} games to play!', style: TextStyle(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.7))),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: games.map((g) => _MiniCard(
                            emoji: g.$1, title: g.$2, desc: g.$3, color: g.$4,
                            onTap: () { StreakService().markToday(); Navigator.push(context, MaterialPageRoute(builder: (_) => g.$5)); },
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String emoji, title, desc;
  final Color color;
  final VoidCallback onTap;

  const _MiniCard({required this.emoji, required this.title, required this.desc, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(desc, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: AppColors.textDark.withValues(alpha: 0.5))),
        ],
      ),
    ),
  );
}
