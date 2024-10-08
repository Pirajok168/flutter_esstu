import 'dart:convert';

import 'package:collection/collection.dart';


import '../static/schedule_time_data.dart';
import 'day_of_week_model.dart';
import 'lesson_model.dart';

class WeekModel {
  final int weekNumber;
  final List<DayOfWeekModel> daysOfWeek;

  final String? weekDate;

  WeekModel({
    required this.weekNumber,
    required this.daysOfWeek,
    this.weekDate,
  });

  @override
  toString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'daysOfWeek': daysOfWeek,
        'weekDate': weekDate,
      };

  static WeekModel fromJson(Map<String, dynamic> json) {
    List<DayOfWeekModel> daysOfWeeksFromJson(List<dynamic> list) {
      final List<DayOfWeekModel> newList = [];
      for (var dayOfWeek in list) {
        newList.add(DayOfWeekModel.fromJson(dayOfWeek));
      }
      return newList;
    }

    return WeekModel(
      weekNumber: json['weekNumber'],
      daysOfWeek: daysOfWeeksFromJson(json['daysOfWeek']),
      weekDate: json['weekDate'],
    );
  }

  /// Добавляет пару в день недели.
  /// Если день недели существует, то записывает в него, иначе создает новый.
  /// Если пара уже существует, то перезаписывает, если новая длиннее
  void updateDayOfWeek(int dayOfWeekIndex, Lesson lesson,
      {String? dayOfWeekDate}) {
    final sameDay = daysOfWeek.firstWhereOrNull(
        (element) => element.dayOfWeekIndex == dayOfWeekIndex);

    if (sameDay != null) {
      sameDay.updateLesson(lesson);
      return;
    }

    daysOfWeek.add(DayOfWeekModel(
      dayOfWeekNumber: dayOfWeekIndex + 1,
      dayOfWeekName: ScheduleTimeData.daysOfWeekShort[dayOfWeekIndex],
      lessons: [],
      dayOfWeekDate: dayOfWeekDate,
    )..updateLesson(lesson));
    daysOfWeek.sort((a, b) => a.dayOfWeekNumber.compareTo(b.dayOfWeekNumber));
  }

  /// Индекс дня недели с учетом возможного отсутствия некоторых
  /// дней недели. [weekIndex] - номер недели, в которой ищем день.
  /// [dayOfWeekIndex] - индекс дня недели с ScheduleTimeData.
  /// Если индекс не найден, возвращает 0
  int dayOfWeekByAbsoluteIndex(int dayOfWeekIndex) {
    final findedDayOfWeek = daysOfWeek.firstWhereOrNull(
        (element) => element.dayOfWeekIndex == dayOfWeekIndex);
    if (findedDayOfWeek == null) return 0;
    return daysOfWeek.indexOf(findedDayOfWeek);
  }

  int get weekIndex => weekNumber - 1;

  int get weekLength => daysOfWeek.length;

  DayOfWeekModel at(int index) => daysOfWeek[index];
}
