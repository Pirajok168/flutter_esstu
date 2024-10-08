import 'dart:convert';


import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/schedule_model.dart';

///
/// Название ключа расписания для сохранения должно выглядеть:
///
/// "<тип расписания>|<название расписания>"
///
/// Название ключа для настроек должно содержать слово service
///
class FavoriteRepository {
  Future<List<String>> getFavoriteList() async {
    final storage = await SharedPreferences.getInstance();
    final list = storage.getKeys().toList();
    list.removeWhere((key) => key.contains('Service'));

    return list;
  }

  Future<ScheduleModel?> getScheduleModel(String key) async {
    final storage = await SharedPreferences.getInstance();
    final scheduleString = storage.getString(key);
    if (scheduleString == null) {
      return null;
    }

    return ScheduleModel.fromJson(jsonDecode(scheduleString));
  }

  Future<void> saveSchedule(String key, String schedule) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setString(key, schedule);
  }

  Future<void> deleteSchedule(String key) async {
    final storage = await SharedPreferences.getInstance();
    await _removeOldMainFav(key);
    await storage.remove(key);
  }

  Future<bool> checkSchedule(String key) async =>
      (await SharedPreferences.getInstance()).getKeys().contains(key);

  Future<void> clearAllSchedule() async {
    final storage = await SharedPreferences.getInstance();

    final list = storage.getKeys().toList();
    list.removeWhere(
        (key) => key.contains('Service') && !key.contains('MainFavService'));

    for (String key in list) {
      await storage.remove(key);
    }
  }

  Future<void> addToMainPage(String key) async {
    final storage = await SharedPreferences.getInstance();
    await _removeOldMainFav(key);
    await storage.setString('${key}MainFavService', '');
  }

  Future<void> _removeOldMainFav(String key) async {
    final storage = await SharedPreferences.getInstance();
    final storageList = storage.getKeys();
    storageList.removeWhere((key) => !key.contains('MainFav'));

    for (String oldMainFav in storageList) {
      await storage.remove(oldMainFav);
    }
  }

  Future<String?> getMainFavScheduleName() async {
    final storage = await SharedPreferences.getInstance();
    final storageList = storage.getKeys();
    storageList.removeWhere((key) => !key.contains('MainFav'));

    if (storageList.isEmpty) {
      return null;
    }

    return storageList.first.replaceAll('MainFavService', '');
  }
}
