import '../../domain/entities/link_check_entity.dart';

abstract class CheckState {}

class CheckInitial extends CheckState {}

class CheckLoading extends CheckState {}

class LinkAnalyzed extends CheckState {
  final LinkAssessmentEntity assessment;

  LinkAnalyzed(this.assessment);
}

class LinkCheckSaved extends CheckState {}

class RecentLinkChecksLoaded extends CheckState {
  final List<LinkCheckEntity> linkChecks;

  RecentLinkChecksLoaded(this.linkChecks);
}

class UserLinkChecksLoaded extends CheckState {
  final List<LinkCheckEntity> linkChecks;

  UserLinkChecksLoaded(this.linkChecks);
}

class PreviousCheckFound extends CheckState {
  final LinkCheckEntity? linkCheck;

  PreviousCheckFound(this.linkCheck);
}

class CheckError extends CheckState {
  final String message;

  CheckError(this.message);
}

class CheckCleared extends CheckState {}
