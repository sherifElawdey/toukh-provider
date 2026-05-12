/// Maps to customer [CartServiceType] where applicable:
/// [pharmacy], [supermarket], [fruitVeg] → grocery vertical for fruits/veg shop.
enum ShopCategory {
  pharmacy,
  supermarket,
  fruitVeg,
  restaurant;

  String get wireValue => name;

  static ShopCategory? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in ShopCategory.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
