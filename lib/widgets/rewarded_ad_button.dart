import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../services/ad_service.dart';

class RewardedAdButton extends StatefulWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final void Function() onRewarded;

  const RewardedAdButton({
    super.key,
    this.emoji = '⭐',
    this.label = 'Watch ad for a star!',
    this.subtitle = 'Free star — just watch a short video',
    this.color = AppColors.warning,
    required this.onRewarded,
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AdService().loadRewardedAd();
  }

  void _onTap() {
    if (_loading) return;
    setState(() => _loading = true);

    AdService().showRewardedAd(onRewarded: () {
      widget.onRewarded();
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Reward earned!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loading ? 'Loading...' : widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.color.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.color.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '▶ WATCH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
