/// Translation keys used across the delivery app.
///
/// Resolve to localized strings via GetX `.tr` (e.g. `AppStrings.Auth.signIn.tr`).
/// English/Arabic maps live in [app_translations.dart].
///
// Section namespaces (App / Auth / Shell / …) are intentionally PascalCase
// to mirror the reference Toukh client (where they read as type-like
// namespaces, e.g. `AppStrings.Auth.signIn`).
// ignore_for_file: constant_identifier_names

library;

abstract final class AppStrings {
  AppStrings._();

  static const App = _App();
  static const Splash = _Splash();
  static const Common = _Common();
  static const Auth = _Auth();
  static const Permissions = _Permissions();
  static const AccountStatus = _AccountStatus();
  static const Shell = _Shell();
  static const Home = _Home();
  static const Orders = _Orders();
  static const Notifications = _Notifications();
  static const Accepted = _Accepted();
  static const Settings = _Settings();
  static const Welcome = _Welcome();
  static const Registration = _Registration();
  static const Pending = _Pending();
}

class _App {
  const _App();
  String get title => 'app.title';
  String get logoutConfirmTitle => 'app.logout_confirm_title';
  String get logoutConfirmBody => 'app.logout_confirm_body';
}

class _Splash {
  const _Splash();
  String get checkingAccount => 'splash.checking_account';
  String get preparingApp => 'splash.preparing_app';
}

class _Common {
  const _Common();
  String get continueLabel => 'common.continue';
  String get cancel => 'common.cancel';
  String get delete => 'common.delete';
  String get confirm => 'common.confirm';
  String get retry => 'common.retry';
  String get save => 'common.save';
  String get next => 'common.next';
  String get back => 'common.back';
  String get error => 'common.error';
  String get success => 'common.success';
  String get loading => 'common.loading';
  String get unknownError => 'common.unknown_error';
  String get light => 'common.light';
  String get dark => 'common.dark';
  String get english => 'common.english';
  String get arabic => 'common.arabic';
}

class _Auth {
  const _Auth();
  String get welcomeBack => 'auth.welcome_back';
  String get welcomeBackSubtitle => 'auth.welcome_back_subtitle';
  String get phoneNumber => 'auth.phone_number';
  String get phoneHint => 'auth.phone_hint';
  String get password => 'auth.password';
  String get signIn => 'auth.sign_in';
  String get createAccount => 'auth.create_account';
  String get createAccountTitle => 'auth.create_account_title';
  String get createAccountSubtitle => 'auth.create_account_subtitle';
  String get firstName => 'auth.first_name';
  String get lastName => 'auth.last_name';
  String get profilePhoto => 'auth.profile_photo';
  String get tapToAddPhoto => 'auth.tap_to_add_photo';
  String get tapToReplaceIdPhoto => 'auth.tap_to_replace_id_photo';
  String get idFrontPhoto => 'auth.id_front_photo';
  String get idBackPhoto => 'auth.id_back_photo';
  String get vehicleType => 'auth.vehicle_type';
  String get vehicleMotorcycle => 'auth.vehicle_motorcycle';
  String get vehicleBicycle => 'auth.vehicle_bicycle';
  String get vehicleTukTuk => 'auth.vehicle_tuktuk';
  String get submitApplication => 'auth.submit_application';
  String get alreadyHaveAccount => 'auth.already_have_account';
  String get forgotPassword => 'auth.forgot_password';
  String get forgotPasswordTitle => 'auth.forgot_password_title';
  String get forgotPasswordSubtitle => 'auth.forgot_password_subtitle';
  String get sendOtp => 'auth.send_otp';
  String get verify => 'auth.verify';
  String get verifyOtp => 'auth.verify_otp';
  String get otpSentTitle => 'auth.otp_sent_title';
  String get otpSentSubtitle => 'auth.otp_sent_subtitle';
  String get resendCodeIn => 'auth.resend_code_in';
  String get resendCode => 'auth.resend_code';
  String get resetPasswordTitle => 'auth.reset_password_title';
  String get resetPasswordSubtitle => 'auth.reset_password_subtitle';
  String get newPassword => 'auth.new_password';
  String get confirmPassword => 'auth.confirm_password';
  String get savePassword => 'auth.save_password';
  String get requestSubmittedTitle => 'auth.request_submitted_title';
  String get requestSubmittedSubtitle => 'auth.request_submitted_subtitle';
  String get backToLogin => 'auth.back_to_login';
  String get invalidPhone => 'auth.invalid_phone';
  String get minPasswordLength => 'auth.min_password_length';
  String get passwordsDoNotMatch => 'auth.passwords_do_not_match';
  String get firstNameRequired => 'auth.first_name_required';
  String get lastNameRequired => 'auth.last_name_required';
  String get profilePhotoRequired => 'auth.profile_photo_required';
  String get idPhotosRequired => 'auth.id_photos_required';
  String get registrationDataMissing => 'auth.registration_data_missing';
  String get profilePendingTitle => 'auth.profile_pending_title';
  String get profilePendingSubtitle => 'auth.profile_pending_subtitle';
  String get phoneNotRegistered => 'auth.phone_not_registered';
}

