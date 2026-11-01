import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/firestore/menu_category_slug.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/repositories/provider_menu_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderMenuRepository implements ProviderMenuRepository {
  FirestoreProviderMenuRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _menuRef(String providerId) {
    return _firestore.collection(ToukhFirestoreCollections.providers).doc(providerId).collection(ToukhFirestoreCollections.menu);
  }

  @override
  Stream<ProviderMenuSnapshot> watchMenu(String providerId) {
    final controller = StreamController<ProviderMenuSnapshot>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? menuSub;
    final itemSubs = <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final itemsByCategory = <String, List<MenuItemEntity>>{};
    var latestCategories = <String>[];

    void emitCombined() {
      if (controller.isClosed) return;
      final allItems = <MenuItemEntity>[];
      for (final list in itemsByCategory.values) {
        allItems.addAll(list);
      }
      controller.add(
        ProviderMenuSnapshot(categories: List.of(latestCategories), items: allItems),
      );
    }

    menuSub = _menuRef(providerId).snapshots().listen(
      (catSnap) {
        // Keep the listeners of categories that stay: reordering or renaming
        // must not blank the menu while items load again.
        final ids = catSnap.docs.map((d) => d.id).toSet();
        for (final id in itemSubs.keys.toList()) {
          if (ids.contains(id)) continue;
          unawaited(itemSubs.remove(id)?.cancel());
          itemsByCategory.remove(id);
        }
        latestCategories = [
          for (final d in MenuOrder.sorted(
            catSnap.docs,
            order: (d) => MenuOrder.read(d.data()[MenuOrder.field]),
            name: _categoryName,
          ))
            _categoryName(d),
        ].where((n) => n.trim().isNotEmpty).toList();

        if (catSnap.docs.isEmpty) {
          controller.add(const ProviderMenuSnapshot(categories: [], items: []));
          return;
        }

        for (final catDoc in catSnap.docs) {
          final catId = catDoc.id;
          if (itemSubs.containsKey(catId)) continue;
          itemsByCategory[catId] = const [];
          itemSubs[catId] = catDoc.reference
              .collection(ToukhFirestoreCollections.menuItems)
              .snapshots()
              .listen((itemsSnap) {
            itemsByCategory[catId] = MenuOrder.sortedItemMaps(
              itemsSnap.docs.map((d) => d.data()),
            ).map(MenuItemEntity.fromFirestore).toList();
            emitCombined();
          });
        }
        emitCombined();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await menuSub?.cancel();
      for (final s in itemSubs.values) {
        await s.cancel();
      }
    };

    return controller.stream;
  }

  static String _categoryName(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      d.data()['displayName'] as String? ?? d.id;

  /// Firestore batches allow 500 writes; keep headroom.
  Future<void> _writeOrder(
    List<(DocumentReference<Map<String, dynamic>>, int)> rows,
  ) async {
    for (var i = 0; i < rows.length; i += 450) {
      final batch = _firestore.batch();
      for (final (ref, order) in rows.skip(i).take(450)) {
        batch.update(ref, {MenuOrder.field: order});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> reorderCategories(
    String providerId,
    List<String> displayNames,
  ) async {
    final docs = await _menuRef(providerId).get();
    final byName = {for (final d in docs.docs) _categoryName(d): d.reference};
    await _writeOrder([
      for (final (i, name) in displayNames.indexed)
        if (byName[name] case final ref?) (ref, i),
    ]);
  }

  @override
  Future<void> reorderItems(
    String providerId,
    String category,
    List<String> itemIds,
  ) async {
    final catRef = await _categoryRefByDisplayName(providerId, category);
    if (catRef == null) return;
    final docs = await catRef.collection(ToukhFirestoreCollections.menuItems).get();
    final byId = {
      for (final d in docs.docs) (d.data()['id'] as String?) ?? d.id: d.reference,
    };
    await _writeOrder([
      for (final (i, id) in itemIds.indexed)
        if (byId[id] case final ref?) (ref, i),
    ]);
  }

  Future<DocumentReference<Map<String, dynamic>>> _resolveCategoryRef(
    String providerId,
    String displayName,
  ) async {
    final name = displayName.trim().isEmpty ? 'General' : displayName.trim();
    final menu = _menuRef(providerId);
    final existing = await menu.get();
    for (final doc in existing.docs) {
      final dn = doc.data()['displayName'] as String? ?? '';
      if (dn == name) return doc.reference;
    }
    final key = uniqueCategoryKey(
      name,
      existing.docs.map((d) => d.id),
    );
    final ref = menu.doc(key);
    await ref.set({
      'displayName': name,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _categoryRefByDisplayName(
    String providerId,
    String displayName,
  ) async {
    final name = displayName.trim();
    if (name.isEmpty) return null;
    final existing = await _menuRef(providerId).get();
    for (final doc in existing.docs) {
      final dn = doc.data()['displayName'] as String? ?? '';
      if (dn == name) return doc.reference;
    }
    return null;
  }

  @override
  Future<void> upsertCategory(String providerId, String displayName) async {
    await _resolveCategoryRef(providerId, displayName);
  }

  @override
  Future<void> upsertItem(String providerId, MenuItemEntity item) async {
    final categoryName = item.category?.trim().isNotEmpty == true
        ? item.category!.trim()
        : 'General';
    final catRef = await _resolveCategoryRef(providerId, categoryName);
    final data = item.toFirestore()
      ..['category'] = categoryName
      ..['providerId'] = providerId
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await catRef.collection(ToukhFirestoreCollections.menuItems).doc(item.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteItem(String providerId, MenuItemEntity item) async {
    final categoryName = item.category?.trim();
    if (categoryName == null || categoryName.isEmpty) return;
    final catRef = await _categoryRefByDisplayName(providerId, categoryName);
    if (catRef == null) return;
    await catRef.collection(ToukhFirestoreCollections.menuItems).doc(item.id).delete();
    final remaining = await catRef.collection(ToukhFirestoreCollections.menuItems).limit(1).get();
    if (remaining.docs.isEmpty) {
      await catRef.delete();
    }
  }

  @override
  Future<void> deleteCategory(String providerId, String displayName) async {
    final catRef = await _categoryRefByDisplayName(providerId, displayName);
    if (catRef == null) return;
    final batch = _firestore.batch();
    final items = await catRef.collection(ToukhFirestoreCollections.menuItems).get();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(catRef);
    await batch.commit();
  }

  @override
  Future<void> renameCategory(
    String providerId,
    String oldDisplayName,
    String newDisplayName,
  ) async {
    final catRef = await _categoryRefByDisplayName(providerId, oldDisplayName);
    if (catRef == null) return;
    final trimmedNew = newDisplayName.trim();
    if (trimmedNew.isEmpty) return;

    await catRef.set({
      'displayName': trimmedNew,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final items = await catRef.collection(ToukhFirestoreCollections.menuItems).get();
    final batch = _firestore.batch();
    for (final doc in items.docs) {
      batch.update(doc.reference, {
        'category': trimmedNew,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<bool> hasAnyItems(String providerId) async {
    final cats = await _menuRef(providerId).get();
    for (final cat in cats.docs) {
      final items = await cat.reference.collection(ToukhFirestoreCollections.menuItems).limit(1).get();
      if (items.docs.isNotEmpty) return true;
    }
    return false;
  }

  @override
  Future<void> migrateFromProfileArrayIfNeeded(
    String providerId,
    List<MenuItemEntity>? legacyItems,
  ) async {
    if (legacyItems == null || legacyItems.isEmpty) return;
    final menu = await _menuRef(providerId).limit(1).get();
    if (menu.docs.isNotEmpty) return;

    final categories = <String>{};
    for (final item in legacyItems) {
      final c = item.category?.trim();
      if (c != null && c.isNotEmpty) categories.add(c);
    }
    if (categories.isEmpty) categories.add('General');
    for (final c in categories) {
      await upsertCategory(providerId, c);
    }
    for (final item in legacyItems) {
      await upsertItem(providerId, item);
    }
  }
}
