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
  static const HomeServiceSchedule = _HomeServiceSchedule();
  static const HomeServiceRequests = _HomeServiceRequests();
  static const Orders = _Orders();
  static const Notifications = _Notifications();
  static const Accepted = _Accepted();
  static const Settings = _Settings();
  static const Welcome = _Welcome();
  static const Registration = _Registration();
  static const Pending = _Pending();
  static const AppUpdate = _AppUpdate();
  static const Wallet = _Wallet();
  static const Drivers = _Drivers();
  static const OrderHistory = _OrderHistory();
  static const FirebaseErrors = _FirebaseErrors();
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

class _AppUpdate {
  const _AppUpdate();
  String get title => 'app_update.title';
  String get description => 'app_update.description';
  String get openStore => 'app_update.open_store';
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
  String get otpSentWhatsapp => 'auth.otp_sent_whatsapp';
  String get otpSentSms => 'auth.otp_sent_sms';
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
  String get otpInvalidCode => 'auth.otp_invalid_code';
  String get otpRateLimited => 'auth.otp_rate_limited';
  String get otpSessionExpired => 'auth.otp_session_expired';
  String get otpSendFailed => 'auth.otp_send_failed';
  String get otpTwilioNotConfigured => 'auth.otp_twilio_not_configured';
  String get otpTrialUnverified => 'auth.otp_trial_unverified';
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
  String get schedule => 'shell.schedule';
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
  String get dashboardStatOrders => 'home.dashboard_stat_orders';
  String get dashboardStatCompletion => 'home.dashboard_stat_completion';
  String get dashboardStatCompletionSub => 'home.dashboard_stat_completion_sub';
  String get dashboardStatRevenue => 'home.dashboard_stat_revenue';
  String get dashboardStatRevenueSub => 'home.dashboard_stat_revenue_sub';
  String get dashboardCanceld => 'home.dashboard_canceld';
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
  String get dashboardStatTodayCaption => 'home.dashboard_stat_today_caption';
  String get dashboardPendingOrdersTitle => 'home.dashboard_pending_orders_title';
  String get dashboardPendingOrdersSubtitle =>
      'home.dashboard_pending_orders_subtitle';
  String get tabOverview => 'home.tab_overview';
  String get tabSchedule => 'home.tab_schedule';
}

class _HomeServiceSchedule {
  const _HomeServiceSchedule();
  String get emptyDay => 'home_service_schedule.empty_day';
  String get today => 'home_service_schedule.today';
  String get tomorrow => 'home_service_schedule.tomorrow';
  String get priceLabel => 'home_service_schedule.price_label';
}

