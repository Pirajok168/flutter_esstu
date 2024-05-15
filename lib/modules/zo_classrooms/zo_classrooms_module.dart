import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_ui/modules/zo_classrooms/view/zo_classrooms_page.dart';

import '../home/home_module.dart';
import 'bloc/zo_classroom_bloc.dart';

class ZoClassroomsModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(ZoClassroomsBloc.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const ZoClassroomsPage());
  }

  @override
  List<Module> get imports => [HomeModule()];
}
