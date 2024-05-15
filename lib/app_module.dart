import 'package:flutter_modular/flutter_modular.dart';

import 'core/static/app_routes.dart';
import 'modules/home/home_module.dart';
import 'modules/students/students_module.dart';


class AppModule extends Module {
  @override
  void routes(RouteManager r) {
    r.module('/', module: HomeModule());
    r.module(AppRoutes.studentsRoute, module: StudentsModule());
  }
}