class _Permissions {
  const _Permissions();
  String get title => 'permissions.title';
  String get intro => 'permissions.intro';
  String get notifications => 'permissions.notifications';
  String get notificationsSubtitle => 'permissions.notifications_subtitle';
  String get location => 'permissions.location';
  String get locationSubtitle => 'permissions.location_subtitle';
  String get backgroundLocation => 'permissions.background_location';
  String get backgroundLocationSubtitle =>
      'permissions.background_location_subtitle';
  String get enable => 'permissions.enable';
  String get allowed => 'permissions.allowed';
  String get openSystemSettings => 'permissions.open_system_settings';
  String get continueLabel => 'permissions.continue';
}

class _AccountStatus {
  const _AccountStatus();
  String get blockedTitle => 'status.blocked_title';
  String get blockedReason => 'status.blocked_reason';
  String get blockedSince => 'status.blocked_since';
  String get blockedTimeRemaining => 'status.blocked_time_remaining';
  String get blockedIndefinite => 'status.blocked_indefinite';
  String get blockedLifted => 'status.blocked_lifted';
  String get unverifiedTitle => 'status.unverified_title';
  String get unverifiedSubtitle => 'status.unverified_subtitle';
  String get verifyPhoneTitle => 'status.verify_phone_title';
  String get verifyPhoneBody => 'status.verify_phone_body';
  String get verifyPhoneFallbackName => 'status.verify_phone_fallback_name';
  String get verifyPhoneInvalidStoredPhone =>
      'status.verify_phone_invalid_stored_phone';
  String get deletedTitle => 'status.deleted_title';
  String get deletedSubtitle => 'status.deleted_subtitle';
  String get deletedAction => 'status.deleted_action';
  String get signOut => 'status.sign_out';
  String get postLoginPendingTitle => 'status.post_login_pending_title';
  String get postLoginPendingBody => 'status.post_login_pending_body';
  String get postLoginContactUs => 'status.post_login_contact_us';
  String get postLoginVerifyPhonePrompt =>
      'status.post_login_verify_phone_prompt';
}

class _Shell {
  const _Shell();
  String get home => 'shell.home';
  String get orders => 'shell.orders';
  String get menu => 'shell.menu';
  String get gallery => 'shell.gallery';
  String get accepted => 'shell.accepted';
  String get settings => 'shell.settings';
  String get notificationsComingSoon => 'shell.notifications_coming_soon';
}

