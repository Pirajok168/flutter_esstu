import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_ui/core/parser/parser.dart';

import '../logger/custom_exception.dart';
import '../logger/errors.dart';
import '../logger/logger.dart';
import '../models/schedule_model.dart';
import '../static/lesson_builder.dart';
import '../static/schedule_links.dart';
import '../static/schedule_type.dart';


class TeachersParser extends Parser {
  TeachersParser(super.repository);

  /// Список расписаний преподов по страницам кафедр.
  Future<List<ScheduleModel>> teachersScheduleList({
    required String link1,
    String? link2,
  }) async {
    final List<ScheduleModel> teachersSchedule = [];

    try {
      final departmentsPages = [
        await repository.loadPage(link1),
        if (link2 != null) await repository.loadPage(link2),
      ];

      for (String page in departmentsPages) {
        final splittedPage =
            page.replaceAll(' COLOR="#0000ff"', '').split('ff00ff">').skip(1);

        for (String teacherSection in splittedPage) {
          final teacherName = teacherSection
              .substring(0, teacherSection.indexOf('</P>'))
              .trim();

          bool isScheduleExist = true;
          var currentScheduleModel = teachersSchedule
              .firstWhereOrNull((element) => element.name == teacherName);

          if (currentScheduleModel == null) {
            currentScheduleModel = ScheduleModel(
              name: teacherName,
              type: ScheduleType.teacher,
              weeks: [],
              link1: link1,
              link2: link2,
            );
            isScheduleExist = false;
          }

          final daysOfWeekFromPage =
              teacherSection.split('SIZE=2><P ALIGN="CENTER">').skip(1);

          int dayOfWeekIndex = 0;
          for (String dayOfWeek in daysOfWeekFromPage) {
            final lessons =
                dayOfWeek.split('SIZE=1><P ALIGN="CENTER">').skip(1);

            int lessonIndex = 0;
            for (String lessonSection in lessons) {
              final lesson = lessonSection
                  .substring(0, lessonSection.indexOf('</FONT>'))
                  .trim();

              final lessonChecker =
                  lesson.replaceAll(RegExp(r'[^0-9а-яА-Я]'), '');

              if (lessonChecker.isEmpty) {
                if (++lessonIndex > 5) break;
                continue;
              }

              currentScheduleModel.updateWeek(
                  dayOfWeekIndex ~/ 6,
                  dayOfWeekIndex % 6,
                  lessonIndex,
                  LessonBuilder.createTeacherLesson(
                    lessonNumber: lessonIndex + 1,
                    lesson: lesson,
                  ));
              if (++lessonIndex > 5) break;
            }

            if (++dayOfWeekIndex > 11) break;
          }

          if (!isScheduleExist && currentScheduleModel.isNotEmpty) {
            teachersSchedule.add(currentScheduleModel);
          }
        }
      }

      if (teachersSchedule.isEmpty) {
        Logger.warning(
          title: Errors.departmentTeachers,
          exception: 'teachersScheduleMap.isEmpty == true',
        );

        throw CustomException(message: Errors.departmentTeachers);
      }

      return teachersSchedule;
    } catch (e, stack) {
      Logger.error(
        title: Errors.schedule,
        exception: e,
        stack: stack,
      );
      throw CustomException(message: Errors.schedule);
    }
  }

