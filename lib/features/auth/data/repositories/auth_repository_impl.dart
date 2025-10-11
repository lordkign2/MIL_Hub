import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo;

  @override
  Future<({UserEntity? user, Failure? failure})> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final userModel = await _remoteDataSource.signUpWithEmail(
          email: email,
          password: password,
        );
        return (user: userModel.toEntity(), failure: null);
      } on AuthException catch (e) {
        return (user: null, failure: AuthFailure(message: e.message));
      } on NetworkException catch (e) {
        return (user: null, failure: NetworkFailure(message: e.message));
      } on ServerException catch (e) {
        return (user: null, failure: ServerFailure(message: e.message));
      } catch (e) {
        return (
          user: null,
          failure: UnknownFailure(message: 'An unexpected error occurred: $e'),
        );
      }
    } else {
      return (
        user: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({UserEntity? user, Failure? failure})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final userModel = await _remoteDataSource.signInWithEmail(
          email: email,
          password: password,
        );
        return (user: userModel.toEntity(), failure: null);
      } on AuthException catch (e) {
        return (user: null, failure: AuthFailure(message: e.message));
      } on NetworkException catch (e) {
        return (user: null, failure: NetworkFailure(message: e.message));
      } on ServerException catch (e) {
        return (user: null, failure: ServerFailure(message: e.message));
      } catch (e) {
        return (
          user: null,
          failure: UnknownFailure(message: 'An unexpected error occurred: $e'),
        );
      }
    } else {
      return (
        user: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({UserEntity? user, Failure? failure})> signInWithGoogle() async {
    if (await _networkInfo.isConnected) {
      try {
        final userModel = await _remoteDataSource.signInWithGoogle();
        return (user: userModel.toEntity(), failure: null);
      } on AuthException catch (e) {
        return (user: null, failure: AuthFailure(message: e.message));
      } on NetworkException catch (e) {
        return (user: null, failure: NetworkFailure(message: e.message));
      } on ServerException catch (e) {
        return (user: null, failure: ServerFailure(message: e.message));
      } catch (e) {
        return (
          user: null,
          failure: UnknownFailure(message: 'An unexpected error occurred: $e'),
        );
      }
    } else {
      return (
        user: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return (success: true, failure: null);
    } on AuthException catch (e) {
      return (success: false, failure: AuthFailure(message: e.message));
    } catch (e) {
      return (
        success: false,
        failure: UnknownFailure(message: 'Failed to sign out: $e'),
      );
    }
  }

  @override
  UserEntity? getCurrentUser() {
    try {
      final userModel = _remoteDataSource.getCurrentUser();
      return userModel?.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((userModel) {
      return userModel?.toEntity();
    });
  }

  @override
  bool get isSignedIn => _remoteDataSource.isSignedIn;

  @override
  Future<({bool success, Failure? failure})> sendPasswordResetEmail({
    required String email,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.sendPasswordResetEmail(email: email);
        return (success: true, failure: null);
      } on AuthException catch (e) {
        return (success: false, failure: AuthFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(
            message: 'Failed to send password reset email: $e',
          ),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({UserEntity? user, Failure? failure})> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final userModel = await _remoteDataSource.updateUserProfile(
          displayName: displayName,
          photoUrl: photoUrl,
        );
        return (user: userModel.toEntity(), failure: null);
      } on AuthException catch (e) {
        return (user: null, failure: AuthFailure(message: e.message));
      } on NetworkException catch (e) {
        return (user: null, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          user: null,
          failure: UnknownFailure(message: 'Failed to update profile: $e'),
        );
      }
    } else {
      return (
        user: null,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> deleteAccount() async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.deleteAccount();
        return (success: true, failure: null);
      } on AuthException catch (e) {
        return (success: false, failure: AuthFailure(message: e.message));
      } on NetworkException catch (e) {
        return (success: false, failure: NetworkFailure(message: e.message));
      } catch (e) {
        return (
          success: false,
          failure: UnknownFailure(message: 'Failed to delete account: $e'),
        );
      }
    } else {
      return (
        success: false,
        failure: const NetworkFailure(message: 'No internet connection'),
      );
    }
  }
}
