import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:jiffy/jiffy.dart';

import 'app_module.dart';
import 'app_widget.dart';
import 'core/http_override.dart';


void main() async {
  await Jiffy.setLocale('ru');
  HttpOverrides.global = AppHttpOverrides();

  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
