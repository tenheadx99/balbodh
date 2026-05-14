import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/sticker.dart';
import '../../services/progress_service.dart';

class StickerBookScreen extends StatefulWidget {
  final ProgressService progressService;

  const StickerBookScreen({super.key, required this.progressService});

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _unlockedStickers = {};
  int _totalStars = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProgress();
  }

  void _loadProgress() {
    _totalStars = widget.progressService.totalStarsAcrossModules;

    for (final sticker in Sticker.all) {
      if (_totalStars >= sticker.starsRequired) {
        _unlockedStickers.add(sticker.id);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            colors: [Color(0xFFFFF176), Color(0xFFFFF9C4)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStickerGrid(Sticker.abcStickers),
                    _buildStickerGrid(Sticker.hindiStickers),
                    _buildStickerGrid(Sticker.mathStickers),
                    _buildStickerGrid(Sticker.bonusStickers),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    size: 32, color: AppColors.textDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalStars',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '🌟 My Sticker Book',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          Text(
            '${_unlockedStickers.length} / ${Sticker.all.length} collected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: Sticker.all.isEmpty
                  ? 0
                  : _unlockedStickers.length / Sticker.all.length,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final labels = ['🔤 ABC', '🕉️ हिंदी', '🔢 Math', '🎁 Bonus'];
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.textDark,
      unselectedLabelColor: AppColors.textDark.withValues(alpha: 0.4),
      indicatorColor: AppColors.primary,
      indicatorWeight: 4,
      labelStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700),
      tabs: labels.map((l) => Tab(text: l)).toList(),
    );
  }

  Widget _buildStickerGrid(List<Sticker> stickers) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        final isUnlocked = _unlockedStickers.contains(sticker.id);
        return _StickerCell(
          sticker: sticker,
          isUnlocked: isUnlocked,
          totalStars: _totalStars,
        );
      },
    );
  }
}

class _StickerCell extends StatefulWidget {
  final Sticker sticker;
  final bool isUnlocked;
  final int totalStars;

  const _StickerCell({
    required this.sticker,
    required this.isUnlocked,
    required this.totalStars,
  });

  @override
  State<_StickerCell> createState() => _StickerCellState();
}

class _StickerCellState extends State<_StickerCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    if (widget.isUnlocked) {
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StickerCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked && !oldWidget.isUnlocked) {
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isUnlocked ? _bounceAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isUnlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isUnlocked
                      ? AppColors.warning
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: widget.isUnlocked
                    ? [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isUnlocked
                        ? widget.sticker.emoji
                        : '🔒',
                    style: TextStyle(
                      fontSize: widget.isUnlocked ? 36 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sticker.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isUnlocked
                          ? AppColors.textDark
                          : AppColors.textDark.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.sticker.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              widget.sticker.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isUnlocked
                  ? '✅ Collected!'
                  : '⭐ Need ${widget.sticker.starsRequired} stars\n(You have ${widget.totalStars})',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isUnlocked
                    ? AppColors.success
                    : AppColors.textDark.withValues(alpha: 0.6),
              ),
            ),
            if (!widget.isUnlocked) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: widget.sticker.starsRequired > 0
                      ? (widget.totalStars / widget.sticker.starsRequired)
                          .clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.warning),
                  minHeight: 8,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              widget.sticker.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
