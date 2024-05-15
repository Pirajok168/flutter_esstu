import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_ui/modules/favorite/view/favorite_list_page.dart';
import 'package:flutter_ui/modules/favorite/view/favorite_schedule_page.dart';

import '../../core/static/app_routes.dart';
import '../home/home_module.dart';
import 'favorite_list_bloc/favorite_list_bloc.dart';
import 'favorite_update_bloc/favorite_update_bloc.dart';


class FavoriteModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(FavoriteListBloc.new);
    i.addSingleton(FavoriteUpdateBloc.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const FavoriteListPage());
    r.child(AppRoutes.favoriteScheduleRoute,
        child: (context) => FavoriteSchedulePage(
              scheduleName: r.args.data[0],
              scheduleType: r.args.data[1],
              isAutoUpdateEnabled: r.args.data[2],
            ));
  }

  @override
  List<Module> get imports => [HomeModule()];
}
