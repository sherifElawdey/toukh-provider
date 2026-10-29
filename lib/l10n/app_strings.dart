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
  static const Revenues = _Revenues();
  static const Welcome = _Welcome();
  static const Registration = _Registration();
  static const ShopRequests = _ShopRequests();
  static const Pending = _Pending();
  static const AppUpdate = _AppUpdate();
  static const Wallet = _Wallet();
  static const Drivers = _Drivers();
  static const Catalog = _Catalog();
  static const Company = _Company();
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
  String get mediaGalleryRationaleTitle => 'common.media_gallery_rationale_title';
  String get mediaGalleryRationaleBody => 'common.media_gallery_rationale_body';
  String get mediaCameraRationaleTitle => 'common.media_camera_rationale_title';
  String get mediaCameraRationaleBody => 'common.media_camera_rationale_body';
  String get egpAmount => 'common.egp_amount';
  String get egp => 'common.egp';
  String get signInRequired => 'common.sign_in_required';
  String get notSignedIn => 'common.not_signed_in';
  String get profileNotFound => 'common.profile_not_found';
  String get refresh => 'common.refresh';
  String get item => 'common.item';
  String get imageReadFailed => 'common.image_read_failed';
  String get durationSeconds => 'common.duration_seconds';
  String get durationMinutes => 'common.duration_minutes';
  String get durationMinutesSeconds => 'common.duration_minutes_seconds';
  String get daysShort => 'common.days_short';
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
  String get phoneAlreadyRegistered => 'auth.phone_already_registered';
  String get profilePendingTitle => 'auth.profile_pending_title';
  String get profilePendingSubtitle => 'auth.profile_pending_subtitle';
  String get phoneNotRegistered => 'auth.phone_not_registered';
  String get otpInvalidCode => 'auth.otp_invalid_code';
  String get otpRateLimited => 'auth.otp_rate_limited';
  String get otpSessionExpired => 'auth.otp_session_expired';
  String get otpSendFailed => 'auth.otp_send_failed';
  String get otpTwilioNotConfigured => 'auth.otp_twilio_not_configured';
  String get otpTrialUnverified => 'auth.otp_trial_unverified';
  String get phoneAlreadyVerified => 'auth.phone_already_verified';
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
  String get notNow => 'permissions.not_now';
  String get locationNeededTitle => 'permissions.location_needed_title';
  String get locationNeededBody => 'permissions.location_needed_body';
  String get notificationsNeededTitle =>
      'permissions.notifications_needed_title';
  String get notificationsNeededBody =>
      'permissions.notifications_needed_body';
  String get bannerTitle => 'permissions.banner_title';
  String get bannerSubtitle => 'permissions.banner_subtitle';
  String get allowLocation => 'permissions.allow_location';
  String get openSettings => 'permissions.open_settings';
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
  String get dashboardWalletRecharge => 'home.dashboard_wallet_recharge';
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
  String get fieldStartLocation => 'home_service_requests.field_start_location';
  String get fieldDestination => 'home_service_requests.field_destination';
  String get viewRouteOnMap => 'home_service_requests.view_route_on_map';
  String get fieldPreferredDate => 'home_service_requests.field_preferred_date';
  String get fieldCargo => 'home_service_requests.field_cargo';
  String get fieldDriver => 'home_service_requests.field_driver';
  String get withDriver => 'home_service_requests.with_driver';
  String get withoutDriver => 'home_service_requests.without_driver';
  String get fieldPreferredTime => 'home_service_requests.field_preferred_time';
  String get fieldProblem => 'home_service_requests.field_problem';
  String get preServiceAnswersTitle =>
      'home_service_requests.pre_service_answers_title';
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
  String get dateChangeTitle => 'home_service_requests.date_change_title';
  String get dateChangeReason => 'home_service_requests.date_change_reason';
  String get dateChangeSend => 'home_service_requests.date_change_send';
  String get dateChangeSent => 'home_service_requests.date_change_sent';
  String get dateChangePickDate => 'home_service_requests.date_change_pick_date';
  String get actionsCancelRequest =>
      'home_service_requests.actions_cancel_request';
  String get actionsReportProblem =>
      'home_service_requests.actions_report_problem';
  String get cancelReasonLabel => 'home_service_requests.cancel_reason';
  String get cancelPenaltyHint => 'home_service_requests.cancel_penalty_hint';
  String get cancelSent => 'home_service_requests.cancel_sent';
  String get reportReasonLabel => 'home_service_requests.report_reason';
  String get reportSent => 'home_service_requests.report_sent';
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
  String get preferredMorning => 'home_service_requests.preferred_morning';
  String get preferredEvening => 'home_service_requests.preferred_evening';
  String get preferredNight => 'home_service_requests.preferred_night';
  String get cancelFailed => 'home_service_requests.cancel_failed';
  String get completeFailed => 'home_service_requests.complete_failed';
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
  String get waCustomerMessage => 'orders.wa_customer_message';
  String get waActionPending => 'orders.wa_action_pending';
  String get waActionPreparing => 'orders.wa_action_preparing';
  String get waActionReady => 'orders.wa_action_ready';
  String get waActionOnTheWay => 'orders.wa_action_on_the_way';
  String get waActionDelivered => 'orders.wa_action_delivered';
  String get waActionCancelled => 'orders.wa_action_cancelled';
  String get waActionDefault => 'orders.wa_action_default';
  String get callCustomer => 'orders.call_customer';
  String get whatsAppCustomer => 'orders.whatsapp_customer';
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
  String get actionRerequestDriver => 'orders.action_rerequest_driver';
  String get actionReadyForPickup => 'orders.action_ready_for_pickup';
  String get searchingForDriver => 'orders.searching_for_driver';
  String get searchingForDriverTimer => 'orders.searching_for_driver_timer';
  String get detailDriverSearchStarted => 'orders.detail_driver_search_started';
  String get detailDriverAssigned => 'orders.detail_driver_assigned';
  String get actionDeliver => 'orders.action_deliver';
  String get actionOutForDelivery => 'orders.action_out_for_delivery';
  String get actionChangeDriver => 'orders.action_change_driver';
  String get awaitingDriverApproval => 'orders.awaiting_driver_approval';
  String get actionConfirmHandoff => 'orders.action_confirm_handoff';
  String get actionShowPickupQr => 'orders.action_show_pickup_qr';
  String get actionFinishOrder => 'orders.action_finish_order';
  String get completionCodeSheetTitle => 'orders.completion_code_sheet_title';
  String get completionCodeWrong => 'orders.completion_code_wrong';
  String get storeDriverPickTitle => 'orders.store_driver_pick_title';
  String get storeDriverPickSubtitle => 'orders.store_driver_pick_subtitle';
  String get storeDriverSearchHint => 'orders.store_driver_search_hint';
  String get storeDriverEmpty => 'orders.store_driver_empty';
  String get storeDriverLoadError => 'orders.store_driver_load_error';
  String get storeDriverOnline => 'orders.store_driver_online';
  String get storeDriverOffline => 'orders.store_driver_offline';
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
  String get requestDeliveryEmpty => 'orders.request_delivery_empty';
  String get requestDeliveryMissingLocation =>
      'orders.request_delivery_missing_location';
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
  String get detailStoreNote => 'orders.detail_store_note';
  String get detailSharedNote => 'orders.detail_shared_note';
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
  String get detailItemsTotal => 'orders.detail_items_total';
  String get detailDeliveryFee => 'orders.detail_delivery_fee';
  String get detailZoneInside => 'orders.detail_zone_inside';
  String get detailZoneOutside => 'orders.detail_zone_outside';
  String get detailServiceFee => 'orders.detail_service_fee';
  String get detailServiceFeeInfo => 'orders.detail_service_fee_info';
  String get detailCourierFeeHint => 'orders.detail_courier_fee_hint';
  String get detailOrderTotal => 'orders.detail_order_total';
  String get detailPickupQrTitle => 'orders.detail_pickup_qr_title';
  String get detailPickupQrHint => 'orders.detail_pickup_qr_hint';
  String get detailPickupQrDriverScanHint =>
      'orders.detail_pickup_qr_driver_scan_hint';
  String get detailPickupHandoffTitle => 'orders.detail_pickup_handoff_title';
  String get detailPickupHandoffHint => 'orders.detail_pickup_handoff_hint';
  String get detailPickupOtpOption => 'orders.detail_pickup_otp_option';
  String get detailPickupOtpHint => 'orders.detail_pickup_otp_hint';
  String get detailPickupQrOption => 'orders.detail_pickup_qr_option';
  String get handoffSuccessTitle => 'orders.handoff_success_title';
  String get handoffSuccessBody => 'orders.handoff_success_body';
  String get deliverMethodTitle => 'orders.deliver_method_title';
  String get deliverMethodSubtitle => 'orders.deliver_method_subtitle';
  String get deliverWithQr => 'orders.deliver_with_qr';
  String get deliverWithOtp => 'orders.deliver_with_otp';
  String get scanDeliveryQr => 'orders.scan_delivery_qr';
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
  String get pharmacyQuoteCourierFeeHint =>
      'orders.pharmacy_quote_courier_fee_hint';
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
  String get alertMoreItems => 'orders.alert_more_items';
  String get alertTotal => 'orders.alert_total';
  String get noReviewsYet => 'orders.no_reviews_yet';
  String get detailTotal => 'orders.detail_total';
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
  String get revenues => 'settings.revenues';
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
  String get deleteAccount => 'settings.delete_account';
  String get deleteAccountTitle => 'settings.delete_account_title';
  String get deleteAccountBody => 'settings.delete_account_body';
  String get deleteAccountContinue => 'settings.delete_account_continue';
  String get declaration => 'settings.declaration';
  String get legalOpenInBrowser => 'settings.legal_open_in_browser';
  String get legalOpenInBrowserHint => 'settings.legal_open_in_browser_hint';
  String get legalLaunchFailed => 'settings.legal_launch_failed';
  String get editProfileComingSoon => 'settings.edit_profile_coming_soon';
  String get walletComingSoon => 'settings.wallet_coming_soon';
  String get profileDriverFallback => 'settings.profile_driver_fallback';
  String get blackPoints => 'settings.black_points';
  String get blackPointsHint => 'settings.black_points_hint';
  String get commitmentPercent => 'settings.commitment_percent';
  String get avgAcceptTime => 'settings.avg_accept_time';
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
  String get brandInfo => 'settings.brand_info';
  String get brandInfoBannerTitle => 'settings.brand_info_banner_title';
  String get brandInfoBannerBody => 'settings.brand_info_banner_body';
  String get brandInfoNotAdded => 'settings.brand_info_not_added';
  String get brandPhone => 'settings.brand_phone';
  String get brandPhoneWhatsapp => 'settings.brand_phone_whatsapp';
  String get brandAddPhone => 'settings.brand_add_phone';
  String get brandRemovePhone => 'settings.brand_remove_phone';
  String get brandWebsite => 'settings.brand_website';
  String get brandFacebook => 'settings.brand_facebook';
  String get brandInstagram => 'settings.brand_instagram';
  String get brandTiktok => 'settings.brand_tiktok';
  String get brandEmail => 'settings.brand_email';
  String get brandEmailInvalid => 'settings.brand_email_invalid';
  String get brandSaved => 'settings.brand_saved';
  String get brandSaveFailed => 'settings.brand_save_failed';
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
  String get otherShopTitle => 'registration.other_shop_title';
  String get otherShopSubtitle => 'registration.other_shop_subtitle';
  String get otherShopTypesHint => 'registration.other_shop_types_hint';
  String get otherShopTypesSelected => 'registration.other_shop_types_selected';
  String get otherShopPickCategory => 'registration.other_shop_pick_category';
  String get otherShopReviewTitle => 'registration.other_shop_review_title';
  String get orderModeTitle => 'registration.order_mode_title';
  String get orderModeMenu => 'registration.order_mode_menu';
  String get orderModeMenuHint => 'registration.order_mode_menu_hint';
  String get orderModeCustom => 'registration.order_mode_custom';
  String get orderModeCustomHint => 'registration.order_mode_custom_hint';
  String get orderModeReviewTitle => 'registration.order_mode_review_title';
  String get kindTitle => 'registration.kind_title';
  String get kindSubtitle => 'registration.kind_subtitle';
  String get stageBusiness => 'registration.stage_business';
  String get stageAccount => 'registration.stage_account';
  String get stagePlace => 'registration.stage_place';
  String get stageReview => 'registration.stage_review';
  String get stageOf => 'registration.stage_of';
  String get shopCategorySubtitle => 'registration.shop_category_subtitle';
  String get serviceCategorySubtitle => 'registration.service_category_subtitle';
  String get credentialsSubtitle => 'registration.credentials_subtitle';
  String get secLogoTitle => 'registration.sec_logo_title';
  String get secLogoHint => 'registration.sec_logo_hint';
  String get secLoginTitle => 'registration.sec_login_title';
  String get secLoginHint => 'registration.sec_login_hint';
  String get secIdTitle => 'registration.sec_id_title';
  String get secIdHint => 'registration.sec_id_hint';
  String get profileSubtitle => 'registration.profile_subtitle';
  String get secBrandTitle => 'registration.sec_brand_title';
  String get secBrandHint => 'registration.sec_brand_hint';
  String get secDescriptionTitle => 'registration.sec_description_title';
  String get secDescriptionHint => 'registration.sec_description_hint';
  String get descriptionExample => 'registration.description_example';
  String get fieldRequired => 'registration.field_required';
  String get mapHint => 'registration.map_hint';
  String get hoursSubtitle => 'registration.hours_subtitle';
  String get deliverySubtitle => 'registration.delivery_subtitle';
  String get secOwnDeliveryTitle => 'registration.sec_own_delivery_title';
  String get secOwnDeliveryHint => 'registration.sec_own_delivery_hint';
  String get secPrepTitle => 'registration.sec_prep_title';
  String get secPrepHint => 'registration.sec_prep_hint';
  String get deliveryHavitFeeNote => 'registration.delivery_havit_fee_note';
  String get deliveryOwnPriceNote => 'registration.delivery_own_price_note';
  String get deliveryPricePerKmLabel => 'registration.delivery_price_per_km_label';
  String get reviewSubtitle => 'registration.review_subtitle';
  String get cuisineIllustrationHint => 'registration.cuisine_illustration_hint';
  String get shopCategoryTitle => 'registration.shop_category_title';
  String get serviceCategoryTitle => 'registration.service_category_title';
  String get credentialsTitle => 'registration.credentials_title';
  String get profileTitle => 'registration.profile_title';
  String get mapTitle => 'registration.map_title';
  String get locationOutsideServiceArea =>
      'registration.location_outside_service_area';
  String get hoursTitle => 'registration.hours_title';
  String get hoursWorkingDays => 'registration.hours_working_days';
  String get hoursWorkingDaysHint => 'registration.hours_working_days_hint';
  String get hoursForAllDays => 'registration.hours_for_all_days';
  String get hoursSameForAllHint => 'registration.hours_same_for_all_hint';
  String get hoursOpen24h => 'registration.hours_open_24h';
  String get hoursSelectOneDay => 'registration.hours_select_one_day';
  String get hoursEndAfterStart => 'registration.hours_end_after_start';
  String get hoursOvernight => 'registration.hours_overnight';
  String get hoursClosesNextDay => 'registration.hours_closes_next_day';
  String get hoursOvernightEarlier => 'registration.hours_overnight_earlier';
  String get deliveryTitle => 'registration.delivery_title';
  String get deliveryOffers => 'registration.delivery_offers';
  String get deliveryManageFromAccount =>
      'registration.delivery_manage_from_account';
  String get deliveryManageFromAccountHint =>
      'registration.delivery_manage_from_account_hint';
  String get deliveryPriceLabel => 'registration.delivery_price_label';
  String get deliveryPriceRequired => 'registration.delivery_price_required';
  String get reviewBusinessType => 'registration.review_business_type';
  String get reviewDeliveryNone => 'registration.review_delivery_none';
  String get reviewDeliveryFree => 'registration.review_delivery_free';
  String get reviewDeliveryPaid => 'registration.review_delivery_paid';
  String get reviewDeliveryNotSet => 'registration.review_delivery_not_set';
  String get reviewPrepTime => 'registration.review_prep_time';
  String get prepTimeRequired => 'registration.prep_time_required';
  String get deliveryModeFixed => 'registration.delivery_mode_fixed';
  String get deliveryModePerKm => 'registration.delivery_mode_per_km';
  String get deliveryModeByRegion => 'registration.delivery_mode_by_region';
  String get deliveryInnerCityLabel => 'registration.delivery_inner_city_label';
  String get deliveryInnerCityNote => 'registration.delivery_inner_city_note';
  String get deliveryOuterCityLabel => 'registration.delivery_outer_city_label';
  String get deliveryOuterCityNote => 'registration.delivery_outer_city_note';
  String get deliveryRegionRequired => 'registration.delivery_region_required';
  String get reviewDeliveryByRegion => 'registration.review_delivery_by_region';
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
  String get kindOtherShops => 'registration.kind_other_shops';
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

  String get preServiceQuestionsTitle =>
      'registration.pre_service_questions_title';
  String get preServiceQuestionsSubtitle =>
      'registration.pre_service_questions_subtitle';
  String get preServiceQuestionsHint =>
      'registration.pre_service_questions_hint';
  String get preServiceQuestionsEmpty =>
      'registration.pre_service_questions_empty';
  String get preServiceQuestionsAdd =>
      'registration.pre_service_questions_add';
  String get preServiceQuestionsMax =>
      'registration.pre_service_questions_max';
  String get preServiceQuestionLabel =>
      'registration.pre_service_question_label';
  String get preServiceQuestionsNone =>
      'registration.pre_service_questions_none';
  String get preServiceQuestionsCount =>
      'registration.pre_service_questions_count';

  /// Menu builder (categories + items)
  String get menuBuilderSubtitle =>
      'registration.menu_builder_subtitle';
  String get addCategory => 'registration.menu_add_category';
  String get categoryName => 'registration.menu_category_name';
  String get noCategoriesYet => 'registration.menu_no_categories_yet';
  String get addFirstCategoryHint =>
      'registration.menu_add_first_category_hint';
  String get addItem => 'registration.menu_add_item';
  String get bulkAddItems => 'registration.menu_bulk_add';
  String get bulkAddHint => 'registration.menu_bulk_add_hint';
  String get bulkAddRow => 'registration.menu_bulk_add_row';
  String get bulkAddInvalid => 'registration.menu_bulk_invalid';
  String get bulkAddSaved => 'registration.menu_bulk_saved';
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

  String get cuisineTitle => 'registration.cuisine_title';
  String get cuisineSubtitle => 'registration.cuisine_subtitle';
  String get cuisineRequired => 'registration.cuisine_required';
  String get menuEditCuisines => 'registration.menu_edit_cuisines';
  String get menuQr => 'registration.menu_qr';
  String get menuQrHint => 'registration.menu_qr_hint';
  String get menuQrShare => 'registration.menu_qr_share';
  String get menuItemAvailable => 'registration.menu_item_available';
  String get menuItemUnavailable => 'registration.menu_item_unavailable';
  String get menuItemOffer => 'registration.menu_item_offer';
  String get menuOfferNone => 'registration.menu_offer_none';
  String get menuOfferPercent => 'registration.menu_offer_percent';
  String get menuOfferFixed => 'registration.menu_offer_fixed';
  String get menuOfferPercentLabel => 'registration.menu_offer_percent_label';
  String get menuOfferFixedLabel => 'registration.menu_offer_fixed_label';
  String get hoursApplyToAll => 'registration.hours_apply_to_all';
  String get hoursApplyToAllHint => 'registration.hours_apply_to_all_hint';
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
  String get kindServiceEarning => 'wallet.kind_service_earning';
  String get kindOrderEarning => 'wallet.kind_order_earning';
  String get kindPayout => 'wallet.kind_payout';
  String get kindAdjustment => 'wallet.kind_adjustment';
  String get kindAppFee => 'wallet.kind_app_fee';
  String get kindCustomerServiceFee => 'wallet.kind_customer_service_fee';
}

