import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipePage extends StatefulWidget {
  final int recipeId;
  final String title;
  final String imageLink;
  final String desc;
  final String instructions;
  RecipePage(
      {Key? key,
      required this.recipeId,
      required this.title,
      required this.imageLink,
      required this.desc,
      required this.instructions})
      : super(key: key);

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  late Future<List> _futureIngredients;

  @override
  void initState() {
    super.initState();
    _futureIngredients = getIngredients(widget.recipeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.orange[100],
      ),
      body: FutureBuilder<List>(
        future: _futureIngredients,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Extract the list of ingredients from the snapshot data
            List ingredients = snapshot.data!;
            return ListView(
              children: [
                // Product image
                Image.network(
                  widget.imageLink,
                  height: MediaQuery.of(context).size.height / 2.5,
                  fit: BoxFit.fill,
                ),
                // Product title
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 10.0),
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24.0),
                    ),
                  ),
                ),
                // Product description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        "Description: ",
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.desc,
                        style: TextStyle(fontSize: 20.0),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Ingredients
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        "Ingredients: ",
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${ingredients.map((ingredient) => '${ingredient['ingredient_name']} (${ingredient['amount']})').join(', ')}",
                        style: TextStyle(fontSize: 20.0),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Instruction: ",
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            widget.instructions,
                            style: TextStyle(fontSize: 20.0),
                            softWrap: true,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getIngredients(int recipe_id) async {
    try {
      String link = "http://192.168.1.11/mealplanner/api.php/";

      final Map<String, dynamic> json = {"recipe_id": recipe_id};
      final Map<String, dynamic> queryParams = {
        "operation": "getingredients",
        "json": jsonEncode(json)
      };

      http.Response response =
          await http.get(Uri.parse(link).replace(queryParameters: queryParams));

      if (response.statusCode == 200) {
        List<dynamic> items = jsonDecode(response.body);
        List<Map<String, dynamic>> ingredients = [];
        for (var item in items) {
          if (item['error'] != null) {
            print("Something went wrong: ${item['error']}");
            return [];
          } else {
            print(items);
            ingredients.add(item);
          }
        }
        return ingredients;
      } else {
        return [];
      }
    } catch (error) {
      print(error);
      return [];
    }
  }
}
