import 'package:firebase_auth/firebase_auth.dart';
import '../entities/link_check_entity.dart';

abstract class LinkCheckRepository {
  /// Performs comprehensive link analysis
  Future<LinkAssessmentEntity> analyzeLink(String url);

  /// Save link check to Firestore
  Future<void> saveLinkCheck(LinkAssessmentEntity assessment);

  /// Get recent link checks from the community
  Stream<List<LinkCheckEntity>> getRecentLinkChecks({int limit = 20});

  /// Get user's link check history
  Stream<List<LinkCheckEntity>> getUserLinkChecks({int limit = 50});

  /// Search for previously checked URLs
  Future<LinkCheckEntity?> findPreviousCheck(String url);
}

abstract class ImageAuthenticityRepository {
  /// Check image authenticity using reverse image search APIs
  Future<ImageAuthenticityEntity> checkImageAuthenticity(String imagePath);
}
