import 'package:flutter/material.dart';

class SchedulePage extends StatefulWidget {
  int recipeId;
  String title;
  SchedulePage({super.key, required this.recipeId, required this.title});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.orange[100],
      ),
      body: Center(
        child: Text("${widget.recipeId}"),
      ),
    );
  }
}
