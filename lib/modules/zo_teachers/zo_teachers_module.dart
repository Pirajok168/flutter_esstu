import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_ui/modules/zo_teachers/view/zo_teachers_page.dart';

import '../home/home_module.dart';
import 'bloc/zo_teachers_bloc.dart';

class ZoTeachersModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(ZoTeachersBloc.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const ZoTeachersPage());
  }

  @override
  List<Module> get imports => [HomeModule()];
}
