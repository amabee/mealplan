// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mealplan/schedulepage.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:file_picker/file_picker.dart';

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
            // print("Index: $index");
            if (_mealList.isNotEmpty &&
                index >= 0 &&
                index < _mealList.length) {
              var recipe_id = _mealList[index]['recipe_id'] ?? 0;
              var mealId = _mealList[index]['recipe_id'] ?? 'Unknown Recipe ID';
              var mealName = _mealList[index]['title'] ?? 'Unknown Product';
              var mealDesc =
                  _mealList[index]['description'] ?? 'Unknown Product';
              var mealImage = _mealList[index]["image"] ?? "No image";
              var instructions = _mealList[index]["instructions"] ?? "No Instructions available";
              return GestureDetector(
                onLongPress: () {
                  print("long pressed");
                },
                child: Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RecipePage(
                                    recipeId: recipe_id,
                                    title: mealName,
                                    imageLink: "http://192.168.1.11/mealplanner/$mealImage",
                                    desc: mealDesc,
                                    instructions: instructions,
                                  )));
                    },
                    trailing: Wrap(
                      spacing: 12,
                      children: <Widget>[
                        GestureDetector(
                            onTap: () {
                              showAddIngredientsDialog(
                                  context, recipe_id, mealName);
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
                          softWrap: true,
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
    File? imageFile;

    Future<void> pickImage() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowCompression: true,
      );

      if (result != null) {
        imageFile = File(result.files.single.path!);
      }
    }

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
                ElevatedButton(
                  onPressed: () async {
                    await pickImage();
                  },
                  child: Text('Pick Image'),
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
                if (imageFile != null) {
                  String imageName = imageFile!.path.split('/').last;
                  addRecipe(
                    title.text,
                    desc.text,
                    instructions.text,
                    prep_time.text,
                    cook_time.text,
                    servings.text,
                    imageName,
                    imageFile,
                  );
                  Navigator.of(context).pop();
                } else {
                  // Handle the case where no image is picked
                  _onBasicAlertPressed(
                      context, "Error", "Please pick an image.");
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void addRecipe(
    String title,
    String desc,
    String ins,
    String prep_time,
    String cook_time,
    String servings,
    String imageName,
    File? imageFile,
  ) async {
    final box = await Hive.openBox("myBox");

    final Map<String, String> json = {
      "title": title,
      "desc": desc,
      "ins": ins,
      "prep_time": prep_time,
      "cook_time": cook_time,
      "serving": servings,
      "author_id": box.get("user_id").toString(),
      "image_name": imageName,
    };

    final Map<String, String> queryParams = {
      "operation": "addrecipe",
      "json": jsonEncode(json),
    };

    var link = "http://192.168.1.11/mealplanner/api.php/";

    var request = http.MultipartRequest('POST', Uri.parse(link));

    if (imageFile != null) {
      request.files.add(
        http.MultipartFile(
          'image',
          imageFile.readAsBytes().asStream(),
          imageFile.lengthSync(),
          filename: imageName,
        ),
      );
    }

    request.fields.addAll(queryParams);

    var response = await request.send();

    try {
      if (response.statusCode == 200) {
        var res = await response.stream.bytesToString();

        var decodedResponse = jsonDecode(res);

        if (decodedResponse["error"] != null) {
          _onBasicAlertPressed(
              context, "Fetch Error", decodedResponse["error"]);
        } else {
          _onBasicAlertPressed(context, "Success", res);
        }
      }
    } catch (error) {
      print(error);
      _onBasicAlertPressed(context, "Success", "Successfully added recipe");
    }
  }

  showAddIngredientsDialog(
      BuildContext context, int recipeId, String mealName) {
    List<TextEditingController> ingredientControllers = [];
    List<TextEditingController> descControllers = [];
    int passRecipeId = recipeId;
    void addIngredientField() {
      ingredientControllers.add(TextEditingController());
      descControllers.add(TextEditingController());
    }

    void removeIngredientField(int index) {
      ingredientControllers.removeAt(index);
      descControllers.removeAt(index);
    }

    void saveIngredients() {
      for (int i = 0; i < ingredientControllers.length; i++) {
        String ingredientName = ingredientControllers[i].text;
        String amount = descControllers[i].text;
        saveIngredient(passRecipeId, ingredientName, amount);
      }
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Center(
                child: Text(
                  'Add Ingredient to $mealName',
                  style: const TextStyle(fontSize: 17.0),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text(
                      'Recipe: $mealName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: ingredientControllers.length,
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ingredientControllers[index],
                                decoration:
                                    InputDecoration(labelText: 'Ingredient'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: descControllers[index],
                                decoration:
                                    InputDecoration(labelText: 'Amount'),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  removeIngredientField(index);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          addIngredientField();
                        });
                      },
                      child: Text('Add Ingredient'),
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
                    saveIngredients();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void saveIngredient(
      int recipeId, String ingredientName, String amount) async {
    final Map<String, dynamic> json = {
      "rid": recipeId,
      "ing_name": ingredientName,
      "amount": amount
    };
    final Map<String, dynamic> queryParams = {
      "operation": "addingredients",
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
          print("Error: $res");
        } else {
          _onBasicAlertPressed(context, "Success", "Success");
        }
      }
    } catch (error) {
      print(error);
    }
  }
}
