import 'package:bloc/bloc.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_state.dart';
import 'package:toukh_provider/features/menu/presentation/models/menu_item_editor_result.dart';

class MenuBuilderCubit extends Cubit<MenuBuilderState> {
  MenuBuilderCubit({
    required AuthCubit authCubit,
    required AuthRepository authRepository,
    required MediaUploadService mediaUploadService,
  })  : _authCubit = authCubit,
        _authRepository = authRepository,
        _media = mediaUploadService,
        super(MenuBuilderState.empty);

  final AuthCubit _authCubit;
  final AuthRepository _authRepository;
  final MediaUploadService _media;

  void seedFromAuthOnce() {
    if (state.seededFromProfile) return;
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;

    final menu = auth.profile.menuItems ?? const <MenuItemEntity>[];
    if (menu.isEmpty) {
      emit(state.copyWith(seededFromProfile: true));
      return;
    }

    final categories = <String>[];
    for (final item in menu) {
      final c = item.category?.trim();
      if (c != null && c.isNotEmpty && !categories.contains(c)) {
        categories.add(c);
      }
    }
    if (categories.isEmpty) categories.add('General');

    final items = <MenuItemEntity>[];
    for (final item in menu) {
      final c = item.category?.trim();
      if (c == null || c.isEmpty) {
        items.add(
          MenuItemEntity(
            id: item.id,
            name: item.name,
            description: item.description,
            imageUrl: item.imageUrl,
            category: categories.first,
            sizes: item.sizes,
          ),
        );
      } else {
        items.add(item);
      }
    }

    emit(
      MenuBuilderState(
        categories: categories,
        items: items,
        selectedCategory: categories.isEmpty ? null : categories.first,
        seededFromProfile: true,
      ),
    );
  }

  void toggleFilterAll() {
    emit(state.copyWith(clearSelectedCategory: true));
  }

  void toggleFilterCategory(String cat) {
    final deselect = state.selectedCategory == cat;
    emit(
      state.copyWith(
        updateSelectedCategory: true,
        selectedCategory: deselect ? null : cat,
      ),
    );
  }

  void addCategory(String name) {
    final categories = List<String>.from(state.categories)..add(name);
    emit(
      state.copyWith(
        categories: categories,
        updateSelectedCategory: true,
        selectedCategory: name,
      ),
    );
  }

  void renameCategory(String oldName, String newName) {
    final categories = List<String>.from(state.categories);
    final i = categories.indexOf(oldName);
    if (i >= 0) categories[i] = newName;

    var selected = state.selectedCategory;
    if (selected == oldName) selected = newName;

    final items = state.items.map((e) {
      if (e.category == oldName) {
        return MenuItemEntity(
          id: e.id,
          name: e.name,
          description: e.description,
          imageUrl: e.imageUrl,
          category: newName,
          sizes: e.sizes,
        );
      }
      return e;
    }).toList();

    emit(
      state.copyWith(
        categories: categories,
        items: items,
        updateSelectedCategory: true,
        selectedCategory: selected,
      ),
    );
  }

  void deleteCategory(String name) {
    final categories = List<String>.from(state.categories)..remove(name);
    final items = state.items.where((e) => e.category != name).toList();
    final selected = state.selectedCategory == name
        ? (categories.isEmpty ? null : categories.first)
        : state.selectedCategory;
    emit(
      state.copyWith(
        categories: categories,
        items: items,
        updateSelectedCategory: true,
        selectedCategory: selected,
      ),
    );
  }

  void upsertItem(MenuItemEntity entity) {
    final items = List<MenuItemEntity>.from(state.items);
    final idx = items.indexWhere((e) => e.id == entity.id);
    if (idx >= 0) {
      items[idx] = entity;
    } else {
      items.add(entity);
    }
    final selected = state.selectedCategory ?? entity.category;
    emit(
      state.copyWith(
        items: items,
        updateSelectedCategory: true,
        selectedCategory: selected,
      ),
    );
  }

  void removeItem(String id) {
    final items = state.items.where((e) => e.id != id).toList();
    emit(state.copyWith(items: items));
  }

  /// Returns an error message if upload fails; null on success (list updated + saved).
  Future<String?> commitItemEditorResult(MenuItemEditorResult result) async {
    var entity = result.entity;

    if (result.clearImage && result.newImageFile == null) {
      entity = MenuItemEntity(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        imageUrl: null,
        category: entity.category,
        sizes: entity.sizes,
      );
    }

    if (result.newImageFile != null) {
      final user = _authRepository.currentUser;
      if (user == null) return 'Not signed in.';
      try {
        final up = await _media.uploadImage(
          source: result.newImageFile!,
          objectPath: 'providers/${user.uid}/menu/${entity.id}.jpg',
        );
        entity = MenuItemEntity(
          id: entity.id,
          name: entity.name,
          description: entity.description,
          imageUrl: up.url,
          category: entity.category,
          sizes: entity.sizes,
        );
      } catch (e) {
        return e.toString();
      }
    }

    upsertItem(entity);
    await saveMenu(auto: true);
    return null;
  }

  Future<void> saveMenu({bool auto = false}) async {
    if (state.items.isEmpty) {
      if (auto) return;
      throw const MenuSaveMinimumItemsException();
    }
    await _authCubit.submitRegistrationMenu(state.items);
  }
}

class MenuSaveMinimumItemsException implements Exception {
  const MenuSaveMinimumItemsException();

  @override
  String toString() => 'MenuSaveMinimumItemsException';
}
