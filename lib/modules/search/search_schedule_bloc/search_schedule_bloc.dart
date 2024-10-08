import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../core/logger/custom_exception.dart';
import '../../../core/logger/errors.dart';
import '../../../core/logger/logger.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/parser/parser.dart';

part 'search_schedule_event.dart';

part 'search_schedule_state.dart';

class SearchScheduleBloc
    extends Bloc<SearchScheduleEvent, SearchScheduleState> {
  final Parser _parser;

  SearchScheduleBloc(Parser parser)
      : _parser = parser,
        super(SearchScheduleInitial()) {
    on<LoadSearchingSchedule>(_loadSearchingSchedule);
  }

  Future<void> _loadSearchingSchedule(
      LoadSearchingSchedule event, Emitter<SearchScheduleState> emit) async {
    emit(SearchScheduleLoading(appBarName: event.scheduleName));

    try {
      final scheduleModel = await _parser.scheduleModel(
        link1: event.link1,
        link2: event.link2,
        scheduleName: event.scheduleName,
        scheduleType: event.scheduleType,
        isZo: event.link1.contains('zo'),
      );

      emit(SearchScheduleLoaded(
        scheduleModel: scheduleModel,
        appBarName: event.scheduleName,
      ));
    } on CustomException catch (e) {
      emit(SearchScheduleError(e.message));
    } catch (e, stack) {
      Logger.error(title: Errors.schedule, exception: e, stack: stack);
      emit(SearchScheduleError('Ошибка: ${e.runtimeType}'));
    }
  }
}
