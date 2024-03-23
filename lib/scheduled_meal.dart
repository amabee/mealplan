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
            print(snapshot);
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              if (snapshot.data == null || snapshot.data!.isEmpty) {
                return Center(child: Text('Nothing to show here'));
              }
              List<dynamic> plannedMeals = snapshot.data!;
              Map<String, List<dynamic>> groupedMeals =
                  groupMealsByDate(plannedMeals);
              return ListView(
                children: groupedMeals.entries.map((entry) {
                  return _buildDateCard(entry.key, entry.value);
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }

  Map<String, List<dynamic>> groupMealsByDate(List<dynamic> meals) {
  Map<String, List<dynamic>> groupedMeals = {};
  for (var meal in meals) {
    String? startDate = meal['start_date'];
    if (startDate != null) {
      String endDate = meal['end_date'];
      String formattedStartDate = _formatDate(startDate);
      if (!groupedMeals.containsKey(formattedStartDate)) {
        groupedMeals[formattedStartDate] = [];
      }
      groupedMeals[formattedStartDate]!.add(meal);
    }
  }
  return groupedMeals;
}


  String _formatDate(String? date) {
    if (date != null) {
      DateTime dateTime = DateTime.parse(date);
      return '${_getMonthName(dateTime.month)} ${dateTime.day}';
    } else {
      return 'Unknown';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  Widget _buildDateCard(String? date, List<dynamic> meals) {
    return Card(
      margin: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$date',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            children: meals.map((meal) {
              return _buildMealBox(meal);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealBox(dynamic meal) {
    return GestureDetector(
      onTap: () {
        // Handle meal selection
      },
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          padding: EdgeInsets.all(15.0),
          width: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '${meal['title']}',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
        return [""];
      }
    } catch (error) {
      print(error);
      return [""];
    }
  }
}
