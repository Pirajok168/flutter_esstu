import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';


import '../../../core/logger/custom_exception.dart';
import '../../../core/logger/errors.dart';
import '../../../core/logger/logger.dart';
import '../../../core/parser/teachers_parser.dart';

part 'faculty_event.dart';
part 'faculty_state.dart';

class FacultyBloc extends Bloc<FacultyEvent, FacultyState> {
  final TeachersParser _parser;

  FacultyBloc(TeachersParser parser)
      : _parser = parser,
        super(FacultyInitial()) {
    on<LoadFaculties>(_loadFaculties);
    on<ChooseFaculty>(_chooseFaculty);
  }

  Future<void> _loadFaculties(
      LoadFaculties event, Emitter<FacultyState> emit) async {
    emit(FacultiesLoading());
    try {
      final facultyDepartmentLinkMap =
          await _parser.facultyDepartmentLinksMap();

      emit(FacultiesLoaded(
          facultyDepartmentLinkMap: facultyDepartmentLinkMap));
    } on CustomException catch (e) {
      emit(FacultiesError(e.message));
    } catch (e, stack) {
      Logger.error(title: Errors.teachersSchedule, exception: e, stack: stack);
      emit(FacultiesError('Ошибка: ${e.runtimeType}'));
    }
  }

  Future<void> _chooseFaculty(
      ChooseFaculty event, Emitter<FacultyState> emit) async {
    emit(CurrentFacultyLoaded(
      facultyName: event.facultyName,
      departmentsMap: event.departmentsMap,
      facultyDepartmentLinkMap: state.facultyDepartmentLinkMap ?? {},
    ));
  }
}
