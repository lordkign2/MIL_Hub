import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/link_check_entity.dart';
import '../../domain/repositories/link_check_repository.dart';
import '../datasources/link_check_remote_datasource.dart';
import '../models/link_check_model.dart';

class LinkCheckRepositoryImpl implements LinkCheckRepository {
  final LinkCheckRemoteDataSource remoteDataSource;

  LinkCheckRepositoryImpl({required this.remoteDataSource});

  @override
  Future<LinkAssessmentEntity> analyzeLink(String url) async {
    try {
      final linkAssessment = await remoteDataSource.analyzeLink(url);
      return linkAssessment.toEntity();
    } on FirebaseAuthException catch (e) {
      throw Failure(e.message ?? 'Authentication error');
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Future<void> saveLinkCheck(LinkAssessmentEntity assessment) async {
    try {
      final linkAssessmentModel = LinkAssessmentModel.fromEntity(assessment);
      await remoteDataSource.saveLinkCheck(linkAssessmentModel);
    } on FirebaseAuthException catch (e) {
      throw Failure(e.message ?? 'Authentication error');
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Stream<List<LinkCheckEntity>> getRecentLinkChecks({int limit = 20}) {
    try {
      return remoteDataSource
          .getRecentLinkChecks(limit: limit)
          .map(
            (linkChecks) =>
                linkChecks.map((check) => check.toEntity()).toList(),
          );
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Stream<List<LinkCheckEntity>> getUserLinkChecks({int limit = 50}) {
    try {
      return remoteDataSource
          .getUserLinkChecks(limit: limit)
          .map(
            (linkChecks) =>
                linkChecks.map((check) => check.toEntity()).toList(),
          );
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Future<LinkCheckEntity?> findPreviousCheck(String url) async {
    try {
      final linkCheck = await remoteDataSource.findPreviousCheck(url);
      return linkCheck?.toEntity();
    } on FirebaseAuthException catch (e) {
      throw Failure(e.message ?? 'Authentication error');
    } catch (e) {
      throw Failure(e.toString());
    }
  }
}

class ImageAuthenticityRepositoryImpl implements ImageAuthenticityRepository {
  @override
  Future<ImageAuthenticityEntity> checkImageAuthenticity(String imagePath) {
    // TODO: Implement image authenticity check
    throw UnimplementedError();
  }
}