class _Revenues {
  const _Revenues();
  String get title => 'revenues.title';
  String get monthFilter => 'revenues.month_filter';
  String get revenue => 'revenues.revenue';
  String get appFees => 'revenues.app_fees';
  String get customerServiceFees => 'revenues.customer_service_fees';
  String get accepted => 'revenues.accepted';
  String get rejected => 'revenues.rejected';
  String get revenueTrend => 'revenues.revenue_trend';
  String get statusBreakdown => 'revenues.status_breakdown';
  String get feesBreakdown => 'revenues.fees_breakdown';
  String get netAfterFees => 'revenues.net_after_fees';
  String get noData => 'revenues.no_data';
}

class _Catalog {
  const _Catalog();
  String get addFromCatalog => 'catalog.add_from_catalog';
  String get addFromCatalogHint => 'catalog.add_from_catalog_hint';
  String get title => 'catalog.title';
  String get search => 'catalog.search';
  String get all => 'catalog.all';
  String get inMenu => 'catalog.in_menu';
  String get empty => 'catalog.empty';
  String get noMatch => 'catalog.no_match';
  String get sizesTitle => 'catalog.sizes_title';
  String get sizesHint => 'catalog.sizes_hint';
  String get priceLabel => 'catalog.price_label';
  String get priceRequired => 'catalog.price_required';
  String get sizeRequired => 'catalog.size_required';
  String get available => 'catalog.available';
  String get availableHint => 'catalog.available_hint';
  String get menuSection => 'catalog.menu_section';
  String get addToMenu => 'catalog.add_to_menu';
  String get saveChanges => 'catalog.save_changes';
  String get removeFromMenu => 'catalog.remove_from_menu';
  String get added => 'catalog.added';
  String get removed => 'catalog.removed';
  String get addFromSupermarketCatalog => 'catalog.add_from_supermarket_catalog';
  String get addFromSupermarketCatalogHint => 'catalog.add_from_supermarket_catalog_hint';
  String get supermarketTitle => 'catalog.supermarket_title';
  String get supermarketSearch => 'catalog.supermarket_search';
  String get saleOptionsTitle => 'catalog.sale_options_title';
  String get saleOptionsHint => 'catalog.sale_options_hint';
  String get saleUnit => 'catalog.sale_unit';
  String get packCount => 'catalog.pack_count';
  String get packCountRequired => 'catalog.pack_count_required';
  String get optionDuplicate => 'catalog.option_duplicate';
  String get addSaleOption => 'catalog.add_sale_option';
  String get addCustomItem => 'catalog.add_custom_item';
  String get productGone => 'catalog.product_gone';
  String get otherSection => 'catalog.other_section';
  String get maxQty => 'catalog.max_qty';
  String get maxQtyHint => 'catalog.max_qty_hint';
  String get maxQtyInvalid => 'catalog.max_qty_invalid';
  String get salesTerms => 'catalog.sales_terms';
  String get salesTermsHint => 'catalog.sales_terms_hint';
  String get maxPerOrderShort => 'catalog.max_per_order_short';
  String get itemsCount => 'catalog.items_count';
  String get priceFrom => 'catalog.price_from';
  String get browse => 'catalog.browse';
  String get dishesTitle => 'catalog.dishes_title';
  String get dishesHint => 'catalog.dishes_hint';
  String get dishesSearch => 'catalog.dishes_search';
  String get dishesEmpty => 'catalog.dishes_empty';
  String get dishApplied => 'catalog.dish_applied';
}

