import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

class UserSettingsScreen extends StatefulWidget {
  final Color themeColor;

  const UserSettingsScreen({super.key, this.themeColor = Colors.purple});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadUserData();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> _loadUserData() async {
    try {
      UserService.getCurrentUserProfile().listen((profile) {
        if (profile != null) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
          _controller.forward();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: widget.themeColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [_buildAppBar(), _buildSettingsContent()],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.themeColor,
                      widget.themeColor.withOpacity(0.7),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    top: 100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  _buildGeneralSection(),
                  _buildNotificationSection(),
                  _buildLearningSection(),
                  _buildPrivacySection(),
                  _buildAccessibilitySection(),
                  _buildAboutSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _buildSection('General', Icons.settings_rounded, [
      _buildSettingItem(
        'Theme',
        _userProfile?.preferences.darkMode == true ? 'Dark Mode' : 'Light Mode',
        Icons.palette_rounded,
        () => _toggleTheme(),
        trailing: Switch(
          value: _userProfile?.preferences.darkMode ?? true,
          onChanged: (value) => _toggleTheme(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Language',
        _getLanguageDisplayName(_userProfile?.preferences.language ?? 'en'),
        Icons.language_rounded,
        () => _changeLanguage(),
      ),
      _buildSettingItem(
        'Auto-sync',
        'Sync data automatically',
        Icons.sync_rounded,
        () => _toggleAutoSync(),
        trailing: Switch(
          value: true, // TODO: Get actual auto-sync setting
          onChanged: (value) => _toggleAutoSync(),
          activeThumbColor: widget.themeColor,
        ),
      ),
    ]);
  }

  Widget _buildNotificationSection() {
    final notifications = _userProfile?.preferences.notificationSettings;

    return _buildSection('Notifications', Icons.notifications_rounded, [
      _buildSettingItem(
        'Push Notifications',
        'Receive push notifications',
        Icons.phone_android_rounded,
        () => _togglePushNotifications(),
        trailing: Switch(
          value: _userProfile?.preferences.pushNotifications ?? true,
          onChanged: (value) => _togglePushNotifications(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Email Digest',
        'Weekly progress summary',
        Icons.email_rounded,
        () => _toggleEmailDigest(),
        trailing: Switch(
          value: _userProfile?.preferences.emailDigest ?? true,
          onChanged: (value) => _toggleEmailDigest(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Achievement Alerts',
        'Notify when you unlock achievements',
        Icons.emoji_events_rounded,
        () => _toggleAchievementAlerts(),
        trailing: Switch(
          value: notifications?.achievementUnlocked ?? true,
          onChanged: (value) => _toggleAchievementAlerts(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Streak Reminders',
        'Daily learning streak reminders',
        Icons.local_fire_department_rounded,
        () => _toggleStreakReminders(),
        trailing: Switch(
          value: notifications?.streakReminder ?? true,
          onChanged: (value) => _toggleStreakReminders(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Quiet Hours',
        '${_formatTime(notifications?.quietHoursStart)} - ${_formatTime(notifications?.quietHoursEnd)}',
        Icons.bedtime_rounded,
        () => _setQuietHours(),
      ),
    ]);
  }

  Widget _buildLearningSection() {
    final learning = _userProfile?.preferences.learningPreferences;

    return _buildSection('Learning', Icons.school_rounded, [
      _buildSettingItem(
        'Daily Goal',
        '${learning?.dailyGoal ?? 30} minutes',
        Icons.flag_rounded,
        () => _setDailyGoal(),
      ),
      _buildSettingItem(
        'Preferred Difficulty',
        _getDifficultyDisplayName(
          learning?.preferredDifficulty ?? 'intermediate',
        ),
        Icons.trending_up_rounded,
        () => _setPreferredDifficulty(),
      ),
      _buildSettingItem(
        'Learning Style',
        _getLearningStyleDisplayName(learning?.learningStyle ?? 'visual'),
        Icons.psychology_rounded,
        () => _setLearningStyle(),
      ),
      _buildSettingItem(
        'Adaptive Learning',
        'Personalize content difficulty',
        Icons.auto_fix_high_rounded,
        () => _toggleAdaptiveLearning(),
        trailing: Switch(
          value: learning?.adaptiveLearning ?? true,
          onChanged: (value) => _toggleAdaptiveLearning(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Gamification',
        'Enable points and badges',
        Icons.videogame_asset_rounded,
        () => _toggleGamification(),
        trailing: Switch(
          value: learning?.gamificationEnabled ?? true,
          onChanged: (value) => _toggleGamification(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Study Reminder',
        _formatTime(learning?.preferredStudyTime),
        Icons.alarm_rounded,
        () => _setStudyReminder(),
      ),
    ]);
  }

  Widget _buildPrivacySection() {
    final privacy = _userProfile?.preferences.privacySettings;

    return _buildSection('Privacy & Security', Icons.security_rounded, [
      _buildSettingItem(
        'Profile Visibility',
        'Show profile to other users',
        Icons.visibility_rounded,
        () => _toggleProfileVisibility(),
        trailing: Switch(
          value: privacy?.profileVisible ?? true,
          onChanged: (value) => _toggleProfileVisibility(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Activity Sharing',
        'Share learning activity',
        Icons.share_rounded,
        () => _toggleActivitySharing(),
        trailing: Switch(
          value: privacy?.activityVisible ?? true,
          onChanged: (value) => _toggleActivitySharing(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Show Achievements',
        'Display achievements publicly',
        Icons.emoji_events_rounded,
        () => _toggleAchievementsVisibility(),
        trailing: Switch(
          value: privacy?.achievementsVisible ?? true,
          onChanged: (value) => _toggleAchievementsVisibility(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Online Status',
        'Show when you\'re online',
        Icons.circle_rounded,
        () => _toggleOnlineStatus(),
        trailing: Switch(
          value: privacy?.showOnlineStatus ?? true,
          onChanged: (value) => _toggleOnlineStatus(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Data Usage',
        'How your data is used',
        Icons.analytics_rounded,
        () => _showDataUsageInfo(),
      ),
      _buildSettingItem(
        'Change Password',
        'Update your password',
        Icons.lock_rounded,
        () => _changePassword(),
      ),
    ]);
  }

  Widget _buildAccessibilitySection() {
    final accessibility = _userProfile?.preferences.accessibilitySettings;

    return _buildSection('Accessibility', Icons.accessibility_rounded, [
      _buildSettingItem(
        'Text Size',
        _getTextSizeDisplayName(accessibility?.fontSize ?? 16.0),
        Icons.text_fields_rounded,
        () => _adjustTextSize(),
      ),
      _buildSettingItem(
        'High Contrast',
        'Increase color contrast',
        Icons.contrast_rounded,
        () => _toggleHighContrast(),
        trailing: Switch(
          value: accessibility?.highContrast ?? false,
          onChanged: (value) => _toggleHighContrast(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Reduce Motion',
        'Minimize animations',
        Icons.motion_photos_off_rounded,
        () => _toggleReduceMotion(),
        trailing: Switch(
          value: accessibility?.reduceMotion ?? false,
          onChanged: (value) => _toggleReduceMotion(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Screen Reader',
        'Enable screen reader support',
        Icons.record_voice_over_rounded,
        () => _toggleScreenReader(),
        trailing: Switch(
          value: accessibility?.screenReader ?? false,
          onChanged: (value) => _toggleScreenReader(),
          activeThumbColor: widget.themeColor,
        ),
      ),
      _buildSettingItem(
        'Color Blind Support',
        _getColorBlindDisplayName(accessibility?.colorBlindSupport ?? 'none'),
        Icons.color_lens_rounded,
        () => _setColorBlindSupport(),
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSection('About', Icons.info_rounded, [
      _buildSettingItem(
        'App Version',
        '1.0.0 (Build 123)',
        Icons.apps_rounded,
        null,
      ),
      _buildSettingItem(
        'Terms of Service',
        'Read our terms',
        Icons.description_rounded,
        () => _showTermsOfService(),
      ),
      _buildSettingItem(
        'Privacy Policy',
        'Read our privacy policy',
        Icons.policy_rounded,
        () => _showPrivacyPolicy(),
      ),
      _buildSettingItem(
        'Help & Support',
        'Get help or contact us',
        Icons.help_rounded,
        () => _showHelpSupport(),
      ),
      _buildSettingItem(
        'Send Feedback',
        'Help us improve the app',
        Icons.feedback_rounded,
        () => _sendFeedback(),
      ),
      _buildSettingItem(
        'Rate App',
        'Rate us on the app store',
        Icons.star_rounded,
        () => _rateApp(),
      ),
    ]);
  }

  Widget _buildSection(String title, IconData icon, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: widget.themeColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Section Items
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods for display names
  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      default:
        return 'English';
    }
  }

  String _getDifficultyDisplayName(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }

  String _getLearningStyleDisplayName(String style) {
    switch (style) {
      case 'visual':
        return 'Visual';
      case 'auditory':
        return 'Auditory';
      case 'kinesthetic':
        return 'Kinesthetic';
      case 'reading':
        return 'Reading/Writing';
      default:
        return 'Visual';
    }
  }

  String _getTextSizeDisplayName(double size) {
    if (size <= 14) return 'Small';
    if (size <= 16) return 'Normal';
    if (size <= 18) return 'Large';
    return 'Extra Large';
  }

  String _getColorBlindDisplayName(String type) {
    switch (type) {
      case 'none':
        return 'None';
      case 'protanopia':
        return 'Protanopia';
      case 'deuteranopia':
        return 'Deuteranopia';
      case 'tritanopia':
        return 'Tritanopia';
      default:
        return 'None';
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Settings actions (placeholder implementations)
  void _toggleTheme() {
    // TODO: Implement theme toggle
    print('Toggle theme');
  }

  void _changeLanguage() {
    // TODO: Show language selection dialog
    print('Change language');
  }

  void _toggleAutoSync() {
    // TODO: Toggle auto-sync
    print('Toggle auto-sync');
  }

  void _togglePushNotifications() {
    // TODO: Toggle push notifications
    print('Toggle push notifications');
  }

  void _toggleEmailDigest() {
    // TODO: Toggle email digest
    print('Toggle email digest');
  }

  void _toggleAchievementAlerts() {
    // TODO: Toggle achievement alerts
    print('Toggle achievement alerts');
  }

  void _toggleStreakReminders() {
    // TODO: Toggle streak reminders
    print('Toggle streak reminders');
  }

  void _setQuietHours() {
    // TODO: Show quiet hours picker
    print('Set quiet hours');
  }

  void _setDailyGoal() {
    // TODO: Show daily goal picker
    print('Set daily goal');
  }

  void _setPreferredDifficulty() {
    // TODO: Show difficulty selection
    print('Set preferred difficulty');
  }

  void _setLearningStyle() {
    // TODO: Show learning style selection
    print('Set learning style');
  }

  void _toggleAdaptiveLearning() {
    // TODO: Toggle adaptive learning
    print('Toggle adaptive learning');
  }

  void _toggleGamification() {
    // TODO: Toggle gamification
    print('Toggle gamification');
  }

  void _setStudyReminder() {
    // TODO: Show study reminder time picker
    print('Set study reminder');
  }

  void _toggleProfileVisibility() {
    // TODO: Toggle profile visibility
    print('Toggle profile visibility');
  }

  void _toggleActivitySharing() {
    // TODO: Toggle activity sharing
    print('Toggle activity sharing');
  }

  void _toggleAchievementsVisibility() {
    // TODO: Toggle achievements visibility
    print('Toggle achievements visibility');
  }

  void _toggleOnlineStatus() {
    // TODO: Toggle online status
    print('Toggle online status');
  }

  void _showDataUsageInfo() {
    // TODO: Show data usage information
    print('Show data usage info');
  }

  void _changePassword() {
    // TODO: Navigate to change password screen
    print('Change password');
  }

  void _adjustTextSize() {
    // TODO: Show text size adjustment
    print('Adjust text size');
  }

  void _toggleHighContrast() {
    // TODO: Toggle high contrast
    print('Toggle high contrast');
  }

  void _toggleReduceMotion() {
    // TODO: Toggle reduce motion
    print('Toggle reduce motion');
  }

  void _toggleScreenReader() {
    // TODO: Toggle screen reader
    print('Toggle screen reader');
  }

  void _setColorBlindSupport() {
    // TODO: Show color blind support options
    print('Set color blind support');
  }

  void _showTermsOfService() {
    // TODO: Show terms of service
    print('Show terms of service');
  }

  void _showPrivacyPolicy() {
    // TODO: Show privacy policy
    print('Show privacy policy');
  }

  void _showHelpSupport() {
    // TODO: Show help and support
    print('Show help and support');
  }

  void _sendFeedback() {
    // TODO: Show feedback form
    print('Send feedback');
  }

  void _rateApp() {
    // TODO: Open app store rating
    print('Rate app');
  }
}
