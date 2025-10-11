import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failure.dart';
import '../entities/link_check_entity.dart';
import '../repositories/link_check_repository.dart';

class CheckImageAuthenticityUseCase {
  final ImageAuthenticityRepository repository;

  CheckImageAuthenticityUseCase(this.repository);

  Future<Either<Failure, ImageAuthenticityEntity>> call(
    String imagePath,
  ) async {
    try {
      final result = await repository.checkImageAuthenticity(imagePath);
      return Right(result);
    } on FirebaseAuthException catch (e) {
      return Left(Failure(e.message ?? 'Authentication error'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
