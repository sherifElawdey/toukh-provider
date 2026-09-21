import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../firestore/toukh_firestore_collections.dart';
import '../orders/assigned_driver_fields.dart';
import 'assigned_driver_identity.dart';

/// [AssignedDriverIdentity] that fills missing name/photo/phone from
/// `drivers/{driverId}` (read-only; does not write back to the order).
class AssignedDriverIdentityWithFallback extends StatelessWidget {
  const AssignedDriverIdentityWithFallback({
    super.key,
    required this.fields,
    this.variant = AssignedDriverIdentityVariant.expanded,
    this.eyebrow,
    this.fallbackName = 'Courier',
    this.showCallButton = true,
    this.padding,
    this.filled = true,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final AssignedDriverFields fields;
  final AssignedDriverIdentityVariant variant;
  final String? eyebrow;
  final String fallbackName;
  final bool showCallButton;
  final EdgeInsetsGeometry? padding;
  final bool filled;
  final FirebaseFirestore? _firestore;

  bool get _needsFallback {
    if (!fields.hasDriverId) return false;
    final nameMissing = fields.name == null || fields.name!.trim().isEmpty;
    final photoMissing =
        fields.photoUrl == null || fields.photoUrl!.trim().isEmpty;
    final phoneMissing = fields.phone == null || fields.phone!.trim().isEmpty;
    return nameMissing || photoMissing || phoneMissing;
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsFallback) {
      return AssignedDriverIdentity(
        fields: fields,
        variant: variant,
        eyebrow: eyebrow,
        fallbackName: fallbackName,
        showCallButton: showCallButton,
        padding: padding,
        filled: filled,
      );
    }

    final db = _firestore ?? FirebaseFirestore.instance;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db
          .collection(ToukhFirestoreCollections.drivers)
          .doc(fields.driverId!.trim())
          .snapshots(),
      builder: (context, snap) {
        final merged = fields.mergeDriverDoc(snap.data?.data());
        return AssignedDriverIdentity(
          fields: merged,
          variant: variant,
          eyebrow: eyebrow,
          fallbackName: fallbackName,
          showCallButton: showCallButton,
          padding: padding,
          filled: filled,
        );
      },
    );
  }
}
