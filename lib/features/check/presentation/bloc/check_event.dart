import '../../domain/entities/link_check_entity.dart';

abstract class CheckEvent {}

class AnalyzeLinkEvent extends CheckEvent {
  final String url;

  AnalyzeLinkEvent(this.url);
}

class SaveLinkCheckEvent extends CheckEvent {
  final LinkAssessmentEntity assessment;

  SaveLinkCheckEvent(this.assessment);
}

class GetRecentLinkChecksEvent extends CheckEvent {
  final int limit;

  GetRecentLinkChecksEvent({this.limit = 20});
}

class GetUserLinkChecksEvent extends CheckEvent {
  final int limit;

  GetUserLinkChecksEvent({this.limit = 50});
}

class FindPreviousCheckEvent extends CheckEvent {
  final String url;

  FindPreviousCheckEvent(this.url);
}

class ClearCheckStateEvent extends CheckEvent {}
