import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_ui/modules/settings/views/debug_page.dart';
import 'package:flutter_ui/modules/settings/views/settings_page.dart';

import '../../core/static/app_routes.dart';
import '../home/home_module.dart';

class SettingsModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const SettingsPage());
    r.child(AppRoutes.debugRoute, child: (context) => const DebugPage());
  }

  @override
  List<Module> get imports => [HomeModule()];
}
