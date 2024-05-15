import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_ui/modules/teachers/view/departments_page.dart';
import 'package:flutter_ui/modules/teachers/view/faculties_page.dart';

import '../../core/static/app_routes.dart';
import '../home/home_module.dart';
import 'departments_bloc/department_bloc.dart';
import 'faculties_bloc/faculty_bloc.dart';

class TeachersModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(FacultyBloc.new);
    i.addSingleton(DepartmentBloc.new);
  }

  @override
  void routes(RouteManager r) {
    //final args = r.args;
    r.child('/', child: (context) => const FacultiesPage());
    r.child(AppRoutes.departmentsRoute,
        child: (context) => DepartmentsPage(facultyState: r.args.data));
  }

  @override
  List<Module> get imports => [HomeModule()];
}