class _Drivers {
  const _Drivers();
  String get pendingRequests => 'drivers.pending_requests';
  String get linkedDrivers => 'drivers.linked_drivers';
  String get noPendingRequests => 'drivers.no_pending_requests';
  String get noLinkedDrivers => 'drivers.no_linked_drivers';
  String get accept => 'drivers.accept';
  String get reject => 'drivers.reject';
  String get remove => 'drivers.remove';
  String get removeConfirmTitle => 'drivers.remove_confirm_title';
  String get removeConfirmBody => 'drivers.remove_confirm_body';
  String get driverRemoved => 'drivers.driver_removed';
  String get online => 'drivers.online';
  String get offline => 'drivers.offline';
  String get requestAccepted => 'drivers.request_accepted';
  String get requestRejected => 'drivers.request_rejected';
  String get actionFailed => 'drivers.action_failed';
  String get removeBusy => 'drivers.remove_busy';
  String get accountUnderReview => 'drivers.account_under_review';
  String get vehicleMotorcycle => 'drivers.vehicle_motorcycle';
  String get vehicleBicycle => 'drivers.vehicle_bicycle';
  String get vehicleTukTuk => 'drivers.vehicle_tuk_tuk';
}

class _Company {
  const _Company();
  // Registration
  String get registerCtaTitle => 'company.register_cta_title';
  String get registerCtaSubtitle => 'company.register_cta_subtitle';
  String get secInfoTitle => 'company.sec_info_title';
  String get secInfoHint => 'company.sec_info_hint';
  String get secLoginTitle => 'company.sec_login_title';
  String get secLoginHint => 'company.sec_login_hint';
  String get registerTitle => 'company.register_title';
  String get registerSubtitle => 'company.register_subtitle';
  String get companyName => 'company.company_name';
  String get managerName => 'company.manager_name';
  String get confirmPassword => 'company.confirm_password';
  String get passwordsMismatch => 'company.passwords_mismatch';
  String get requiredField => 'company.required_field';
  String get locationTitle => 'company.location_title';
  String get reviewTitle => 'company.review_title';
  String get reviewSubtitle => 'company.review_subtitle';
  String get location => 'company.location';
  String get serviceArea => 'company.service_area';
  String get createAccount => 'company.create_account';
  String get locationMissing => 'company.location_missing';
  // Status
  String get blockedTitle => 'company.blocked_title';
  String get blockedBody => 'company.blocked_body';
  String get activatingTitle => 'company.activating_title';
  String get activatingBody => 'company.activating_body';
  String get retryActivation => 'company.retry_activation';
  // Dashboard
  String get tabCouriers => 'company.tab_couriers';
  String get tabRequests => 'company.tab_requests';
  String get idTitle => 'company.id_title';
  String get idHint => 'company.id_hint';
  String get copyId => 'company.copy_id';
  String get shareId => 'company.share_id';
  String get shareIdMessage => 'company.share_id_message';
  String get statCouriers => 'company.stat_couriers';
  String get statOnline => 'company.stat_online';
  String get statBusy => 'company.stat_busy';
  String get statOrdersToday => 'company.stat_orders_today';
  String get statEarningsToday => 'company.stat_earnings_today';
  String get statDistanceToday => 'company.stat_distance_today';
  String get activeOrders => 'company.active_orders';
  String get noActiveOrders => 'company.no_active_orders';
  String get couriers => 'company.couriers';
  String get noCouriers => 'company.no_couriers';
  String get busy => 'company.busy';
  String get disabled => 'company.disabled';
  String get awaitingAdmin => 'company.awaiting_admin';
  String get ordersTodayCount => 'company.orders_today_count';
  String get noRequests => 'company.no_requests';
  String get requestsHint => 'company.requests_hint';
  String get requestedOn => 'company.requested_on';
  String get requestAccepted => 'company.request_accepted';
  String get requestRejected => 'company.request_rejected';
  String get actionFailed => 'company.action_failed';
  String get statsUnavailable => 'company.stats_unavailable';
  // Courier profile
  String get courierProfile => 'company.courier_profile';
  String get call => 'company.call';
  String get accountEnabled => 'company.account_enabled';
  String get accountDisabled => 'company.account_disabled';
  String get accountEnabledHint => 'company.account_enabled_hint';
  String get accountDisabledHint => 'company.account_disabled_hint';
  String get disableTitle => 'company.disable_title';
  String get disableBody => 'company.disable_body';
  String get enableTitle => 'company.enable_title';
  String get enableBody => 'company.enable_body';
  String get disable => 'company.disable';
  String get enable => 'company.enable';
  String get courierDisabled => 'company.courier_disabled';
  String get courierEnabled => 'company.courier_enabled';
  String get removeTitle => 'company.remove_title';
  String get removeBody => 'company.remove_body';
  String get remove => 'company.remove';
  String get courierRemoved => 'company.courier_removed';
  String get courierNotFound => 'company.courier_not_found';
  String get today => 'company.today';
  String get thisWeek => 'company.this_week';
  String get thisMonth => 'company.this_month';
  String get orders => 'company.orders';
  String get earnings => 'company.earnings';
  String get distance => 'company.distance';
  String get cancelled => 'company.cancelled';
  String get kmValue => 'company.km_value';
  String get egpValue => 'company.egp_value';
  String get dailyOrders => 'company.daily_orders';
  String get weeklyOrders => 'company.weekly_orders';
  String get tripTypes => 'company.trip_types';
  String get noTrips => 'company.no_trips';
  String get tripRestaurants => 'company.trip_restaurants';
  String get tripGrocery => 'company.trip_grocery';
  String get tripSupermarket => 'company.trip_supermarket';
  String get tripPharmacy => 'company.trip_pharmacy';
  String get tripExplore => 'company.trip_explore';
  String get tripMultiStop => 'company.trip_multi_stop';
  String get tripRide => 'company.trip_ride';
  String get tripOther => 'company.trip_other';
  String get jobRide => 'company.job_ride';
  String get jobDelivery => 'company.job_delivery';
  String get jobAssigned => 'company.job_assigned';
  String get jobPickedUp => 'company.job_picked_up';
  String get jobOnTheWay => 'company.job_on_the_way';
  String get jobInProgress => 'company.job_in_progress';
  String get vehicleCar => 'company.vehicle_car';
  // Company shell
  String get navCouriers => 'company.nav_couriers';
  String get navProfile => 'company.nav_profile';
  String get pendingRequestsBanner => 'company.pending_requests_banner';
  String get review => 'company.review';
  String get seeAll => 'company.see_all';
  String get todayByCourier => 'company.today_by_courier';
  String get filterAll => 'company.filter_all';
  String get filterLive => 'company.filter_live';
  String get filterDelivered => 'company.filter_delivered';
  String get filterCancelled => 'company.filter_cancelled';
  String get filterOnline => 'company.filter_online';
  String get last7Days => 'company.last_7_days';
  String get last30Days => 'company.last_30_days';
  String get ordersSearchHint => 'company.orders_search_hint';
  String get noOrders => 'company.no_orders';
  String get ordersLoadFailed => 'company.orders_load_failed';
  String get jobDelivered => 'company.job_delivered';
  String get jobCompleted => 'company.job_completed';
  String get jobCancelled => 'company.job_cancelled';
  String get couriersSearchHint => 'company.couriers_search_hint';
  String get noCouriersMatch => 'company.no_couriers_match';
  String get addCourier => 'company.add_courier';
  String get inviteTitle => 'company.invite_title';
  String get inviteStep1 => 'company.invite_step1';
  String get inviteStep2 => 'company.invite_step2';
  String get inviteStep3 => 'company.invite_step3';
  String get companyDetails => 'company.company_details';
  String get companyDetailsSaved => 'company.company_details_saved';
  String get phone => 'company.phone';
  String get address => 'company.address';
  String get readOnlyHint => 'company.read_only_hint';
  String get fleetEarnings => 'company.fleet_earnings';
  String get fleetEarningsHint => 'company.fleet_earnings_hint';
  String get dailyEarnings => 'company.daily_earnings';
  String get earningsByCourier => 'company.earnings_by_courier';
  String get companyIdShort => 'company.company_id_short';
  String get accountSection => 'company.account_section';
  String get fleetSection => 'company.fleet_section';
  String get statusActive => 'company.status_active';
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

class _ShopRequests {
  const _ShopRequests();
  String get title => 'shop_requests.title';
  String get tabNew => 'shop_requests.tab_new';
  String get tabQuoted => 'shop_requests.tab_quoted';
  String get tabClosed => 'shop_requests.tab_closed';
  String get empty => 'shop_requests.empty';
  String get sendPrice => 'shop_requests.send_price';
  String get changePrice => 'shop_requests.change_price';
  String get decline => 'shop_requests.decline';
  String get priceLabel => 'shop_requests.price_label';
  String get noteLabel => 'shop_requests.note_label';
  String get declineTitle => 'shop_requests.decline_title';
  String get declineReason => 'shop_requests.decline_reason';
  String get invalidPrice => 'shop_requests.invalid_price';
  String get quoteSent => 'shop_requests.quote_sent';
  String get declined => 'shop_requests.declined';
  String get statusPending => 'shop_requests.status_pending';
  String get statusQuoted => 'shop_requests.status_quoted';
  String get statusDeclined => 'shop_requests.status_declined';
  String get statusAccepted => 'shop_requests.status_accepted';
  String get statusCancelled => 'shop_requests.status_cancelled';
  String get yourNote => 'shop_requests.your_note';
  String get photoOnly => 'shop_requests.photo_only';
  String get dashboardTitle => 'shop_requests.dashboard_title';
  String get dashboardSubtitle => 'shop_requests.dashboard_subtitle';
  String get viewOrder => 'shop_requests.view_order';
}
