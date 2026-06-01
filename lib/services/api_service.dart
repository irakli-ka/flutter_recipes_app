import 'package:dio/dio.dart';
import '../models/recipe.dart';
import '../models/recipe_response.dart';

class ApiService {
  final Dio _dio = Dio();
  static const String baseUrl = 'https://dummyjson.com';

  ApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<RecipeResponse> getRecipes({int skip = 0, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/recipes',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return RecipeResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Could not load recipes: $e');
    }
  }

  Future<Recipe> getRecipeDetail(int id) async {
    try {
      final response = await _dio.get('$baseUrl/recipes/$id');
      return Recipe.fromJson(response.data);
    } catch (e) {
      throw Exception('Could not load details: $e');
    }
  }
}