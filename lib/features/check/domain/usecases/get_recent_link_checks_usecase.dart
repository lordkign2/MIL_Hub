import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failure.dart';
import '../entities/link_check_entity.dart';
import '../repositories/link_check_repository.dart';

class GetRecentLinkChecksUseCase {
  final LinkCheckRepository repository;

  GetRecentLinkChecksUseCase(this.repository);

  Stream<Either<Failure, List<LinkCheckEntity>>> call({int limit = 20}) {
    return repository
        .getRecentLinkChecks(limit: limit)
        .map((linkChecks) => Right<Failure, List<LinkCheckEntity>>(linkChecks))
        .handleError((error) {
          if (error is FirebaseAuthException) {
            return Stream.value(
              Left<Failure, List<LinkCheckEntity>>(
                Failure(error.message ?? 'Authentication error'),
              ),
            );
          }
          return Stream.value(
            Left<Failure, List<LinkCheckEntity>>(Failure(error.toString())),
          );
        });
  }
}
