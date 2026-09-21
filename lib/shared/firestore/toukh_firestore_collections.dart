/// Canonical Firestore collection and document id keys shared across Toukh apps.
///
/// Prefer these over string literals so path names stay consistent.
abstract final class ToukhFirestoreCollections {
  ToukhFirestoreCollections._();

  // --- Top-level collections ---
  static const users = 'users';
  static const providers = 'providers';
  static const drivers = 'drivers';
  static const masterOrders = 'masterOrders';
  static const finishedOrders = 'finishedOrders';
  static const deliveryTasks = 'deliveryTasks';
  static const deliveryRequests = 'deliveryRequests';

  /// Driver registration applications (courier / admin onboarding).
  /// Distinct from [deliveryRequests] (dispatch feed).
  static const deliveryRequestsOnboarding = 'Delivery Requests';

  static const orderTimelines = 'orderTimelines';
  static const rideRequests = 'rideRequests';

  /// Pending taxi rides waiting for a driver accept or client cancel.
  static const waitingRideRequests = 'waitingRideRequests';

  static const homeServiceRequests = 'homeServiceRequests';
  static const homeServicesCatalog = 'HomeServices';
  static const exploreProducts = 'exploreProducts';
  static const offers = 'offers';
  static const driverOffers = 'driverOffers';
  static const appSettings = 'appSettings';
  static const homeSections = 'homeSections';
  static const complaints = 'complaints';
  static const suggestions = 'suggestions';
  static const homeServiceChatReports = 'homeServiceChatReports';
  static const serviceAreas = 'service_areas';
  static const dispatchAuditLogs = 'dispatchAuditLogs';
  static const homeServiceChats = 'homeServiceChats';
  static const serviceProviderPresence = 'serviceProviderPresence';
  static const admins = 'admins';

  /// Synthetic parent used only to allocate auto-ids (no real documents stored).
  static const ids = '_ids';

  // --- Subcollections ---
  static const addresses = 'addresses';
  static const cartItems = 'cartItems';
  static const orders = 'orders';
  static const qaimaRequests = 'qaimaRequests';
  static const notifications = 'notifications';
  static const menu = 'Menu';
  static const menuItems = 'items';
  static const gallery = 'gallery';
  static const reviews = 'reviews';

  /// Driver reviews: `drivers/{driverId}/Ratings/{ratingId}`.
  static const driverRatings = 'Ratings';
  static const transactions = 'transactions';
  static const timelineEvents = 'events';
  static const blackPoints = 'blackPoints';
  static const performanceEvents = 'performanceEvents';
  static const messages = 'messages';

  /// Subcollection under `rideRequests/{rideId}`.
  static const rideDispatchAuditLogs = 'dispatchAuditLogs';
}

/// Well-known document ids under shared collections.
abstract final class ToukhFirestoreDocs {
  ToukhFirestoreDocs._();

  /// Singleton app config: `appSettings/global`.
  static const appSettingsGlobal = 'global';
}
