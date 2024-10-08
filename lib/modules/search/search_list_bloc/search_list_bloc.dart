import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../core/logger/custom_exception.dart';
import '../../../core/logger/errors.dart';
import '../../../core/logger/logger.dart';
import '../../../core/parser/students_parser.dart';
import '../../../core/parser/teachers_parser.dart';
import '../../../core/static/schedule_type.dart';


part 'search_list_event.dart';

part 'search_list_state.dart';

class SearchListBloc extends Bloc<SearchListEvent, SearchListState> {
  final TeachersParser _teachersParser;
  final StudentsParser _studentsParser;

  final _streamController = StreamController<Map<String, String>>();

  SearchListBloc(TeachersParser teachersParser, StudentsParser studentsParser)
      : _teachersParser = teachersParser,
        _studentsParser = studentsParser,
        super(SearchInitial()) {
    on<LoadSearchList>(_loadSearchList);
    on<SearchInList>(_searchInList);
  }

  Future<void> _loadSearchList(
      LoadSearchList event, Emitter<SearchListState> emit) async {
    emit(SearchListLoading());

    final Map<String, List<String>>? scheduleLinksMap;

    try {
      if (event.scheduleType == ScheduleType.student) {
        ///Учебные группы
        scheduleLinksMap = await _studentsParser.groupLinkMap();
      } else {
        ///Препода
        _streamController.stream.listen((event) {
          emit(SearchListLoading(
            percents: event['percents'] ?? '0',
            message: event['message'] ?? '',
          ));
        });

        scheduleLinksMap =
            await _teachersParser.teachersLinksMap(_streamController);
        await _streamController.close();
      }

      emit(SearchListLoaded(scheduleLinksMap: scheduleLinksMap));
    } on CustomException catch (e) {
      if (_streamController.hasListener) {
        await _streamController.close();
      }
      emit(SearchingError(e.message));
    } catch (e, stack) {
      if (_streamController.hasListener) {
        await _streamController.close();
      }
      Logger.error(title: Errors.search, exception: e, stack: stack);
      emit(SearchingError('Ошибка: ${e.runtimeType}'));
    }
  }

  Future<void> _searchInList(
      SearchInList event, Emitter<SearchListState> emit) async {
    final currentState = state;

    if (currentState is SearchListLoaded) {
      try {
        final namesList = currentState.scheduleLinksMap.keys.toList();
        namesList.removeWhere((element) =>
            !element.toUpperCase().contains(event.searchText.toUpperCase()));

        emit(currentState.copyWith(
            searchedList: namesList.take(15).toList()..sort()));
      } catch (e, stack) {
        Logger.error(title: Errors.search, exception: e, stack: stack);
        emit(SearchingError('Ошибка: ${e.runtimeType}'));
      }
    }
  }

  @override
  Future<void> close() async {
    if (_streamController.hasListener) {
      await _streamController.close();
    }
    return super.close();
  }
}
