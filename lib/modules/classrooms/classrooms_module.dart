import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_ui/modules/classrooms/view/classrooms_page.dart';

import '../home/home_module.dart';
import 'bloc/classrooms_bloc.dart';


class ClassroomsModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(ClassroomsBloc.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const ClassroomsPage());
  }

  @override
  List<Module> get imports => [HomeModule()];
}
