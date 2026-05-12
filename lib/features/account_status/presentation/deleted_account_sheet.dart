import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

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
      builder: (ctx) => const _DeletedSheetBody(),
    );
  }
}

class _DeletedSheetBody extends StatelessWidget {
  const _DeletedSheetBody();

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': AppConstants.deletedAccountEmailSubject,
      },
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnack.show(
        context,
        message: 'Could not open mail client.'.tr,
        state: AppSnackState.error,
        icon: Icons.mail_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSizes.spaceXl,
          AppSizes.spaceLg,
          AppSizes.spaceXl,
          AppSizes.spaceXl + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(height: AppSizes.spaceLg),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                size: 56,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSizes.spaceLg),
            CustomText(
              AppStrings.AccountStatus.deletedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontTitle,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.AccountStatus.deletedSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: AppSizes.space2xl),
            FilledButton.icon(
              onPressed: () => _emailSupport(context),
              icon: const Icon(Icons.mail_outline_rounded),
              label: CustomText(AppStrings.AccountStatus.deletedAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            SizedBox(height: AppSizes.spaceMd),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().signOut();
              },
              child: CustomText(AppStrings.AccountStatus.signOut),
            ),
          ],
        ),
      ),
    );
  }
}
