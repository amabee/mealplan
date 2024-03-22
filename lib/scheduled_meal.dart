import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScheduledMealPage extends StatefulWidget {
  String username;
  ScheduledMealPage({super.key, required this.username});

  @override
  State<ScheduledMealPage> createState() => _ScheduledMealPageState();
}

class _ScheduledMealPageState extends State<ScheduledMealPage> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "${widget.username}'s Scheduled Meals",
              style:
                  const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange[100],
          ),
        ));
  }
}
