import 'package:flutter/material.dart';

import 'package:toukh_provider/features/account_status/presentation/widgets/deleted_account_sheet_body.dart';

/// Modal bottom sheet shown when the signed-in provider's status is `deleted`.
///
/// CTA opens the system mail composer with the support email + the required
/// "My Account Has Been Deleted" subject. After the sheet closes (either via
/// the action button or "Sign out"), the user is signed out.
abstract final class DeletedAccountSheet {
  const DeletedAccountSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DeletedAccountSheetBody(),
    );
  }
}
