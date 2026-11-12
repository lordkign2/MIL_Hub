import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/analyze_link_usecase.dart';
import '../../domain/usecases/save_link_check_usecase.dart';
import '../../domain/usecases/get_recent_link_checks_usecase.dart';
import '../../domain/usecases/get_user_link_checks_usecase.dart';
import '../../domain/usecases/find_previous_check_usecase.dart';
import '../../domain/usecases/check_image_authenticity_usecase.dart';
import 'check_event.dart';
import 'check_state.dart';

class CheckBloc extends Bloc<CheckEvent, CheckState> {
  final AnalyzeLinkUseCase analyzeLinkUseCase;
  final SaveLinkCheckUseCase saveLinkCheckUseCase;
  final GetRecentLinkChecksUseCase getRecentLinkChecksUseCase;
  final GetUserLinkChecksUseCase getUserLinkChecksUseCase;
  final FindPreviousCheckUseCase findPreviousCheckUseCase;
  final CheckImageAuthenticityUseCase checkImageAuthenticityUseCase;

  CheckBloc({
    required this.analyzeLinkUseCase,
    required this.saveLinkCheckUseCase,
    required this.getRecentLinkChecksUseCase,
    required this.getUserLinkChecksUseCase,
    required this.findPreviousCheckUseCase,
    required this.checkImageAuthenticityUseCase,
  }) : super(CheckInitial()) {
    on<AnalyzeLinkEvent>((event, emit) async {
      emit(CheckLoading());
      final result = await analyzeLinkUseCase(event.url);
      result.fold(
        (failure) => emit(CheckError(failure.message)),
        (assessment) => emit(LinkAnalyzed(assessment)),
      );
    });
    on<AnalyzeImageEvent>((event, emit) async {
      emit(CheckLoading());
      final result = await checkImageAuthenticityUseCase(event.imagePath);
      result.fold(
        (failure) => emit(CheckError(failure.message)),
        (assessment) => emit(ImageAnalyzed(assessment)),
      );
    });
    on<SaveLinkCheckEvent>((event, emit) async {
      emit(CheckLoading());
      final result = await saveLinkCheckUseCase(event.assessment);
      result.fold(
        (failure) => emit(CheckError(failure.message)),
        (_) => emit(LinkCheckSaved()),
      );
    });
    on<GetRecentLinkChecksEvent>((event, emit) async {
      emit(CheckLoading());
      await emit.forEach(
        getRecentLinkChecksUseCase(limit: event.limit),
        onData: (result) {
          return result.fold(
            (failure) => CheckError(failure.message),
            (linkChecks) => RecentLinkChecksLoaded(linkChecks),
          );
        },
      );
    });
    on<GetUserLinkChecksEvent>((event, emit) async {
      emit(CheckLoading());
      await emit.forEach(
        getUserLinkChecksUseCase(limit: event.limit),
        onData: (result) {
          return result.fold(
            (failure) => CheckError(failure.message),
            (linkChecks) => UserLinkChecksLoaded(linkChecks),
          );
        },
      );
    });
    on<FindPreviousCheckEvent>((event, emit) async {
      emit(CheckLoading());
      final result = await findPreviousCheckUseCase(event.url);
      result.fold(
        (failure) => emit(CheckError(failure.message)),
        (linkCheck) => emit(PreviousCheckFound(linkCheck)),
      );
    });
    on<ClearCheckStateEvent>((event, emit) {
      emit(CheckCleared());
    });
  }
}