class _Home {
  const _Home();
  String get greetingMorning => 'home.greeting_morning';
  String get greetingAfternoon => 'home.greeting_afternoon';
  String get greetingEvening => 'home.greeting_evening';
  String get statusOnline => 'home.status_online';
  String get statusOffline => 'home.status_offline';
  String get goOnline => 'home.go_online';
  String get goOffline => 'home.go_offline';
  String get todayDeliveries => 'home.today_deliveries';
  String get todayEarnings => 'home.today_earnings';
  String get todayDistance => 'home.today_distance';
  String get activeOrderTitle => 'home.active_order_title';
  String get activeOrderViewAll => 'home.active_order_view_all';
  String get activeOrderEmpty => 'home.active_order_empty';
  String get activeOrderPickup => 'home.active_order_pickup';
  String get activeOrderDropoff => 'home.active_order_dropoff';
  String get activeOrderDistance => 'home.active_order_distance';
  String get activeOrderStatusAssigned => 'home.active_order_status_assigned';
  String get activeOrderStatusPickup => 'home.active_order_status_pickup';
  String get activeOrderStatusReceived => 'home.active_order_status_received';
  String get activeOrderStatusInTransit => 'home.active_order_status_in_transit';
  String get activeOrderStatusDelivered => 'home.active_order_status_delivered';
  String get activeOrderContinue => 'home.active_order_continue';
  String get notificationsSectionTitle => 'home.notifications_section_title';
  String get dashboardSubtitle => 'home.dashboard_subtitle';
  String get dashboardInProgressTitle => 'home.dashboard_in_progress_title';
  String get dashboardInProgressEmpty => 'home.dashboard_in_progress_empty';
  String get dashboardViewOrders => 'home.dashboard_view_orders';
  String get dashboardWalletTitle => 'home.dashboard_wallet_title';
  String get dashboardWalletPending => 'home.dashboard_wallet_pending';
  String get dashboardMockPreview => 'home.dashboard_mock_preview';
  String get dashboardStatOrders => 'home.dashboard_stat_orders';
  String get dashboardStatCompletion => 'home.dashboard_stat_completion';
  String get dashboardStatCompletionSub => 'home.dashboard_stat_completion_sub';
  String get dashboardStatRevenue => 'home.dashboard_stat_revenue';
  String get dashboardStatRevenueSub => 'home.dashboard_stat_revenue_sub';
  String get dashboardChartTitle => 'home.dashboard_chart_title';
  String get dashboardPeriodWeek => 'home.dashboard_period_week';
  String get dashboardPeriodMonth => 'home.dashboard_period_month';
  String get dashboardChartEmpty => 'home.dashboard_chart_empty';
  String get dashboardBestsellersTitle => 'home.dashboard_bestsellers_title';
  String get dashboardBestsellersEmpty => 'home.dashboard_bestsellers_empty';
  String get dashboardBestsellersUnits => 'home.dashboard_bestsellers_units';
  String get dashboardReviewsTitle => 'home.dashboard_reviews_title';
  String get dashboardReviewsEmpty => 'home.dashboard_reviews_empty';
  String get dashboardOrderShort => 'home.dashboard_order_short';
  String get dashboardStatusPreparing => 'home.dashboard_status_preparing';
  String get dashboardStatusNew => 'home.dashboard_status_new';
  String get dashboardStatusPickup => 'home.dashboard_status_pickup';
  String get seedDemoProvidersButton => 'home.seed_demo_providers_button';
  String get seedDemoProvidersTitle => 'home.seed_demo_providers_title';
  String get seedDemoProvidersBody => 'home.seed_demo_providers_body';
  String get seedDemoProvidersConfirm => 'home.seed_demo_providers_confirm';
  String get seedDemoProvidersDone => 'home.seed_demo_providers_done';
}

class _Notifications {
  const _Notifications();
  String get title => 'notifications.title';
  String get showMore => 'notifications.show_more';
  String get emptyTitle => 'notifications.empty_title';
  String get emptySubtitle => 'notifications.empty_subtitle';
}

