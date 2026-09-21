/// Paths for assets declared in this package's `pubspec.yaml`.
abstract final class ToukhUiAssets {
  ToukhUiAssets._();

  static const String brandingAppLogo = 'assets/branding/app_logo.png';
  static const String brandingAppIcon = 'assets/branding/app_icon.png';
  static const String brandingDriverLogo = 'assets/branding/driver_logo.png';
  static const String brandingPartnerLogo = 'assets/branding/partner_logo.png';
  static const String brandingHavitSplash = 'assets/branding/havit_splash.json';
  /// Full wide logo (PNG cropped from havit_logo.svg viewBox).
  static const String brandingHavitLogo = 'assets/branding/havit_logo.png';
  /// Raster square icon (extracted from havit_icon.svg wrapper).
  static const String brandingHavitIcon = 'assets/branding/havit_icon.png';
  static const String loaderHavit = 'assets/loaders/havit_loader.json';

  static const String sectionsRestaurants =
      'assets/sections/Restaurant Food Loading.json';
  static const String sectionsPharmacy =
      'assets/sections/a635001c-1170-11ee-bde1-778d5ef0c1ab.json';
  static const String sectionsGrocery = 'assets/sections/grocery.json';
  static const String sectionsSupermarkets =
      'assets/sections/Supermarket Cart.json';
  static const String sectionsHomeServices =
      'assets/sections/home_services2.json';
  static const String sectionsHomeSales =
      'assets/sections/delivery food splash.json';
  static const String sectionsTaxi = 'assets/sections/Moto riding.json';
  static const String sectionsQaima = 'assets/sections/qaima.json';

  static const String placeholderRestaurants =
      'assets/placeholders/restaurant_service.svg';
  static const String placeholderPharmacy =
      'assets/placeholders/pharmacy_service.svg';
  static const String placeholderGrocery =
      'assets/placeholders/grocery_service.svg';
  static const String placeholderSupermarkets =
      'assets/placeholders/supermarket_service.svg';
  static const String placeholderHomeServices =
      'assets/placeholders/home_service.svg';
  static const String placeholderHomeSales =
      'assets/placeholders/homesales_services.svg';
  static const String placeholderTaxi =
      'assets/placeholders/driver_service.svg';
  static const String placeholderProfileAvatar =
      'assets/placeholders/profile_avatar.png';
}

/// Must match `name:` in [pubspec.yaml] — used for [Image.asset] `package:`.
const String? kToukhUiPackageName = null;

/// Consumer / provider service verticals with bundled Lottie + placeholder art.
enum ToukhServiceCategory {
  restaurants(
    lottieAsset: ToukhUiAssets.sectionsRestaurants,
    placeholderAsset: ToukhUiAssets.placeholderRestaurants,
    defaultLoop: true,
  ),
  pharmacy(
    lottieAsset: ToukhUiAssets.sectionsPharmacy,
    placeholderAsset: ToukhUiAssets.placeholderPharmacy,
    defaultLoop: true,
  ),
  grocery(
    lottieAsset: ToukhUiAssets.sectionsGrocery,
    placeholderAsset: ToukhUiAssets.placeholderGrocery,
    defaultLoop: true,
  ),
  supermarkets(
    lottieAsset: ToukhUiAssets.sectionsSupermarkets,
    placeholderAsset: ToukhUiAssets.placeholderSupermarkets,
    defaultLoop: true,
  ),
  homeServices(
    lottieAsset: ToukhUiAssets.sectionsHomeServices,
    placeholderAsset: ToukhUiAssets.placeholderHomeServices,
    defaultLoop: false,
  ),
  homeSales(
    lottieAsset: ToukhUiAssets.sectionsHomeSales,
    placeholderAsset: ToukhUiAssets.placeholderHomeSales,
    defaultLoop: true,
  ),
  otherShops(
    lottieAsset: ToukhUiAssets.sectionsGrocery,
    placeholderAsset: ToukhUiAssets.placeholderGrocery,
    defaultLoop: true,
  ),
  taxi(
    lottieAsset: ToukhUiAssets.sectionsTaxi,
    placeholderAsset: ToukhUiAssets.placeholderTaxi,
    defaultLoop: true,
  ),
  qaima(
    lottieAsset: ToukhUiAssets.sectionsQaima,
    placeholderAsset: null,
    defaultLoop: true,
  );

  const ToukhServiceCategory({
    required this.lottieAsset,
    required this.placeholderAsset,
    required this.defaultLoop,
  });

  final String lottieAsset;
  final String? placeholderAsset;
  final bool defaultLoop;

  bool get hasPlaceholder => placeholderAsset != null;

  /// Maps provider [ServiceType] wire values (`restaurant`, `pharmacy`, …).
  static ToukhServiceCategory? fromProviderServiceType(String? wireValue) {
    if (wireValue == null || wireValue.isEmpty) return null;
    return switch (wireValue) {
      'restaurant' => ToukhServiceCategory.restaurants,
      'pharmacy' => ToukhServiceCategory.pharmacy,
      'grocery' => ToukhServiceCategory.grocery,
      'supermarket' => ToukhServiceCategory.supermarkets,
      'homeService' => ToukhServiceCategory.homeServices,
      'homeBrands' => ToukhServiceCategory.homeSales,
      _ => null,
    };
  }

  /// Shelf browse filter: grocery product types vs supermarket aisles.
  static ToukhServiceCategory forShelfBrowse({required bool isSupermarket}) {
    return isSupermarket
        ? ToukhServiceCategory.supermarkets
        : ToukhServiceCategory.grocery;
  }
}
