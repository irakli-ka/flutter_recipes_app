import 'recipe.dart';

class RecipeResponse {
  final List<Recipe> recipes;
  final int total;
  final int skip;
  final int limit;

  RecipeResponse({
    required this.recipes,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory RecipeResponse.fromJson(Map<String, dynamic> json) {
    return RecipeResponse(
      recipes: (json['recipes'] as List)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      skip: json['skip'] as int,
      limit: json['limit'] as int,
    );
  }
}