class _Orders {
  const _Orders();
  String get title => 'orders.title';
  String get emptyNotified => 'orders.empty_notified';
  String get waitingSinceAcceptLabel => 'orders.waiting_since_accept_label';
  String get waitingOverdueMessage => 'orders.waiting_overdue_message';
  String get waitingClientHeadline => 'orders.waiting_client_headline';
  String get emptySubtitle => 'orders.empty_subtitle';
  String get actionAccept => 'orders.action_accept';
  String get actionDismiss => 'orders.action_dismiss';
  String get seeDetails => 'orders.see_details';
  String get notifiedElapsedLabel => 'orders.notified_elapsed_label';
  String get notifiedOverdueMessage => 'orders.notified_overdue_message';
  String get statusRunning => 'orders.status_running';
  String get statusFinished => 'orders.status_finished';
  String get listOrderIdLabel => 'orders.list_order_id_label';
  String get listCreatedLabel => 'orders.list_created_label';
  String get listViewFullDetails => 'orders.list_view_full_details';
  String get detailTitle => 'orders.detail_title';
  String get detailNotFound => 'orders.detail_not_found';
  String get detailOrderIdLabel => 'orders.detail_order_id_label';
  String get detailSectionTimeline => 'orders.detail_section_timeline';
  String get detailSectionAddresses => 'orders.detail_section_addresses';
  String get detailSectionNotes => 'orders.detail_section_notes';
  String get detailCreated => 'orders.detail_created';
  String get detailAccepted => 'orders.detail_accepted';
  String get detailPickedUp => 'orders.detail_picked_up';
  String get detailCompleted => 'orders.detail_completed';
  String get detailDatePending => 'orders.detail_date_pending';
  String get detailCustomer => 'orders.detail_customer';
  String get detailPickup => 'orders.detail_pickup';
  String get detailDropoff => 'orders.detail_dropoff';
  String get trackPlaced => 'orders.track_placed';
  String get trackAccepted => 'orders.track_accepted';
  String get trackPickup => 'orders.track_pickup';
  String get trackDelivered => 'orders.track_delivered';
  String get trackAwaitingUpdate => 'orders.track_awaiting_update';
}

class _Accepted {
  const _Accepted();
  String get title => 'accepted.title';
  String get emptyRunning => 'accepted.empty_running';
  String get emptySubtitle => 'accepted.empty_subtitle';
}

class _Settings {
  const _Settings();
  String get title => 'settings.title';
  String get appearance => 'settings.appearance';
  String get themeMode => 'settings.theme_mode';
  String get themeLight => 'settings.theme_light';
  String get themeDark => 'settings.theme_dark';
  String get language => 'settings.language';
  String get languageEnglish => 'settings.language_english';
  String get languageArabic => 'settings.language_arabic';
  String get account => 'settings.account';
  String get editProfile => 'settings.edit_profile';
  String get signOut => 'settings.sign_out';
  String get aboutApp => 'settings.about_app';
  String get appVersion => 'settings.app_version';
  String get ordersHistory => 'settings.orders_history';
  String get wallet => 'settings.wallet';
  String get legal => 'settings.legal';
  String get selectLanguage => 'settings.select_language';
  String get termsAndConditions => 'settings.terms_and_conditions';
  String get privacyPolicy => 'settings.privacy_policy';
  String get declaration => 'settings.declaration';
  String get legalOpenInBrowser => 'settings.legal_open_in_browser';
  String get legalOpenInBrowserHint => 'settings.legal_open_in_browser_hint';
  String get legalLaunchFailed => 'settings.legal_launch_failed';
  String get editProfileComingSoon => 'settings.edit_profile_coming_soon';
  String get walletComingSoon => 'settings.wallet_coming_soon';
  String get profileDriverFallback => 'settings.profile_driver_fallback';
}

class _Welcome {
  const _Welcome();
  String get title => 'welcome.title';
  String get subtitle => 'welcome.subtitle';
  String get chooseLanguage => 'welcome.choose_language';
  String get chooseTheme => 'welcome.choose_theme';
  String get regionUk => 'welcome.region_uk';
  String get regionEgypt => 'welcome.region_egypt';
}

