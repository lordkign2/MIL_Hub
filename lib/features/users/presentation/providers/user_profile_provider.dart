import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user_profile_model.dart';
import '../../services/user_service.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<UserProfile?>? _profileSubscription;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProfileProvider() {
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _profileSubscription = UserService.getCurrentUserProfile().listen(
      (profile) {
        _userProfile = profile;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Triggers the camera/gallery picker and saves the file locally in the App Documents dir.
  Future<void> updateProfilePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && _userProfile != null) {
        // Since firebase isn't wired for storage yet, save to the local documents directory persistently.
        final appDir = await getApplicationDocumentsDirectory();
        
        // Generate a unique filename using timestamp
        final fileName = 'avatar_${_userProfile!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        
        // Push the physical path string into the profile model and save it via our user service.
        final updatedProfile = _userProfile!.copyWith(photoURL: savedImage.path);
        await UserService.createOrUpdateUserProfile(updatedProfile);
        
        // The active Firestore stream will intercept this DB update and naturally feed the new URL back into our state!
      }
    } catch (e) {
      _errorMessage = 'Failed to update photo: $e';
      notifyListeners();
      
      // Auto-clear message
      Future.delayed(const Duration(seconds: 4), () {
        _errorMessage = null;
        notifyListeners();
      });
    }
  }

  Future<void> saveProfileDetails(String displayName, String bio) async {
    if (_userProfile == null) return;
    
    try {
      final updatedProfile = _userProfile!.copyWith(
        displayName: displayName,
        bio: bio.trim().isEmpty ? null : bio,
      );
      await UserService.createOrUpdateUserProfile(updatedProfile);
    } catch (e) {
      _errorMessage = 'Failed to save profile details: $e';
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 4), () {
        _errorMessage = null;
        notifyListeners();
      });
      rethrow; // So the UI controller can catch and stop its loading spinner
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel(); // Fix the memory leak!
    super.dispose();
  }
}
