// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

late String username = "";

class _HomePageState extends State<HomePage> {
  late List<dynamic> _mealList = [];

  @override
  void initState() {
    super.initState();
    getName();
    getAllMeal().then((myRecipes) {
      setState(() {
        _mealList = myRecipes ?? [];
      });
    }).catchError((error) {
      print("Error in getting meal: $error");
    });
  }

  _onBasicAlertPressed(context, String desc, String title) {
    Alert(
      context: context,
      title: title,
      desc: desc,
    ).show();
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    List<dynamic>? myRecipeList = await getAllMeal();

    setState(() {
      _mealList = myRecipeList!;
    });
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
          title: Text("$username's Dashboard"),
          centerTitle: true,
          backgroundColor: Colors.orange[100],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: FutureBuilder(
              future: getAllMeal(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Center(child: CircularProgressIndicator());
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    return itemListView();

                  default:
                    return Text("Error: ${snapshot.error}");
                }
              },
            ),
          ),
        ),
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom: 15,
              right: 15,
              child: Container(
                width: 125,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange[200],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    showAddRecipeDialog(context);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.add),
                      Text(
                        "Add Food",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      List<dynamic>? updatedMealList = await getAllMeal();
      setState(() {
        _mealList = updatedMealList ?? [];
      });
    } catch (error) {
      print("Error refreshing data: $error");
      throw Exception("Failed to refresh data");
    }
  }

  Widget itemListView() {
    return Container(
      child: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
        },
        child: ListView.builder(
          itemCount: _mealList.length,
          itemBuilder: (context, index) {
            print("Index: $index");
            if (_mealList.isNotEmpty &&
                index >= 0 &&
                index < _mealList.length) {
              var mealId = _mealList[index]['recipe_id'] ?? 'Unknown Recipe ID';
              var mealName = _mealList[index]['title'] ?? 'Unknown Product';
              var mealDesc =
                  _mealList[index]['description'] ?? 'Unknown Product';
              return GestureDetector(
                onLongPress: () {
                  print("DELETED");
                },
                child: Card(
                  child: ListTile(
                    onTap: (){
                      print("hello");
                    },
                    trailing: Wrap(
                      spacing: 12,
                      children: <Widget>[
                        GestureDetector(
                            onTap: () {
                              showAddIngredientsDialog(context);
                            },
                            child: Icon(Icons.edit)),
                        const SizedBox(
                          width: 3,
                        ),
                        Icon(Icons.add),
                      ],
                    ),
                    title: Text(
                      mealName.toString(),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description: ${mealDesc.toString()}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }

  Future<List<dynamic>?> getAllMeal() async {
    var link = "http://192.168.1.11/mealplanner/api.php/";
    final box = await Hive.openBox('myBox');

    final Map<String, dynamic> jsonData = {
      "author_id": box.get("user_id"),
    };
    final Map<String, dynamic> query = {
      "operation": "myrecipes",
      "json": jsonEncode(jsonData),
    };

    http.Response response =
        await http.get(Uri.parse(link).replace(queryParameters: query));
    try {
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res is List && res.isNotEmpty && res[0] is Map<String, dynamic>) {
          var data = List<dynamic>.from(res);
          return data;
        } else {
          print("Invalid data format received from API");
          return null;
        }
      }
    } catch (error) {
      print("Runtime Error: $error");
    }
    return null;
  }

  Future<String> getName() async {
    var box = await Hive.openBox("myBox");
    setState(() {
      username = box.get("username");
    });
    return username;
  }

  showAddRecipeDialog(BuildContext context) {
    TextEditingController title = TextEditingController();
    TextEditingController desc = TextEditingController();
    TextEditingController instructions = TextEditingController();
    TextEditingController prep_time = TextEditingController();
    TextEditingController cook_time = TextEditingController();
    TextEditingController servings = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Recipe'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: title,
                  decoration: InputDecoration(labelText: 'Recipe Name'),
                ),
                TextFormField(
                  controller: desc,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: instructions,
                  decoration: InputDecoration(labelText: 'Instructions'),
                ),
                TextFormField(
                  controller: prep_time,
                  decoration: InputDecoration(labelText: 'Preparation Time'),
                ),
                TextFormField(
                  controller: cook_time,
                  decoration: InputDecoration(labelText: 'Cooking Time'),
                ),
                TextFormField(
                  controller: servings,
                  decoration: InputDecoration(labelText: 'Servings'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                addRecipe(title.text, desc.text, instructions.text,
                    prep_time.text, cook_time.text, servings.text);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void addRecipe(String title, String desc, String ins, String prep_time,
      String cook_time, String servings) async {
    final box = await Hive.openBox("myBox");

    final Map<String, dynamic> json = {
      "title": title,
      "desc": desc,
      "ins": ins,
      "prep_time": prep_time,
      "cook_time": cook_time,
      "serving": servings,
      "author_id": box.get("user_id")
    };

    final Map<String, dynamic> queryParams = {
      "operation": "addrecipe",
      "json": jsonEncode(json)
    };

    var link = "http://192.168.1.11/mealplanner/api.php/";

    http.Response response = await http.post(
      Uri.parse(link),
      body: queryParams,
    );

    try {
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);

        if (res["error"] != null) {
          _onBasicAlertPressed(context, "Fetch Error", res["error"]);
        } else {
          _onBasicAlertPressed(context, "Success", response.body);
        }
      }
    } catch (error) {
      print(error);
      _onBasicAlertPressed(context, "Success", "Added Recipe");
    }
  }

  showAddIngredientsDialog(BuildContext context) {
    TextEditingController title = TextEditingController();
    TextEditingController desc = TextEditingController();
    TextEditingController instructions = TextEditingController();
    TextEditingController prep_time = TextEditingController();
    TextEditingController cook_time = TextEditingController();
    TextEditingController servings = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Recipe'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: title,
                  decoration: InputDecoration(labelText: 'Recipe Name'),
                ),
                TextFormField(
                  controller: desc,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: instructions,
                  decoration: InputDecoration(labelText: 'Instructions'),
                ),
                TextFormField(
                  controller: prep_time,
                  decoration: InputDecoration(labelText: 'Preparation Time'),
                ),
                TextFormField(
                  controller: cook_time,
                  decoration: InputDecoration(labelText: 'Cooking Time'),
                ),
                TextFormField(
                  controller: servings,
                  decoration: InputDecoration(labelText: 'Servings'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                addRecipe(
                    title.text,
                    desc.text,
                    instructions.text,
                    prep_time.text,
                    cook_time.text,
                    "s"
                    );
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
