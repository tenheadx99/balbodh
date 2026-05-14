import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/settings_service.dart';
import '../../services/progress_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final ProgressService _progress = ProgressService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection('👤 Profile'),
                    _buildChildNameField(),
                    const SizedBox(height: 24),
                    _buildSection('🔊 Audio'),
                    _buildToggle(
                      icon: '🔊',
                      title: 'Sound Effects',
                      subtitle: 'Play sounds for actions',
                      value: _settings.soundEnabled,
                      onChanged: (v) => _settings.setSoundEnabled(v),
                    ),
                    const Divider(height: 1),
                    _buildToggle(
                      icon: '🕉️',
                      title: 'Hindi Voice',
                      subtitle: 'Use Hindi pronunciation',
                      value: _settings.hindiVoiceEnabled,
                      onChanged: (v) => _settings.setHindiVoiceEnabled(v),
                    ),
                    const SizedBox(height: 24),
                    _buildSection('🎨 Appearance'),
                    _buildToggle(
                      icon: '🌙',
                      title: 'Dark Mode',
                      subtitle: 'Easier on eyes at night',
                      value: _settings.darkMode,
                      onChanged: (v) => _settings.setDarkMode(v),
                    ),
                    const SizedBox(height: 24),
                    _buildSection('📊 Data'),
                    _buildInfoRow(
                      icon: '⭐',
                      label: 'Total Stars',
                      value: '${_progress.totalStarsAcrossModules}',
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      icon: '🔤',
                      label: 'ABC Mastered',
                      value: '${_progress.getMasteredCount("abc")} / 26',
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      icon: '🕉️',
                      label: 'हिंदी Mastered',
                      value: '${_progress.getMasteredCount("hindi")} / 43',
                    ),
                    const SizedBox(height: 24),
                    _buildSection('⚠️ Danger Zone'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmReset,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Reset All Progress'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 32, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text(
            '⚙️ Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildToggle({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.secondary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildNameField() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Enter child\'s name',
          border: InputBorder.none,
          icon: Text('✏️', style: TextStyle(fontSize: 22)),
        ),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        controller: TextEditingController(text: _settings.childName),
        onSubmitted: (v) => _settings.setChildName(v),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will delete all stars, mastered letters, and stickers. This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _progress.resetAll();
              _settings.resetAll();
              Navigator.of(ctx).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress reset!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