class _HomeServiceRequests {
  const _HomeServiceRequests();
  String get title => 'home_service_requests.title';
  String get tabIncoming => 'home_service_requests.tab_incoming';
  String get tabInProgress => 'home_service_requests.tab_in_progress';
  String get tabHistory => 'home_service_requests.tab_history';
  String get emptyIncoming => 'home_service_requests.empty_incoming';
  String get emptyInProgress => 'home_service_requests.empty_in_progress';
  String get emptyHistory => 'home_service_requests.empty_history';
  String get emptyHistoryCompleted =>
      'home_service_requests.empty_history_completed';
  String get emptyHistoryCancelled =>
      'home_service_requests.empty_history_cancelled';
  String get historyFilterAll => 'home_service_requests.history_filter_all';
  String get historyFilterCompleted =>
      'home_service_requests.history_filter_completed';
  String get historyFilterCancelled =>
      'home_service_requests.history_filter_cancelled';
  String get detailTitle => 'home_service_requests.detail_title';
  String get notFound => 'home_service_requests.not_found';
  String get accept => 'home_service_requests.accept';
  String get decline => 'home_service_requests.decline';
  String get updated => 'home_service_requests.updated';
  String get fieldCategory => 'home_service_requests.field_category';
  String get fieldStatus => 'home_service_requests.field_status';
  String get fieldRequested => 'home_service_requests.field_requested';
  String get fieldAddress => 'home_service_requests.field_address';
  String get fieldPreferredTime => 'home_service_requests.field_preferred_time';
  String get fieldProblem => 'home_service_requests.field_problem';
  String get noAddress => 'home_service_requests.no_address';
  String get dashboardPendingTitle =>
      'home_service_requests.dashboard_pending_title';
  String get dashboardPendingSubtitle =>
      'home_service_requests.dashboard_pending_subtitle';
  String get customerFallback => 'home_service_requests.customer_fallback';
  String get placedAtLabel => 'home_service_requests.placed_at_label';
  String get statusPending => 'home_service_requests.status_pending';
  String get statusTendering => 'home_service_requests.status_tendering';
  String get statusQuoted => 'home_service_requests.status_quoted';
  String get statusAwaitingCustomer =>
      'home_service_requests.status_awaiting_customer';
  String get statusAwaitingProvider =>
      'home_service_requests.status_awaiting_provider';
  String get statusAccepted => 'home_service_requests.status_accepted';
  String get statusCompleted => 'home_service_requests.status_completed';
  String get statusCancelled => 'home_service_requests.status_cancelled';
  String get statusDeclined => 'home_service_requests.status_declined';
  String get sendQuote => 'home_service_requests.send_quote';
  String get quoteSheetTitle => 'home_service_requests.quote_sheet_title';
  String get quoteClientPriceLabel => 'home_service_requests.quote_client_price_label';
  String get quoteUseClientPrice => 'home_service_requests.quote_use_client_price';
  String get quotePriceLabel => 'home_service_requests.quote_price_label';
  String get quotePickVisitDate => 'home_service_requests.quote_pick_visit_date';
  String get quoteSendToClient => 'home_service_requests.quote_send_to_client';
  String get quoteSent => 'home_service_requests.quote_sent';
  String get quoteInvalidPrice => 'home_service_requests.quote_invalid_price';
  String get quoteVisitDateRequired => 'home_service_requests.quote_visit_date_required';
  String get fieldClientPrice => 'home_service_requests.field_client_price';
  String get fieldQuotedPrice => 'home_service_requests.field_quoted_price';
  String get fieldVisitDate => 'home_service_requests.field_visit_date';
  String get onMyWay => 'home_service_requests.on_my_way';
  String get finishVisit => 'home_service_requests.finish_visit';
  String get onMyWayBlocked => 'home_service_requests.on_my_way_blocked';
  String get onMyWayBlockedNamed =>
      'home_service_requests.on_my_way_blocked_named';
  String get contactCustomer => 'home_service_requests.contact_customer';
  String get contactCustomerUnavailable =>
      'home_service_requests.contact_customer_unavailable';
  String get visitToday => 'home_service_requests.visit_today';
  String get visitTomorrow => 'home_service_requests.visit_tomorrow';
  String get visitInDays => 'home_service_requests.visit_in_days';
  String get visitOverdue => 'home_service_requests.visit_overdue';
  String get visitOverdueDays => 'home_service_requests.visit_overdue_days';
  String get visitOverdueBanner => 'home_service_requests.visit_overdue_banner';
  String get statusOnTheWay => 'home_service_requests.status_on_the_way';
  String get statusInProgress => 'home_service_requests.status_in_progress';
}

class _Notifications {
  const _Notifications();
  String get title => 'notifications.title';
  String get showMore => 'notifications.show_more';
  String get emptyTitle => 'notifications.empty_title';
  String get emptySubtitle => 'notifications.empty_subtitle';
  String get inboxTitle => 'notifications.inbox.title';
  String get inboxMarkAllRead => 'notifications.inbox.mark_all_read';
  String get inboxClearAll => 'notifications.inbox.clear_all';
  String get inboxClearAllConfirm => 'notifications.inbox.clear_all_confirm';
  String get inboxShowUnreadOnly => 'notifications.inbox.show_unread_only';
  String get inboxEmptyTitle => 'notifications.inbox.empty_title';
  String get inboxEmptySubtitle => 'notifications.inbox.empty_subtitle';
  String get inboxNoUnread => 'notifications.inbox.no_unread';
  String get categoryMessage => 'notifications.category.message';
  String get categoryOrder => 'notifications.category.order';
  String get categorySupport => 'notifications.category.support';
  String get categorySystem => 'notifications.category.system';
  String get statusPlaced => 'notifications.status.placed';
  String get statusPreparing => 'notifications.status.preparing';
  String get statusDriverAssigned => 'notifications.status.driver_assigned';
  String get statusReadyForPickup => 'notifications.status.ready_for_pickup';
  String get statusOnTheWay => 'notifications.status.on_the_way';
  String get statusPickedUp => 'notifications.status.picked_up';
  String get statusDelivered => 'notifications.status.delivered';
  String get statusCancelled => 'notifications.status.cancelled';
}