  /// Мэп факультет - кафедра - список ссылок
  /// Для страницы факультетов
  Future<Map<String, Map<String, List<String>>>>
      facultyDepartmentLinksMap() async {
    try {
      String bakSiteText =
          await repository.loadPage(ScheduleLinks.allBakFaculties);
      String magSiteText =
          await repository.loadPage(ScheduleLinks.allMagFaculties);

      int facultyWordExistingCheck = 0;
      Iterable<String> bakSiteList = [], magSiteList = [];

      if (bakSiteText.contains('faculty')) {
        bakSiteList = bakSiteText
            .replaceAll(RegExp(r"<!--.*-->"), '')
            .split('faculty')
            .skip(1);
      } else {
        facultyWordExistingCheck++;
      }

      if (magSiteText.contains('faculty')) {
        magSiteList = magSiteText
            .replaceAll(RegExp(r"<!--.*-->"), '')
            .split('faculty')
            .skip(1);
      } else {
        facultyWordExistingCheck++;
      }

      if (facultyWordExistingCheck > 1) {
        Logger.error(
          title: Errors.pageParsing,
          exception:
              'Возможно, проблемы с доступом к сайту\nfacultyWordExistingCheck = 2',
        );

        throw CustomException(message: Errors.pageParsing);
      }

      final Map<String, Map<String, List<String>>> facultyMap = {};

      void fillMapByOneSiteText(Iterable<String> siteList, String linkName) {
        for (String facultySection in siteList) {
          String facultyName = 'Не удалось распознать название факультета';

          try {
            facultyName = facultySection.contains('id')
                ? facultySection.substring(
                    facultySection.indexOf(RegExp(r"[а-я]|[А-Я]")),
                    facultySection.indexOf('</h2>'))
                : 'Прочее';
          } catch (e, stack) {
            Logger.warning(
              title: Errors.pageParsing,
              exception: e,
              stack: stack,
            );
          }

          final Map<String, List<String>> departmentMap =
              facultyMap[facultyName] ?? {};

          final departmentsList = facultySection.split('href="').skip(1);

          for (String departmentSection in departmentsList) {
            String link = '/$linkName/0.htm';
            String departmentName =
                'Не удалось распознать ссылку и/или название кафедры';

            try {
              link =
                  '/$linkName/${departmentSection.substring(0, departmentSection.indexOf('"'))}';
              departmentName = departmentSection.substring(
                  departmentSection.indexOf(RegExp(r"[а-я]|[А-Я]")),
                  departmentSection.indexOf('<'));
            } catch (e, stack) {
              Logger.warning(
                title: Errors.pageParsing,
                exception: e,
                stack: stack,
              );
            }

            if (!departmentMap.keys.contains(departmentName)) {
              departmentMap[departmentName] = [];
            }
            departmentMap[departmentName]!.add(link);
          }

          facultyMap[facultyName] = departmentMap;
        }
      }

      fillMapByOneSiteText(bakSiteList, 'bakalavriat');
      fillMapByOneSiteText(magSiteList, 'spezialitet');

      return facultyMap;
    } catch (e, stack) {
      Logger.error(
        title: Errors.schedule,
        exception: e,
        stack: stack,
      );
      throw CustomException(message: Errors.facultiesTeachers);
    }
  }

