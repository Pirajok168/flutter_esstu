import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../core/logger/logger.dart';
import '../../core/main_repository.dart';
import '../../core/parser/parser.dart';
import '../../core/parser/students_parser.dart';
import '../../core/parser/teachers_parser.dart';
import '../../core/static/app_routes.dart';
import '../../core/time/bloc/week_number_bloc.dart';
import '../../core/time/week_number_repository.dart';
import '../classrooms/classrooms_module.dart';
import '../favorite/favorite_button_bloc/favorite_button_bloc.dart';
import '../favorite/favorite_module.dart';
import '../favorite/favorite_schedule_bloc/favorite_schedule_bloc.dart';
import '../favorite/repository/favorite_repository.dart';
import '../search/search_module.dart';
import '../settings/settings_module.dart';
import '../students/students_module.dart';
import '../teachers/teachers_module.dart';
import '../zo_classrooms/zo_classrooms_module.dart';
import '../zo_teachers/zo_teachers_module.dart';
import 'home_page.dart';


class HomeModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(WeekNumberRepository.new);
    i.addSingleton(WeekNumberBloc.new);
    i.addSingleton(FavoriteButtonBloc.new);
    i.addSingleton(FavoriteScheduleBloc.new);
    i.addSingleton(FavoriteRepository.new);
    i.addSingleton(MainRepository.new);
    i.addSingleton(TeachersParser.new);
    i.addSingleton(StudentsParser.new);
    i.addSingleton(Parser.new);
  }

  @override
  void exportedBinds(i) {
    //i.addSingleton(MainRepository.new);
    //i.addSingleton(FavoriteRepository.new);
  }

  BindConfig<T> blocConfig<T extends Bloc>() {
    return BindConfig(
      notifier: (bloc) => bloc.stream,
      onDispose: (bloc) => bloc.close(),
    );
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const HomePage());

    r.module(AppRoutes.studentsRoute, module: StudentsModule());
    r.module(AppRoutes.settingsRoute, module: SettingsModule());
    r.module(AppRoutes.teachersRoute, module: TeachersModule());
    r.module(AppRoutes.classesRoute, module: ClassroomsModule());
    r.module(AppRoutes.favoriteListRoute, module: FavoriteModule());
    r.module(AppRoutes.searchRoute, module: SearchModule());
    r.module(AppRoutes.zoClassesRoute, module: ZoClassroomsModule());
    r.module(AppRoutes.zoTeachersRoute, module: ZoTeachersModule());
  }
}