class _Orders {
  const _Orders();
  String get title => 'orders.title';
  String get emptyNotified => 'orders.empty_notified';
  String get waitingSinceAcceptLabel => 'orders.waiting_since_accept_label';
  String get waitingOverdueMessage => 'orders.waiting_overdue_message';
  String get waitingClientHeadline => 'orders.waiting_client_headline';
  String get emptySubtitle => 'orders.empty_subtitle';
  String get tabIncoming => 'orders.tab_incoming';
  String get tabInProgress => 'orders.tab_in_progress';
  String get tabOutgoing => 'orders.tab_outgoing';
  String get tabDelivered => 'orders.tab_delivered';
  String get emptyIncoming => 'orders.empty_incoming';
  String get emptyInProgress => 'orders.empty_in_progress';
  String get emptyOutgoing => 'orders.empty_outgoing';
  String get emptyDelivered => 'orders.empty_delivered';
  String get filterNewest => 'orders.filter_newest';
  String get filterOldest => 'orders.filter_oldest';
  String get filterWithCourier => 'orders.filter_with_courier';
  String get actionApprove => 'orders.action_approve';
  String get actionCancel => 'orders.action_cancel';
  String get actionRequestDelivery => 'orders.action_request_delivery';
  String get actionReadyForPickup => 'orders.action_ready_for_pickup';
  String get actionDeliver => 'orders.action_deliver';
  String get actionConfirmHandoff => 'orders.action_confirm_handoff';
  String get storeDeliveryLabel => 'orders.store_delivery_label';
  String get courierAssignedLabel => 'orders.courier_assigned_label';
  String get elapsedSinceDispatch => 'orders.elapsed_since_dispatch';
  String get statusNew => 'orders.status_new';
  String get statusPreparing => 'orders.status_preparing';
  String get statusCourierRequested => 'orders.status_courier_requested';
  String get statusCourierAssigned => 'orders.status_courier_assigned';
  String get statusReadyForPickup => 'orders.status_ready_for_pickup';
  String get statusOutForDelivery => 'orders.status_out_for_delivery';
  String get statusPickup => 'orders.status_pickup';
  String get statusDelivered => 'orders.status_delivered';
  String get statusCancelled => 'orders.status_cancelled';
  String get requestDeliveryTitle => 'orders.request_delivery_title';
  String get requestDeliveryHint => 'orders.request_delivery_hint';
  String get requestDeliveryConfirm => 'orders.request_delivery_confirm';
  String get driverAssignedTitle => 'orders.driver_assigned_title';
  String get driverAssignedBody => 'orders.driver_assigned_body';
  String get driverAssignedDone => 'orders.driver_assigned_done';
  String get courierLateWarning => 'orders.courier_late_warning';
  String get actionAccept => 'orders.action_accept';
  String get actionDismiss => 'orders.action_dismiss';
  String get seeDetails => 'orders.see_details';
  String get orderTypeGroup => 'orders.order_type_group';
  String get orderTypeIndividual => 'orders.order_type_individual';
  String get itemsMore => 'orders.items_more';
  String get exploreItemsLabel => 'orders.explore_items_label';
  String get placedAtLabel => 'orders.placed_at_label';
  String get waitingElapsedLabel => 'orders.waiting_elapsed_label';
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
  String get detailClient => 'orders.detail_client';
  String get detailSectionNotes => 'orders.detail_section_notes';
  String get detailCreated => 'orders.detail_created';
  String get detailAccepted => 'orders.detail_accepted';
  String get detailPickedUp => 'orders.detail_picked_up';
  String get detailCompleted => 'orders.detail_completed';
  String get detailDatePending => 'orders.detail_date_pending';
  String get detailCustomer => 'orders.detail_customer';
  String get pharmacyRequestCustomerLabel =>
      'orders.pharmacy_request_customer_label';
  String get pharmacyCustomerContactHidden =>
      'orders.pharmacy_customer_contact_hidden';
  String get detailPickup => 'orders.detail_pickup';
  String get detailDropoff => 'orders.detail_dropoff';
  String get viewOnMap => 'orders.view_on_map';
  String get mapUnavailable => 'orders.map_unavailable';
  String get noAddress => 'orders.no_address';
  String get detailPlacedAt => 'orders.detail_placed_at';
  String get detailSectionItems => 'orders.detail_section_items';
  String get detailSubtotal => 'orders.detail_subtotal';
  String get detailDeliveryFee => 'orders.detail_delivery_fee';
  String get detailOrderTotal => 'orders.detail_order_total';
  String get detailPickupQrTitle => 'orders.detail_pickup_qr_title';
  String get detailPickupQrHint => 'orders.detail_pickup_qr_hint';
  String get detailCancelledByProvider => 'orders.detail_cancelled_by_provider';
  String get detailCancelledByCustomer => 'orders.detail_cancelled_by_customer';
  String get detailCancelledAt => 'orders.detail_cancelled_at';
  String get detailCancelReason => 'orders.detail_cancel_reason';
  String get detailCancellationSection => 'orders.detail_cancellation_section';
  String get detailCancelled => 'orders.detail_cancelled';
  String get pharmacyReviewOrder => 'orders.pharmacy_review_order';
  String get pharmacyApproveTitle => 'orders.pharmacy_approve_title';
  String get pharmacyPharmacistNote => 'orders.pharmacy_pharmacist_note';
  String get pharmacyPharmacistNoteHint => 'orders.pharmacy_pharmacist_note_hint';
  String get pharmacyQuoteSubtotal => 'orders.pharmacy_quote_subtotal';
  String get pharmacyQuoteDeliveryFee => 'orders.pharmacy_quote_delivery_fee';
  String get pharmacyAcceptOrder => 'orders.pharmacy_accept_order';
  String get pharmacyQuoteSubtotalRequired => 'orders.pharmacy_quote_subtotal_required';
  String get pharmacyQuoteSelectItems => 'orders.pharmacy_quote_select_items';
  String get pharmacyQuoteFailed => 'orders.pharmacy_quote_failed';
  String get imageLoadFailed => 'orders.image_load_failed';
  String get pharmacyStatusQuoted => 'orders.pharmacy_status_quoted';
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
  String get reviews => 'settings.reviews';
  String get reviewsAverage => 'settings.reviews_average';
  String get reviewsCount => 'settings.reviews_count';
  String get manageDrivers => 'settings.manage_drivers';
  String get gallery => 'settings.gallery';
  String get gallerySubtitle => 'settings.gallery_subtitle';
  String get copyProviderId => 'settings.copy_provider_id';
  String get copyProviderIdHint => 'settings.copy_provider_id_hint';
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
  String get accountDetails => 'settings.account_details';
  String get businessInfo => 'settings.business_info';
  String get contactInfo => 'settings.contact_info';
  String get location => 'settings.location';
  String get operations => 'settings.operations';
  String get accountInfo => 'settings.account_info';
  String get providerId => 'settings.provider_id';
  String get memberSince => 'settings.member_since';
  String get phoneVerified => 'settings.phone_verified';
  String get email => 'settings.email';
  String get statusActive => 'settings.status_active';
  String get statusPending => 'settings.status_pending';
  String get statusUnverified => 'settings.status_unverified';
  String get statusBlocked => 'settings.status_blocked';
  String get statusDeleted => 'settings.status_deleted';
  String get aboutTagline => 'settings.about_tagline';
  String get support => 'settings.support';
  String get copyright => 'settings.copyright';
  String get copied => 'settings.copied';
  String get fieldLocked => 'settings.field_locked';
  String get changeProfilePhoto => 'settings.change_profile_photo';
  String get takePhoto => 'settings.take_photo';
  String get pickFromGallery => 'settings.pick_from_gallery';
  String get profilePhotoUpdated => 'settings.profile_photo_updated';
  String get profilePhotoFailed => 'settings.profile_photo_failed';
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
  String get deliveryPriceRequired => 'registration.delivery_price_required';
  String get reviewBusinessType => 'registration.review_business_type';
  String get reviewDeliveryNone => 'registration.review_delivery_none';
  String get reviewDeliveryFree => 'registration.review_delivery_free';
  String get reviewDeliveryPaid => 'registration.review_delivery_paid';
  String get reviewDeliveryNotSet => 'registration.review_delivery_not_set';
  String get reviewPrepTime => 'registration.review_prep_time';
  String get deliveryModeFixed => 'registration.delivery_mode_fixed';
  String get deliveryModePerKm => 'registration.delivery_mode_per_km';
  String get reviewTitle => 'registration.review_title';
  String get reviewEditSave => 'registration.review_edit_save';
  String get reviewTapToEdit => 'registration.review_tap_to_edit';
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
  String get portfolioHint => 'registration.portfolio_hint';
  String get portfolioAddPhoto => 'registration.portfolio_add_photo';
  String get portfolioMinOne => 'registration.portfolio_min_one';

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

class _Wallet {
  const _Wallet();
  String get myWallet => 'wallet.my_wallet';
  String get toukhServiceWallet => 'wallet.toukh_service_wallet';
  String get availableBalance => 'wallet.available_balance';
  String get pendingBalance => 'wallet.pending_balance';
  String get cardMask => 'wallet.card_mask';
  String get earningsOverview => 'wallet.earnings_overview';
  String get week => 'wallet.week';
  String get month => 'wallet.month';
  String get year => 'wallet.year';
  String get noEarningsInPeriod => 'wallet.no_earnings_in_period';
  String get recentEarnings => 'wallet.recent_earnings';
  String get seeAll => 'wallet.see_all';
  String get lastEarning => 'wallet.last_earning';
  String get noEarningsYet => 'wallet.no_earnings_yet';
  String get requestPayout => 'wallet.request_payout';
  String get requestPayoutComingSoon => 'wallet.request_payout_coming_soon';
  String get allTransactions => 'wallet_transactions.all_transactions';
  String get noTransactionsYet => 'wallet_transactions.no_transactions_yet';
  String get walletEarningOrder => 'wallet_earning.order';
  String get walletEarningOrderId => 'wallet_earning.order_id';
  String get earningCredit => 'wallet.earning_credit';
  String get earningDebit => 'wallet.earning_debit';
  String get amount => 'wallet.amount';
  String get date => 'wallet.date';
  String get title => 'wallet.title';
  String get details => 'wallet.details';
  String get type => 'wallet.type';
  String get total => 'wallet.total';
}

class _Drivers {
  const _Drivers();
  String get pendingRequests => 'drivers.pending_requests';
  String get linkedDrivers => 'drivers.linked_drivers';
  String get noPendingRequests => 'drivers.no_pending_requests';
  String get noLinkedDrivers => 'drivers.no_linked_drivers';
  String get accept => 'drivers.accept';
  String get reject => 'drivers.reject';
  String get online => 'drivers.online';
  String get offline => 'drivers.offline';
  String get requestAccepted => 'drivers.request_accepted';
  String get requestRejected => 'drivers.request_rejected';
  String get actionFailed => 'drivers.action_failed';
  String get vehicleMotorcycle => 'drivers.vehicle_motorcycle';
  String get vehicleBicycle => 'drivers.vehicle_bicycle';
  String get vehicleTukTuk => 'drivers.vehicle_tuk_tuk';
}

class _OrderHistory {
  const _OrderHistory();
  String get title => 'order_history.title';
  String get totalOrders => 'order_history.total_orders';
  String get completedOrders => 'order_history.completed_orders';
  String get canceledOrders => 'order_history.canceled_orders';
  String get dateFrom => 'order_history.date_from';
  String get dateTo => 'order_history.date_to';
  String get applyFilter => 'order_history.apply_filter';
  String get clearFilter => 'order_history.clear_filter';
  String get empty => 'order_history.empty';
  String get loadError => 'order_history.load_error';
  String get selectDate => 'order_history.select_date';
  String get invalidDateRange => 'order_history.invalid_date_range';
}

class _FirebaseErrors {
  const _FirebaseErrors();
  String get unknown => 'firebase.errors.unknown';
  String get signInAgain => 'firebase.errors.sign_in_again';
  String get permissionDenied => 'firebase.errors.permission_denied';
  String get network => 'firebase.errors.network';
  String get tryAgain => 'firebase.errors.try_again';
  String get serviceUnavailable => 'firebase.errors.service_unavailable';
  String get actionNotAllowed => 'firebase.errors.action_not_allowed';
  String get authInvalidCredentials => 'firebase.errors.auth_invalid_credentials';
  String get authEmailInUse => 'firebase.errors.auth_email_in_use';
  String get authTooManyRequests => 'firebase.errors.auth_too_many_requests';
  String get authRequiresRecentLogin => 'firebase.errors.auth_requires_recent_login';
  String get indexBuilding => 'firebase.errors.index_building';
}