  /// Создание мэпа корпус - список аудиторий.
  /// [streamController] - для отслеживания прогресса в блоке, после окончания
  /// обязательно закрывать
  Future<Map<String, List<ScheduleModel>>> buildingsClassroomsMap(
      StreamController<Map<String, String>> streamController) async {
    final Map<String, List<ScheduleModel>> buildingsScheduleMap = {
      '1 корпус': [],
      '2 корпус': [],
      '3 корпус': [],
      '4 корпус': [],
      '5 корпус': [],
      '6 корпус': [],
      '7 корпус': [],
      '8 корпус': [],
      '9 корпус': [],
      '10 корпус': [],
      '11 корпус': [],
      '12 корпус': [],
      '13 корпус': [],
      '14 корпус': [],
      '15 корпус': [],
    };

    /// функция заполнения buildingsScheduleMap
    void mapCreating(
      Map<String, List<ScheduleModel>> map,
      Iterable<String> splittedPage, {
      String? link,
    }) {
      int getBuildingByClassroom(String classroom) {
        if (classroom.length > 1) {
          final start = classroom.substring(0, 2);
          switch (start) {
            case '11':
              return 11;
            case '12':
              return 12;
            case '13':
              return 13;
            case '14':
              return 14;
            case '15':
              return 15;
          }
        }
        if (classroom.isNotEmpty) {
          final start = classroom[0];
          switch (start) {
            case '0':
              return 10;
            case '1':
              return 1;
            case '2':
              return 2;
            case '3':
              return 3;
            case '4':
              return 4;
            case '5':
              return 5;
            case '6':
              return 6;
            case '7':
              return 7;
            case '8':
              return 8;
            case '9':
              return 9;
          }
        }

        return 1;
      }

      ///12 дней каждого препода
      for (String teacherSection in splittedPage) {
        final teacherName =
            teacherSection.substring(0, teacherSection.indexOf('</P>')).trim();

        final daysOfWeekFromPage =
            teacherSection.split('SIZE=2><P ALIGN="CENTER">').skip(1);

        int dayOfWeekIndex = 0;
        for (String dayOfWeek in daysOfWeekFromPage) {
          final lessons = dayOfWeek.split('SIZE=1><P ALIGN="CENTER">').skip(1);

          int lessonIndex = 0;
          for (String lessonSection in lessons) {
            if (!lessonSection.contains('а.')) {
              lessonIndex++;
              continue;
            }

            final fullLesson = lessonSection
                .substring(0, lessonSection.indexOf('</FONT>'))
                .trim();
            final lessonChecker =
                fullLesson.replaceAll(RegExp(r'[^0-9а-яА-Я]'), '');

            if (lessonChecker.isEmpty) {
              lessonIndex++;
              continue;
            }

            final lesson = fullLesson
                .substring(fullLesson.indexOf('а.') + 2)
                .trim()
                .replaceAll('и/д', '')
                .replaceAll('пр.', '')
                .replaceAll('пр', '')
                .replaceAll('д/кл', '')
                .replaceAll('д/к', '')
                .replaceAll(RegExp(r'си\W+|си$|св\W+|св$|мф\W+|мф$'), ' ');

            final classroom = lesson.contains(' ')
                ? lesson.substring(0, lesson.indexOf(' '))
                : lesson;

            if (!classroom.contains(RegExp(r"[0-9]"))) {
              if (++lessonIndex > 5) break;
              continue;
            }

            final building = '${getBuildingByClassroom(classroom)} корпус';

            bool isScheduleExist = true;
            var currentScheduleModel = map[building]
                ?.firstWhereOrNull((element) => element.name == classroom);

            if (currentScheduleModel == null) {
              currentScheduleModel = ScheduleModel(
                name: classroom,
                type: ScheduleType.classroom,
                weeks: [],
              );
              isScheduleExist = false;
            }

            currentScheduleModel.updateWeek(
              dayOfWeekIndex ~/ 6,
              dayOfWeekIndex % 6,
              lessonIndex,
              LessonBuilder.createClassroomLesson(
                  lessonNumber: lessonIndex + 1,
                  lesson: '$teacherName $fullLesson'),
            );

            if (!isScheduleExist && currentScheduleModel.isNotEmpty) {
              map[building]?.add(currentScheduleModel);
            }

            if (++lessonIndex > 5) break;
          }

          if (++dayOfWeekIndex > 11) break;
        }
      }
    }

    try {
      await _parseDepartments(
        buildingsScheduleMap,
        streamController,
        mapCreating,
      );
    } on CustomException {
      rethrow;
    } catch (e, stack) {
      Logger.error(
        title: Errors.schedule,
        exception: e,
        stack: stack,
      );
      throw CustomException(message: Errors.schedule);
    }

    buildingsScheduleMap.removeWhere((key, value) => value.isEmpty);
    for (var building in buildingsScheduleMap.keys) {
      buildingsScheduleMap[building]!.sort((a, b) => a.name.compareTo(b.name));
    }

    if (buildingsScheduleMap.isEmpty) {
      Logger.error(
        title: Errors.schedule,
        exception:
            'Не найдено ни одного расписания кафедры. buildingsScheduleMap.isEmpty',
      );
      throw CustomException(message: Errors.schedule);
    }

    return buildingsScheduleMap;
  }

  /// Получения мэпа препод - список ссылок для поиска
  Future<Map<String, List<String>>> teachersLinksMap(
      StreamController<Map<String, String>> streamController) async {
    final Map<String, List<String>> scheduleLinksMap = {};

    /// Функция заплнения scheduleLinksMap
    void mapCreating(
      Map<String, List<String>> map,
      Iterable<String> splittedPage, {
      String? link,
    }) {
      for (String teacherSection in splittedPage) {
        final teacherName =
            teacherSection.substring(0, teacherSection.indexOf('</P>')).trim();

        map[teacherName] ??= [];
        map[teacherName]!.add(link!);
      }
    }

    try {
      await _parseDepartments(
        scheduleLinksMap,
        streamController,
        mapCreating,
      );
    } on CustomException {
      rethrow;
    } catch (e, stack) {
      Logger.error(
        title: Errors.schedule,
        exception: e,
        stack: stack,
      );
      throw CustomException(message: Errors.schedule);
    }

    if (scheduleLinksMap.isEmpty) {
      Logger.error(
        title: Errors.schedule,
        exception:
            'Не найдено ни одной ссылки на кафедру. scheduleLinksMap.isEmpty',
      );
      throw CustomException(message: Errors.schedule);
    }
    return scheduleLinksMap;
  }

