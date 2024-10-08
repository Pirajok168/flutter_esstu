import 'dart:async';



import '../logger/custom_exception.dart';
import '../logger/errors.dart';
import '../logger/logger.dart';
import '../main_repository.dart';
import '../models/schedule_model.dart';
import '../static/lesson_builder.dart';
import '../static/schedule_type.dart';

class Parser {
  final MainRepository repository;

  Parser(this.repository);

  Future<ScheduleModel> updateSchedule({
    required String link1,
    String? link2,
    required String scheduleName,
    required String scheduleType,
    bool isZo = false,
  }) async {
    final pagesList = <String>[];

    try {
      pagesList.add(await repository.loadPage(link1));
      if (link2 != null) {
        pagesList.add(await repository.loadPage(link2));
      }
    } catch (e, stack) {
      Logger.error(title: Errors.update, exception: e, stack: stack);

      throw CustomException(message: Errors.update);
    }

    if (!pagesList[0].contains(scheduleName) &&
        (pagesList.length < 2 || !pagesList[1].contains(scheduleName))) {
      final text =
          'Расписание "$scheduleName" не найдено по сохраненной ссылке. '
          '1:"$link1", 2:"$link2"';
      Logger.warning(title: Errors.update, exception: text);

      throw CustomException(message: text);
    }

    return scheduleModel(
      link1: link1,
      link2: link2,
      page1: pagesList[0],
      page2: pagesList.length > 1 ? pagesList[1] : null,
      scheduleName: scheduleName,
      scheduleType: scheduleType,
      isZo: isZo,
    );
  }

  /// Парсинг страницы с расписанием и превращение ее в модель
  Future<ScheduleModel> scheduleModel({
    required String link1,
    String? link2,
    String? page1,
    String? page2,
    required String scheduleName,
    required String scheduleType,
    bool isZo = false,
  }) async {
    final numOfLessons = isZo ? 7 : 6;

    final pagesList = <String>[];
    try {
      pagesList.add(page1 ?? await repository.loadPage(link1));
      if (page2 != null) {
        pagesList.add(page2);
      } else if (link2 != null) {
        pagesList.add(await repository.loadPage(link2));
      }
    } catch (e, stack) {
      Logger.error(title: Errors.pageLoading, exception: e, stack: stack);

      throw CustomException(message: Errors.pageLoading);
    }

    final ScheduleModel scheduleModel = ScheduleModel(
      name: scheduleName,
      type: scheduleType,
      weeks: [],
      link1: link1,
      link2: link2,
    );

    try {
      for (String page in pagesList) {
        String? scheduleBeginning;
        if (scheduleType == ScheduleType.teacher) {
          if (page.contains(scheduleName)) {
            scheduleBeginning = page.split(scheduleName).elementAt(1);
          }
        } else {
          scheduleBeginning = page;
        }

        if (scheduleBeginning == null) continue;

        final splittedPage = scheduleType == ScheduleType.teacher
            ? scheduleBeginning
                .substring(0, scheduleBeginning.indexOf('</TABLE>'))
                .replaceAll(' COLOR="#0000ff"', '')
                .split('SIZE=2><P ALIGN="CENTER">')
                .skip(1)
            : scheduleBeginning
                .replaceAll(' COLOR="#0000ff"', '')
                .split('SIZE=2><P ALIGN="CENTER">')
                .skip(1);

        int dayOfWeekIndex = 0;
        for (String dayOfWeek in splittedPage) {
          String? dayOfWeekDate;
          if (isZo) {
            final lastIndex = dayOfWeek.indexOf('</B>');
            dayOfWeekDate = lastIndex > 0
                ? dateFromZoDayOfWeek(dayOfWeek.substring(0, lastIndex).trim())
                : null;
          }
          final lessons = dayOfWeek.split('"CENTER">').skip(1);

          int lessonIndex = 0;
          for (String lessonSection in lessons) {
            final lesson = lessonSection
                .substring(0, lessonSection.indexOf('</FONT>'))
                .trim();

            final lessonChecker =
                lesson.replaceAll(RegExp(r'[^0-9а-яА-Я]'), '');

            if (lessonChecker.isEmpty) {
              if (++lessonIndex >= numOfLessons) break;
              continue;
            }

            scheduleModel.updateWeek(
              dayOfWeekIndex ~/ numOfLessons,
              dayOfWeekIndex % numOfLessons,
              lessonIndex,
              scheduleType == ScheduleType.teacher
                  ? LessonBuilder.createTeacherLesson(
                      lessonNumber: lessonIndex + 1,
                      lesson: lesson,
                    )
                  : LessonBuilder.createStudentLesson(
                      lessonNumber: lessonIndex + 1,
                      lesson: lesson,
                    ),
              dayOfWeekDate: dayOfWeekDate,
            );

            if (++lessonIndex >= numOfLessons) break;
          }

          dayOfWeekIndex++;
        }
      }

      if (scheduleModel.isEmpty) {
        Logger.warning(
          title: Errors.scheduleModel,
          exception: 'Модель расписания пуста. scheduleModel.isEmpty',
        );
      }

      return scheduleModel;
    } catch (e, stack) {
      Logger.error(
        title: Errors.scheduleModel,
        exception: e,
        stack: stack,
      );

      throw CustomException(message: Errors.scheduleModel);
    }
  }

  String? dateFromZoDayOfWeek(String? dayOfWeek) {
    if (dayOfWeek == null) return null;

    final splittedDayOfWeek = dayOfWeek.split(RegExp(r'\s+'));
    if (splittedDayOfWeek.length < 2) return null;

    final day = splittedDayOfWeek[0].contains(',')
        ? splittedDayOfWeek[0].split(',')[1]
        : splittedDayOfWeek[0];

    final month = splittedDayOfWeek[1];

    if (month.contains('янв') || month.contains('ЯНВ')) return '$day.01';
    if (month.contains('фев') || month.contains('ФЕВ')) return '$day.02';
    if (month.contains('мар') || month.contains('МАР')) return '$day.03';
    if (month.contains('апр') || month.contains('АПР')) return '$day.04';
    if (month.contains('мая') ||
        month.contains('МАЯ') ||
        month.contains('май') ||
        month.contains('МАЙ')) {
      return '$day.05';
    }
    if (month.contains('июн') || month.contains('ИЮН')) return '$day.06';
    if (month.contains('июл') || month.contains('ИЮЛ')) return '$day.07';
    if (month.contains('авг') || month.contains('АВГ')) return '$day.08';
    if (month.contains('сен') || month.contains('СЕН')) return '$day.09';
    if (month.contains('окт') || month.contains('ОКТ')) return '$day.10';
    if (month.contains('ноя') || month.contains('НОЯ')) return '$day.11';
    if (month.contains('дек') || month.contains('ДЕК')) return '$day.12';

    return null;
  }
}
