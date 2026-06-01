import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/loading_animation.dart';
import 'recipe_detail.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late ApiService _apiService;
  late ScrollController _scrollController;
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  String? _error;

  final Set<String> _selectedMealTypes = {};
  final Set<String> _availableMealTypes = {};

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadRecipes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMoreRecipes();
      }
    }
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.getRecipes(skip: 0, limit: 10);
      setState(() {
        _allRecipes = response.recipes;
        _skip = 10;
        _hasMore = _allRecipes.length < response.total;
        _isLoading = false;
        _extractFilterOptions();
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreRecipes() async {
    setState(() => _isLoading = true);
    try {
      final response =
      await _apiService.getRecipes(skip: _skip, limit: 10);
      setState(() {
        _allRecipes.addAll(response.recipes);
        _skip += 10;
        _hasMore = _allRecipes.length < response.total;
        _isLoading = false;
        _extractFilterOptions();
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _extractFilterOptions() {
    for (var recipe in _allRecipes) {
      _availableMealTypes.addAll(recipe.mealType);
    }
  }

  void _applyFilters() {
    setState(() {
      if (_selectedMealTypes.isEmpty) {
        _filteredRecipes = _allRecipes;
      } else {
        _filteredRecipes = _allRecipes.where((recipe) {
          return recipe.mealType
              .any((mealType) => _selectedMealTypes.contains(mealType));
        }).toList();
      }
    });
  }

  void _toggleMealType(String mealType) {
    setState(() {
      if (_selectedMealTypes.contains(mealType)) {
        _selectedMealTypes.remove(mealType);
      } else {
        _selectedMealTypes.add(mealType);
      }
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedMealTypes.clear();
      _applyFilters();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,
        elevation: 3,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _allRecipes.isEmpty) {
      return const LoadingAnimation(message: 'Loading Recipes...');
    }

    if (_error != null && _allRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecipes,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildMealTypeFilter(),
        Expanded(
          child: _filteredRecipes.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No recipes found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          )
              : ListView.builder(
            controller: _scrollController,
            itemCount: _filteredRecipes.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _filteredRecipes.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }
              return RecipeCard(
                recipe: _filteredRecipes[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecipeDetailScreen(recipeId: _filteredRecipes[index].id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMealTypeFilter() {
    if (_availableMealTypes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ..._availableMealTypes.map((mealType) {
                final isSelected = _selectedMealTypes.contains(mealType);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(mealType),
                    selected: isSelected,
                    onSelected: (_) => _toggleMealType(mealType),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Colors.amber : Colors.grey[300]!,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.amber[800] : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
              if (_selectedMealTypes.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      '✕ Clear',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}