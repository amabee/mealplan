import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mealplan/login.dart';
import 'package:mealplan/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  bool hasSession = await _checkSession();

  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  final bool hasSession;

  const MyApp({Key? key, required this.hasSession}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meal Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: hasSession ? HomePage() : LoginPage(),
    );
  }
}

Future<bool> _checkSession() async {
  await Future.delayed(const Duration(seconds: 5));
  final box = await Hive.openBox('myBox');
  return box.get("hasSession", defaultValue: false);
}
