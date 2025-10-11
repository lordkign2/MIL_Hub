import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failure.dart';
import '../entities/link_check_entity.dart';
import '../repositories/link_check_repository.dart';

class FindPreviousCheckUseCase {
  final LinkCheckRepository repository;

  FindPreviousCheckUseCase(this.repository);

  Future<Either<Failure, LinkCheckEntity?>> call(String url) async {
    try {
      final linkCheck = await repository.findPreviousCheck(url);
      return Right(linkCheck);
    } on FirebaseAuthException catch (e) {
      return Left(Failure(e.message ?? 'Authentication error'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
