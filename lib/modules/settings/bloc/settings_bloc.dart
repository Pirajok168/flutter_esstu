import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';


import '../../../core/logger/errors.dart';
import '../../../core/static/settings_types.dart';
import '../../../core/time/current_time.dart';
import '../settings_repository.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc(SettingsRepository repository)
      : _settingsRepository = repository,
        super(SettingsState()) {
    on<LoadSettings>(_loadSettings);
    on<ChangeSetting>(_changeSetting);
    on<ClearAll>(_clearAll);
  }

  Future<void> _loadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final stringSettingsValues = await _settingsRepository.loadSettings();

      ///
      /// загрузка сдвига номера недели
      ///
      if (stringSettingsValues[SettingsTypes.weekIndexShifting] == 'true') {
        CurrentTime.weekShifting = 1;
      }

      emit(SettingsLoaded.fromMap(stringSettingsValues));
    } catch (e, stack) {
      emit(SettingsError('${Errors.settings}: ${e.runtimeType}\n$stack'));
    }
  }

  Future<void> _changeSetting(
      ChangeSetting event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoaded.fromMap(
        await _settingsRepository.saveSettings(event.settingType, event.value),
      ));
    } catch (e, stack) {
      emit(SettingsError('${Errors.settings}: ${e.runtimeType}\n$stack'));
    }
  }

  Future<void> _clearAll(ClearAll event, Emitter<SettingsState> emit) async {
    try {
      await _settingsRepository.clearAll();
    } catch (e, stack) {
      emit(SettingsError('${Errors.settings}: ${e.runtimeType}\n$stack'));
      return;
    }

    try {
      emit(SettingsLoaded.fromMap(await _settingsRepository.loadSettings()));
    } catch (e, stack) {
      emit(SettingsError('${Errors.settings}: ${e.runtimeType}\n$stack'));
    }
  }
}
