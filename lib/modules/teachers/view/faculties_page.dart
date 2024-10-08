import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/static/app_routes.dart';
import '../../../core/static/settings_types.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../faculties_bloc/faculty_bloc.dart';

class FacultiesPage extends StatelessWidget {
  const FacultiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Факультет')),
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(
              value: Modular.get<FacultyBloc>()..add(LoadFaculties())),
        ],
        child: BlocListener<FacultyBloc, FacultyState>(
          listener: (context, state) {
            if (state is CurrentFacultyLoaded) {
              Modular.to.pushNamed(
                  AppRoutes.teachersRoute + AppRoutes.departmentsRoute,
                  arguments: state);
            }
          },
          child: Center(
            child: BlocBuilder<FacultyBloc, FacultyState>(
              builder: (context, state) {
                if (state is FacultiesLoading) {
                  return const CircularProgressIndicator();
                }

                if (state is FacultiesLoaded || state is CurrentFacultyLoaded) {
                  final map = state.facultyDepartmentLinkMap!;

                  return Center(
                    child: ListView(
                      children: List.generate(
                        map.keys.length,
                        (index) => _facultyButton(map.keys.elementAt(index),
                            map[map.keys.elementAt(index)]!, context),
                      ),
                    ),
                  );
                }

                if (state is FacultiesError) {
                  return Text(state.message, textAlign: TextAlign.center);
                }

                return const Center(child: Text('Неизвестная ошибка'));
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _facultyButton(String facultyName,
      Map<String, List<String>> departmentsMap, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: SizedBox(
        child: ElevatedButton(
          onPressed: () {
            Modular.get<FacultyBloc>().add(ChooseFaculty(
                facultyName: facultyName, departmentsMap: departmentsMap));
          },
          child: Container(
            height: 50.0,
            alignment: AlignmentDirectional.center,
            child: Text(
              facultyName,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
