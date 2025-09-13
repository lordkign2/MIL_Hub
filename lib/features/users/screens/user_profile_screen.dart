import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart'; // TODO: Add image_picker dependency
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  final Color themeColor;

  const UserProfileScreen({super.key, this.themeColor = Colors.purple});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadUserProfile();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> _loadUserProfile() async {
    try {
      UserService.getCurrentUserProfile().listen((profile) {
        if (profile != null) {
          setState(() {
            _userProfile = profile;
            _displayNameController.text = profile.displayName;
            _bioController.text = profile.bio ?? '';
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
    _displayNameController.dispose();
    _bioController.dispose();
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
      body: CustomScrollView(slivers: [_buildAppBar(), _buildProfileContent()]),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
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
                    bottom: 30,
                    top: 100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Profile Image
                      Hero(
                        tag: 'profile_image',
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _userProfile?.photoURL != null
                                    ? Image.network(
                                        _userProfile!.photoURL!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return _buildDefaultAvatar();
                                            },
                                      )
                                    : _buildDefaultAvatar(),
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _changeProfilePhoto,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.themeColor,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // User Info
                      if (_isEditing)
                        _buildEditableInfo()
                      else
                        _buildDisplayInfo(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          )
        else
          IconButton(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.themeColor.withOpacity(0.7), widget.themeColor],
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 60),
    );
  }

  Widget _buildDisplayInfo() {
    return Column(
      children: [
        Text(
          _userProfile?.displayName ?? 'User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _userProfile?.email ?? '',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        if (_userProfile?.bio?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            _userProfile!.bio!,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoChip(
              'Level ${_userProfile?.stats.level ?? 1}',
              Icons.star_rounded,
              Colors.amber,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              _getRoleDisplayName(_userProfile?.role ?? UserRole.student),
              Icons.person_rounded,
              widget.themeColor,
            ),
            if (_userProfile?.subscription.isPremium == true) ...[
              const SizedBox(width: 8),
              _buildInfoChip('Premium', Icons.diamond_rounded, Colors.purple),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEditableInfo() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Display Name Field
          TextFormField(
            controller: _displayNameController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Display Name',
              hintStyle: TextStyle(color: Colors.white60),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            validator: (value) {
              if (value?.trim().isEmpty == true) {
                return 'Display name cannot be empty';
              }
              return null;
            },
          ),

          const SizedBox(height: 8),

          Text(
            _userProfile?.email ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Bio Field
          TextFormField(
            controller: _bioController,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            maxLength: 150,
            decoration: const InputDecoration(
              hintText: 'Write something about yourself...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              counterStyle: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
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
                  _buildStatsSection(),
                  _buildPreferencesSection(),
                  _buildAccountSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: widget.themeColor),
              const SizedBox(width: 12),
              const Text(
                'Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Lessons Completed',
                  '${_userProfile?.stats.totalLessonsCompleted ?? 0}',
                  Icons.school_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total Points',
                  '${_userProfile?.stats.totalPoints ?? 0}',
                  Icons.stars_rounded,
                  Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Current Streak',
                  '${_userProfile?.stats.currentStreak ?? 0} days',
                  Icons.local_fire_department_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Time Spent',
                  '${(_userProfile?.stats.totalTimeSpent ?? 0) ~/ 60}h',
                  Icons.schedule_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.themeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: widget.themeColor),
              const SizedBox(width: 12),
              const Text(
                'Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildPreferenceItem(
            'Learning Goal',
            '${_userProfile?.preferences.learningPreferences.dailyGoal ?? 30} minutes/day',
            Icons.flag_rounded,
            () => _editLearningGoal(),
          ),
          _buildPreferenceItem(
            'Preferred Topics',
            _userProfile
                        ?.preferences
                        .learningPreferences
                        .favoriteTopics
                        .isEmpty ==
                    true
                ? 'Not set'
                : '${_userProfile?.preferences.learningPreferences.favoriteTopics.length} selected',
            Icons.topic_rounded,
            () => _editTopics(),
          ),
          _buildPreferenceItem(
            'Notifications',
            _userProfile?.preferences.notifications == true
                ? 'Enabled'
                : 'Disabled',
            Icons.notifications_rounded,
            () => _navigateToNotificationSettings(),
          ),
          _buildPreferenceItem(
            'Privacy',
            'Manage privacy settings',
            Icons.security_rounded,
            () => _navigateToPrivacySettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: widget.themeColor, size: 24),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_circle_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildAccountItem(
            'Member Since',
            _formatJoinDate(_userProfile?.joinedDate),
            Icons.cake_rounded,
            null,
          ),
          _buildAccountItem(
            'Account ID',
            _userProfile?.uid ?? '',
            Icons.badge_rounded,
            null,
          ),
          _buildAccountItem(
            'Export Data',
            'Download your data',
            Icons.download_rounded,
            () => _exportUserData(),
          ),
          _buildAccountItem(
            'Delete Account',
            'Permanently delete account',
            Icons.delete_forever_rounded,
            () => _showDeleteAccountDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.educator:
        return 'Educator';
      case UserRole.admin:
        return 'Admin';
      case UserRole.moderator:
        return 'Moderator';
    }
  }

  String _formatJoinDate(DateTime? joinDate) {
    if (joinDate == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(joinDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  Future<void> _changeProfilePhoto() async {
    try {
      // TODO: Implement image picker when package is available
      /*
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // TODO: Upload image to storage and update profile
        print('Selected image: ${image.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      */

      // Placeholder implementation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo upload feature coming soon!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to access camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedProfile = _userProfile!.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      await UserService.createOrUpdateUserProfile(updatedProfile);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editLearningGoal() {
    // TODO: Show learning goal edit dialog
    print('Edit learning goal');
  }

  void _editTopics() {
    // TODO: Show topics selection dialog
    print('Edit topics');
  }

  void _navigateToNotificationSettings() {
    // TODO: Navigate to notification settings
    print('Navigate to notification settings');
  }

  void _navigateToPrivacySettings() {
    // TODO: Navigate to privacy settings
    print('Navigate to privacy settings');
  }

  void _exportUserData() {
    // TODO: Implement data export
    print('Export user data');
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await UserService.deleteUserAccount();
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
