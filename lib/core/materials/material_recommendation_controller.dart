import 'package:flutter/foundation.dart';
import 'models/material_category.dart';
import 'models/material_item.dart';
import 'services/firestore_materials_service.dart';

class MaterialRecommendationController extends ChangeNotifier {
  static const String filterAll = 'All';
  static const String filterFloor = 'Floor';
  static const String filterWall = 'Wall';

  MaterialRecommendationController({
    FirestoreMaterialsService? firestore,
    List<MaterialCategory>? initialCategories,
  }) : _firestore = firestore,
       _categories = initialCategories ?? const <MaterialCategory>[];

  final FirestoreMaterialsService? _firestore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MaterialCategory> _categories;
  List<MaterialCategory> get categories => _categories;

  String _selectedFilter = filterAll;
  String get selectedFilter => _selectedFilter;

  void setSelectedFilter(String filter) {
    final next = filter.trim();
    if (next.isEmpty) return;
    if (next == _selectedFilter) return;
    _selectedFilter = next;
    notifyListeners();
  }

  bool _itemHasType(MaterialItem item, String type) {
    final typeKey = type.trim().toLowerCase();
    if (typeKey.isEmpty) return false;

    final itemType = (item.type ?? '').trim().toLowerCase();
    if (itemType.isEmpty) return false;

    // Support Firestore `placement` semantics: "both" matches floor + wall.
    if (itemType == 'both') {
      return typeKey == 'floor' || typeKey == 'wall';
    }

    return itemType == typeKey;
  }

  bool _itemMatchesSelectedFilter(MaterialItem item) {
    switch (_selectedFilter) {
      case filterFloor:
        return _itemHasType(item, 'floor');
      case filterWall:
        return _itemHasType(item, 'wall');
      case filterAll:
      default:
        return true;
    }
  }

  bool shouldShowCategory(MaterialCategory category) {
    switch (_selectedFilter) {
      case filterFloor:
        return category.items.any(_itemMatchesSelectedFilter);
      case filterWall:
        return category.items.any(_itemMatchesSelectedFilter);
      case filterAll:
      default:
        return true;
    }
  }

  List<MaterialCategory> get filteredCategories {
    return List<MaterialCategory>.unmodifiable(
      _categories.where(shouldShowCategory),
    );
  }

  /// Simple selection (most recently selected item across categories).
  MaterialItem? selectedItem;

  /// Category-scoped selection, as requested.
  final Map<String, MaterialItem?> selectedPerCategory =
      <String, MaterialItem?>{};

  Future<void> loadForProject(String project) async {
    if (_firestore == null) {
      _errorMessage = 'Materials Firestore service is not configured.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _firestore.fetchMaterialsForProject(project);
      _errorMessage = null;
    } catch (e) {
      _categories = const <MaterialCategory>[];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update selected item state and notify listeners.
  void selectItem(MaterialItem item) {
    selectItemForCategory(item.category, item);
  }

  /// Update selected item state scoped to a specific category key.
  ///
  /// Useful when a UI is keyed by `MaterialCategory.title` while the
  /// underlying `MaterialItem.category` may not exactly match that title.
  void selectItemForCategory(String category, MaterialItem item) {
    selectedItem = item;
    selectedPerCategory[category] = item;
    notifyListeners();
  }

  /// Returns description of currently selected item, with a fallback.
  String getSelectedDescription() {
    return selectedItem?.description ?? 'Select an item to view details.';
  }

  /// Returns items for a category, applying the active type filter.
  List<MaterialItem> getItemsByCategory(String category) {
    for (final cat in _categories) {
      if (cat.title == category) {
        return List<MaterialItem>.unmodifiable(
          cat.items.where(_itemMatchesSelectedFilter),
        );
      }
    }
    return const <MaterialItem>[];
  }

  List<MaterialItem> getRecommendedItemsForCategory(String category) {
    return getItemsByCategory(category).toList(growable: false);
  }

  List<MaterialItem> getAlternativeItemsForCategory(String category) {
    return getItemsByCategory(category).toList(growable: false);
  }

  /// Helper: first 4 items for a given category.
  List<MaterialItem> getInitialItemsForCategory(String category) {
    return getInitialItems(getItemsByCategory(category));
  }

  /// Helper: remaining items for a given category.
  List<MaterialItem> getRemainingItemsForCategory(String category) {
    return getRemainingItems(getItemsByCategory(category));
  }

  static List<MaterialItem> getInitialItems(List<MaterialItem> items) {
    if (items.isEmpty) return const <MaterialItem>[];
    return items.take(4).toList(growable: false);
  }

  static List<MaterialItem> getRemainingItems(List<MaterialItem> items) {
    if (items.length <= 4) return const <MaterialItem>[];
    return items.sublist(4);
  }

  MaterialItem? getSelectedForCategory(String category) {
    return selectedPerCategory[category];
  }

  void clearSelection({String? category}) {
    if (category == null) {
      selectedItem = null;
      selectedPerCategory.clear();
    } else {
      if (selectedItem?.category == category) {
        selectedItem = null;
      }
      selectedPerCategory.remove(category);
    }
    notifyListeners();
  }
}
