import 'package:toukh_provider/shared/firestore/toukh_firestore_collections.dart';

/// Who receives an inbox notification (determines Firestore parent collection).
enum ToukhNotificationRecipient {
  customer,
  provider,
  driver;

  String get collectionName {
    switch (this) {
      case ToukhNotificationRecipient.customer:
        return ToukhFirestoreCollections.users;
      case ToukhNotificationRecipient.provider:
        return ToukhFirestoreCollections.providers;
      case ToukhNotificationRecipient.driver:
        return ToukhFirestoreCollections.drivers;
    }
  }
}
