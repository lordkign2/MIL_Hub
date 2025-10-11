import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failure.dart';
import '../entities/link_check_entity.dart';
import '../repositories/link_check_repository.dart';

class SaveLinkCheckUseCase {
  final LinkCheckRepository repository;

  SaveLinkCheckUseCase(this.repository);

  Future<Either<Failure, void>> call(LinkAssessmentEntity assessment) async {
    try {
      await repository.saveLinkCheck(assessment);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(Failure(e.message ?? 'Authentication error'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
