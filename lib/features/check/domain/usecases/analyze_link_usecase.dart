import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failure.dart';
import '../entities/link_check_entity.dart';
import '../repositories/link_check_repository.dart';

class AnalyzeLinkUseCase {
  final LinkCheckRepository repository;

  AnalyzeLinkUseCase(this.repository);

  Future<Either<Failure, LinkAssessmentEntity>> call(String url) async {
    try {
      final assessment = await repository.analyzeLink(url);
      return Right(assessment);
    } on FirebaseAuthException catch (e) {
      return Left(Failure(e.message ?? 'Authentication error'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
