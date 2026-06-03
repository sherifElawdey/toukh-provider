import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_menu_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_state.dart';
import 'package:toukh_provider/features/menu/presentation/models/menu_item_editor_result.dart';

class MenuBuilderCubit extends Cubit<MenuBuilderState> {
  MenuBuilderCubit({
    required AuthCubit authCubit,
    required AuthRepository authRepository,
    required MediaUploadService mediaUploadService,
    required ProviderMenuRepository menuRepository,
  })  : _authCubit = authCubit,
        _authRepository = authRepository,
        _media = mediaUploadService,
        _menuRepository = menuRepository,
        super(MenuBuilderState.empty);

  final AuthCubit _authCubit;
  final AuthRepository _authRepository;
  final MediaUploadService _media;
  final ProviderMenuRepository _menuRepository;

  StreamSubscription<ProviderMenuSnapshot>? _menuSub;

  String? get _uid {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return null;
    return auth.user.uid;
  }

  void seedFromAuthOnce() {
    if (state.seededFromProfile) return;
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;

    final uid = auth.user.uid;

    unawaited(_startMenuStream(uid, auth.profile.menuItems));
  }

  Future<void> _startMenuStream(
    String uid,
    List<MenuItemEntity>? legacyItems,
  ) async {
    try {
      await _menuRepository.migrateFromProfileArrayIfNeeded(uid, legacyItems);
    } catch (_) {
      // Stream will reflect partial state; UI can retry saves.
    }

    await _menuSub?.cancel();
    _menuSub = _menuRepository.watchMenu(uid).listen(
      (snapshot) {
        if (isClosed) return;
        final selected = state.selectedCategory;
        final nextSelected = selected != null && snapshot.categories.contains(selected)
            ? selected
            : (snapshot.categories.isEmpty ? null : snapshot.categories.first);
        emit(
          MenuBuilderState(
            categories: snapshot.categories,
            items: snapshot.items,
            selectedCategory: nextSelected,
            seededFromProfile: true,
          ),
        );
      },
      onError: (_) {
        if (!isClosed) {
          emit(state.copyWith(seededFromProfile: true));
        }
      },
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

  Future<String?> addCategory(String name) async {
    final uid = _uid;
    if (uid == null) return 'Not signed in.';
    try {
      await _menuRepository.upsertCategory(uid, name);
      emit(
        state.copyWith(
          updateSelectedCategory: true,
          selectedCategory: name,
        ),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> renameCategory(String oldName, String newName) async {
    final uid = _uid;
    if (uid == null) return 'Not signed in.';
    try {
      await _menuRepository.renameCategory(uid, oldName, newName);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteCategory(String name) async {
    final uid = _uid;
    if (uid == null) return 'Not signed in.';
    try {
      await _menuRepository.deleteCategory(uid, name);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeItem(String id) async {
    final uid = _uid;
    if (uid == null) return 'Not signed in.';
    MenuItemEntity? item;
    for (final e in state.items) {
      if (e.id == id) {
        item = e;
        break;
      }
    }
    if (item == null) return null;
    try {
      await _menuRepository.deleteItem(uid, item);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

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

    final uid = _uid;
    if (uid == null) return 'Not signed in.';
    try {
      await _menuRepository.upsertItem(uid, entity);
      await _maybeCompleteRegistration();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _maybeCompleteRegistration() async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    if (auth.profile.registrationExtrasComplete) return;
    final uid = auth.user.uid;
    if (!await _menuRepository.hasAnyItems(uid)) return;
    await _authCubit.markMenuRegistrationComplete();
  }

  Future<void> saveMenu({bool auto = false}) async {
    final uid = _uid;
    if (uid == null) {
      if (!auto) throw const MenuSaveNotSignedInException();
      return;
    }
    final hasItems = await _menuRepository.hasAnyItems(uid);
    if (!hasItems) {
      if (auto) return;
      throw const MenuSaveMinimumItemsException();
    }
    await _authCubit.markMenuRegistrationComplete();
  }

  @override
  Future<void> close() {
    unawaited(_menuSub?.cancel());
    return super.close();
  }
}

class MenuSaveMinimumItemsException implements Exception {
  const MenuSaveMinimumItemsException();

  @override
  String toString() => 'MenuSaveMinimumItemsException';
}

class MenuSaveNotSignedInException implements Exception {
  const MenuSaveNotSignedInException();

  @override
  String toString() => 'MenuSaveNotSignedInException';
}