  /// Парсинг всех страниц кафедр.
  /// [map] - мэп, в который будут записаны данные.
  /// [streamController] - для отслеживания процентов в блоке.
  /// [mapCreating] - функция заполнения мэпа данными.
  /// Возвращает true, если все прошло успешно, иначе - false
  Future<void> _parseDepartments<T extends Map>(
    T map,
    StreamController streamController,
    void Function(T map, Iterable<String> splittedPage, {String? link})
        mapCreating,
  ) async {
    final List<String> teachersLinks = [
      ScheduleLinks.allMagFaculties,
      ScheduleLinks.allBakFaculties,
    ];

    final List<String> teachersScheduleLinks = [
      ScheduleLinks.magPrefix,
      ScheduleLinks.bakPrefix,
    ];

    final facultiesPages = [];
    const int threadCount = 6;

    try {
      for (String link in teachersLinks) {
        facultiesPages.add(await repository.loadPage(link));
      }
    } catch (e, stack) {
      Logger.error(title: Errors.pageLoading, exception: e, stack: stack);

      throw CustomException(message: Errors.pageLoading);
    }

    int progress = 0;
    int errorCount = 0;
    int completedThreads = 0;
    int linksCount = 0;

    Future<void> loadDepartmentPages(List<String> links) async {
      int localErrorCount = 0;

      ///Загрузка и обработка всех страниц с кафедрами
      for (String link in links) {
        try {
          final splittedPage = (await repository.loadPage(link))
              .replaceAll(' COLOR="#0000ff"', '')
              .split('ff00ff">')
              .skip(1);

          mapCreating(map, splittedPage, link: link);

          progress++;
        } catch (e, stack) {
          Logger.warning(
              title: Errors.pageLoading, exception: e, stack: stack);

          localErrorCount++;
        }

        if (localErrorCount > 4) {
          completedThreads++;
          errorCount += localErrorCount;
          return;
        }
      }

      completedThreads++;
    }

    ///Создания списка ссылок на кафедры
    ///
    /// Список содержит [threadCount] списков ссылок, которые потом асинхронно
    /// загружаются и формируют мэп по корпусам
    final List<List<String>> departmentLinks =
        List.generate(threadCount, (index) => []);

    try {
      int i = 0;
      for (String facultyPage in facultiesPages) {
        Iterable<String> splittedPage = [];
        if (facultyPage.contains('faculty')) {
          splittedPage = facultyPage
              .replaceAll(RegExp(r"<!--.*-->"), '')
              .split('href="')
              .skip(1);
        }

        int j = 0;
        for (String departmentSection in splittedPage) {
          departmentLinks[j % threadCount].add(
            '${teachersScheduleLinks[i]}'
            '${departmentSection.substring(0, departmentSection.indexOf('">'))}',
          );
          j++;
        }
        linksCount += j;
        i++;
      }

      if (linksCount == 0) {
        Logger.error(
          title: Errors.pageParsing,
          exception: 'Не получено ни одной ссылки на кафедры. linksCount == 0',
        );
        throw CustomException(message: Errors.pageParsing);
      }

      /// Собственно [threadCount] асинхронных потоков по загрузке страниц. Далее
      /// ождиание окончания их работы с отображением прогресса.
      ///
      /// Если прогресс слишком долго не идет (капитализм как-никак), то выводится
      /// сообщение об этом. Проверяется зависание счетчиком сравнения предыдущего
      /// прогресса с нынешним
      int freezeCount = 0;
      int oldProgress = progress;
      for (int i = 0; i < threadCount; i++) {
        loadDepartmentPages(departmentLinks[i]);
      }
      do {
        await Future.delayed(const Duration(milliseconds: 500));

        if (oldProgress == progress) {
          freezeCount++;
          if (freezeCount > 20) {
            streamController.add({
              'percents': (progress / linksCount * 100).toInt().toString(),
              'message':
                  'Загрузка длится слишком долго. Возможно, что-то пошло не так...',
            });
          }
          continue;
        } else {
          oldProgress = progress;
          freezeCount = 0;
        }
        streamController.add({
          'percents': (progress / linksCount * 100).toInt().toString(),
        });
      } while (completedThreads < threadCount);

      if (errorCount > 8) {
        Logger.error(
          title: Errors.schedule,
          exception: 'Большое количество ошибок при загрузке. errorsCount > 8',
        );
        throw CustomException(message: Errors.schedule);
      }
    } catch (e, stack) {
      Logger.error(
        title: Errors.schedule,
        exception: e,
        stack: stack,
      );
      throw CustomException(message: Errors.schedule);
    }
  }
}
