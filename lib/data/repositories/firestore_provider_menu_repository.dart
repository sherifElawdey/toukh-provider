import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/firestore/menu_category_slug.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/repositories/provider_menu_repository.dart';

class FirestoreProviderMenuRepository implements ProviderMenuRepository {
  FirestoreProviderMenuRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _menuRef(String providerId) {
    return _firestore.collection('providers').doc(providerId).collection('Menu');
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

    void cancelItemSubs() {
      for (final s in itemSubs.values) {
        unawaited(s.cancel());
      }
      itemSubs.clear();
      itemsByCategory.clear();
    }

    menuSub = _menuRef(providerId).snapshots().listen(
      (catSnap) {
        cancelItemSubs();
        latestCategories = catSnap.docs
            .map((d) => d.data()['displayName'] as String? ?? d.id)
            .where((n) => n.trim().isNotEmpty)
            .toList();

        if (catSnap.docs.isEmpty) {
          controller.add(const ProviderMenuSnapshot(categories: [], items: []));
          return;
        }

        for (final catDoc in catSnap.docs) {
          final catId = catDoc.id;
          itemsByCategory[catId] = const [];
          itemSubs[catId] = catDoc.reference
              .collection('items')
              .snapshots()
              .listen((itemsSnap) {
            itemsByCategory[catId] = itemsSnap.docs
                .map((d) => MenuItemEntity.fromFirestore(d.data()))
                .toList();
            emitCombined();
          });
        }
        emitCombined();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await menuSub?.cancel();
      cancelItemSubs();
    };

    return controller.stream;
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
    await catRef.collection('items').doc(item.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteItem(String providerId, MenuItemEntity item) async {
    final categoryName = item.category?.trim();
    if (categoryName == null || categoryName.isEmpty) return;
    final catRef = await _categoryRefByDisplayName(providerId, categoryName);
    if (catRef == null) return;
    await catRef.collection('items').doc(item.id).delete();
    final remaining = await catRef.collection('items').limit(1).get();
    if (remaining.docs.isEmpty) {
      await catRef.delete();
    }
  }

  @override
  Future<void> deleteCategory(String providerId, String displayName) async {
    final catRef = await _categoryRefByDisplayName(providerId, displayName);
    if (catRef == null) return;
    final batch = _firestore.batch();
    final items = await catRef.collection('items').get();
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

    final items = await catRef.collection('items').get();
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
      final items = await cat.reference.collection('items').limit(1).get();
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