class _Registration {
  const _Registration();
  String get kindTitle => 'registration.kind_title';
  String get kindSubtitle => 'registration.kind_subtitle';
  String get shopCategoryTitle => 'registration.shop_category_title';
  String get serviceCategoryTitle => 'registration.service_category_title';
  String get credentialsTitle => 'registration.credentials_title';
  String get profileTitle => 'registration.profile_title';
  String get mapTitle => 'registration.map_title';
  String get hoursTitle => 'registration.hours_title';
  String get hoursWorkingDays => 'registration.hours_working_days';
  String get hoursWorkingDaysHint => 'registration.hours_working_days_hint';
  String get hoursForAllDays => 'registration.hours_for_all_days';
  String get hoursSameForAllHint => 'registration.hours_same_for_all_hint';
  String get hoursOpen24h => 'registration.hours_open_24h';
  String get hoursSelectOneDay => 'registration.hours_select_one_day';
  String get hoursEndAfterStart => 'registration.hours_end_after_start';
  String get deliveryTitle => 'registration.delivery_title';
  String get reviewTitle => 'registration.review_title';
  String get submit => 'registration.submit';
  String get brandName => 'registration.brand_name';
  String get description => 'registration.description';
  String get kindShop => 'registration.kind_shop';
  String get kindService => 'registration.kind_service';
  String get kindRestaurant => 'registration.kind_restaurant';
  String get kindHomeService => 'registration.kind_home_service';
  String get kindSupermarket => 'registration.kind_supermarket';
  String get kindGrocery => 'registration.kind_grocery';
  String get kindPharmacy => 'registration.kind_pharmacy';
  String get kindHomeBrands => 'registration.kind_home_brands';
  String get brandLogoTitle => 'registration.brand_logo_title';
  String get brandImageRequired => 'registration.brand_image_required';
  String get homeCategoriesEmpty => 'registration.home_categories_empty';
  String get homeCategoriesLoadError => 'registration.home_categories_load_error';
  String get menuBuilderTitle => 'registration.menu_builder_title';
  String get portfolioTitle => 'registration.portfolio_title';

  /// Menu builder (categories + items)
  String get menuBuilderSubtitle =>
      'registration.menu_builder_subtitle';
  String get addCategory => 'registration.menu_add_category';
  String get categoryName => 'registration.menu_category_name';
  String get noCategoriesYet => 'registration.menu_no_categories_yet';
  String get addFirstCategoryHint =>
      'registration.menu_add_first_category_hint';
  String get addItem => 'registration.menu_add_item';
  String get editItem => 'registration.menu_edit_item';
  String get itemTitle => 'registration.menu_item_title';
  String get itemDescription => 'registration.menu_item_description';
  String get sizes => 'registration.menu_sizes';
  String get addSize => 'registration.menu_add_size';
  String get sizeLabel => 'registration.menu_size_label';
  String get pricePerSize => 'registration.menu_price_per_size';
  String get regular => 'registration.menu_regular';
  String get selectCategory => 'registration.menu_select_category';
  String get noItemsInCategory => 'registration.menu_no_items_in_category';
  String get confirmDeleteCategory =>
      'registration.menu_confirm_delete_category';
  String get confirmDeleteItem => 'registration.menu_confirm_delete_item';
  String get renameCategory => 'registration.menu_rename_category';
  String get menuMinimumItems => 'registration.menu_minimum_items';
  String get emptyCategoriesWarning =>
      'registration.menu_empty_categories_warning';
  String get duplicateCategory => 'registration.menu_duplicate_category';
  String get menuAllCategories => 'registration.menu_all_categories';
  String get menuItemPhoto => 'registration.menu_item_photo';
  String get menuTapAddItemPhoto => 'registration.menu_tap_add_item_photo';
  String get menuRemoveItemPhoto => 'registration.menu_remove_item_photo';
}

class _Pending {
  const _Pending();
  String get title => 'pending.title';
  String get subtitle => 'pending.subtitle';
}
