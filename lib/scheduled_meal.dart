import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class ScheduledMealPage extends StatefulWidget {
  final String username;

  ScheduledMealPage({Key? key, required this.username}) : super(key: key);

  @override
  State<ScheduledMealPage> createState() => _ScheduledMealPageState();
}

class _ScheduledMealPageState extends State<ScheduledMealPage> {
  late Future<List<dynamic>> _plannedMealsFuture;

  @override
  void initState() {
    super.initState();
    _plannedMealsFuture = getPlannedMeals();
  }

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
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange[100],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _plannedMealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              List<dynamic> plannedMeals = snapshot.data!;
              return ListView.builder(
                itemCount: plannedMeals.length,
                itemBuilder: (context, index) {
                  return _buildMealBox(plannedMeals[index]);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMealBox(dynamic meal) {
    return GestureDetector(
      onTap: () {
        // Handle meal selection
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        padding: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal['title'],
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'Start Date: ${meal['start_date']}',
              style: TextStyle(fontSize: 16.0),
            ),
            Text(
              'End Date: ${meal['end_date']}',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> getPlannedMeals() async {
    final box = await Hive.openBox("myBox");
    var link = "http://192.168.1.11/mealplanner/api.php/";

    final Map<String, dynamic> json = {"user_id": box.get("user_id")};

    final Map<String, dynamic> queryParams = {
      "operation": "getmealplan",
      "json": jsonEncode(json)
    };

    http.Response response =
        await http.get(Uri.parse(link).replace(queryParameters: queryParams));

    try {
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res is List<dynamic>) {
          return List<dynamic>.from(res);
        } else if (res is Map<String, dynamic>) {
          return [res];
        } else {
          print("Invalid response format: $res");
          return [];
        }
      } else {
        print(response.statusCode);
        return [];
      }
    } catch (error) {
      print(error);
      return [];
    }
  }
}
