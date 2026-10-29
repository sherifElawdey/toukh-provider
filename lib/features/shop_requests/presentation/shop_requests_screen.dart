import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Live custom requests sent to this store (newest first).
Stream<List<ShopRequest>> watchProviderShopRequests(String providerId) =>
    getIt<FirebaseFirestore>()
        .collection(shopRequestsCollection)
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((s) => [
              for (final d in s.docs) ShopRequest.fromFirestore(d.id, d.data()),
            ]..sort(ShopRequest.byRecent));

/// Inbox for "other shops" stores in custom-request mode: reply to each
/// request with a price (the customer then accepts and it becomes an order)
/// or decline it.
class ShopRequestsScreen extends StatelessWidget {
  const ShopRequestsScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(ToukhIcons.back),
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          title: CustomText(AppStrings.ShopRequests.title),
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.ShopRequests.tabNew.tr),
              Tab(text: AppStrings.ShopRequests.tabQuoted.tr),
              Tab(text: AppStrings.ShopRequests.tabClosed.tr),
            ],
          ),
        ),
        body: StreamBuilder<List<ShopRequest>>(
          stream: watchProviderShopRequests(providerId),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: CustomText(appFirebaseError(snap.error!)));
            }
            if (!snap.hasData) return const Center(child: AppLoadingMark());
            final all = snap.data!;
            List<ShopRequest> only(bool Function(ShopRequestStatus s) test) =>
                [for (final r in all) if (test(r.status)) r];
            return TabBarView(
              children: [
                _RequestList(items: only((s) => s == ShopRequestStatus.pending)),
                _RequestList(
                  items: only((s) => s == ShopRequestStatus.quoted || s == ShopRequestStatus.accepting),
                ),
                _RequestList(items: only((s) => !s.isOpen)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.items});

  final List<ShopRequest> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: ToukhSectionEmptyState(
          category: ToukhServiceCategory.otherShops,
          message: AppStrings.ShopRequests.empty.tr,
        ),
      );
    }
    return ListView.separated(
      padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceMd, bottom: AppSizes.space2xl),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSizes.spaceMd),
      itemBuilder: (context, i) => _RequestCard(request: items[i]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ShopRequest request;

  Future<void> _call(BuildContext context, Map<String, dynamic> data, String successKey) async {
    try {
      await context.withAppLoading(
        () => getIt<FirebaseFunctions>().httpsCallable('respondShopRequest').call<void>(data),
      );
      if (context.mounted) {
        AppSnack.show(context, message: successKey.tr, state: AppSnackState.success);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnack.show(context, message: appFirebaseError(e), state: AppSnackState.error);
      }
    }
  }

  Future<void> _quote(BuildContext context) async {
    final result = await showModalBottomSheet<(double, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _QuoteSheet(initialPrice: request.quotedPriceEgp, initialNote: request.providerNote),
    );
    if (result == null || !context.mounted) return;
    await _call(context, {
      'requestId': request.id,
      'action': 'quote',
      'priceEgp': result.$1,
      'note': result.$2,
    }, AppStrings.ShopRequests.quoteSent);
  }

  Future<void> _decline(BuildContext context) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.ShopRequests.declineTitle),
        content: TextField(
          controller: note,
          maxLength: 500,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(labelText: AppStrings.ShopRequests.declineReason.tr),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.Common.cancel.tr)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.ShopRequests.decline.tr),
          ),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (ok != true || !context.mounted) return;
    await _call(context, {'requestId': request.id, 'action': 'decline', 'note': text},
        AppStrings.ShopRequests.declined);
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(AppSizes.spaceMd),
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(child: HavitNetworkImage(imageUrl: url, fit: BoxFit.contain)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = request;
    final created = r.createdAt;
    final (statusText, statusColor) = switch (r.status) {
      ShopRequestStatus.pending => (AppStrings.ShopRequests.statusPending.tr, AppColors.warning),
      ShopRequestStatus.quoted || ShopRequestStatus.accepting => (
          AppStrings.ShopRequests.statusQuoted.trParams({'price': _money(r.quotedPriceEgp)}),
          AppColors.secondColor,
        ),
      ShopRequestStatus.declined => (AppStrings.ShopRequests.statusDeclined.tr, scheme.onSurfaceVariant),
      ShopRequestStatus.accepted => (AppStrings.ShopRequests.statusAccepted.tr, AppColors.success),
      ShopRequestStatus.cancelled => (AppStrings.ShopRequests.statusCancelled.tr, scheme.onSurfaceVariant),
    };

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    r.customerName ?? '—',
                    style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w800),
                  ),
                ),
                if (created != null)
                  CustomText(
                    DateFormat('d MMM, h:mm a', Get.locale?.languageCode).format(created),
                    style: TextStyle(fontSize: AppSizes.fontCaption, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
            SizedBox(height: AppSizes.spaceSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomText(
                    r.text.isEmpty ? AppStrings.ShopRequests.photoOnly : r.text,
                    style: TextStyle(fontSize: AppSizes.fontBody, color: scheme.onSurface, height: 1.45),
                  ),
                ),
                if (r.imageUrl != null) ...[
                  SizedBox(width: AppSizes.spaceMd),
                  GestureDetector(
                    onTap: () => _openImage(context, r.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: HavitNetworkImage(imageUrl: r.imageUrl!, width: 76, height: 76, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: AppSizes.spaceMd),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: CustomText(
                  statusText,
                  style: TextStyle(fontSize: AppSizes.fontCaption, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ),
            if (r.providerNote != null && r.status != ShopRequestStatus.pending) ...[
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                AppStrings.ShopRequests.yourNote.trParams({'note': r.providerNote!}),
                style: TextStyle(fontSize: AppSizes.fontCaption, color: scheme.onSurfaceVariant),
              ),
            ],
            if (r.status == ShopRequestStatus.pending || r.status == ShopRequestStatus.quoted) ...[
              SizedBox(height: AppSizes.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      text: AppStrings.ShopRequests.decline,
                      onTap: () => _decline(context),
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceMd),
                  Expanded(
                    child: AppFilledButton(
                      text: r.status == ShopRequestStatus.quoted
                          ? AppStrings.ShopRequests.changePrice
                          : AppStrings.ShopRequests.sendPrice,
                      onTap: () => _quote(context),
                    ),
                  ),
                ],
              ),
            ],
            if (r.status == ShopRequestStatus.accepted && r.masterOrderId != null) ...[
              SizedBox(height: AppSizes.spaceMd),
              AppOutlinedButton(
                text: AppStrings.ShopRequests.viewOrder,
                onTap: () => context.push(AppRoutes.orderDetailPath(r.masterOrderId!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _money(double? v) {
  if (v == null) return '—';
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

class _QuoteSheet extends StatefulWidget {
  const _QuoteSheet({this.initialPrice, this.initialNote});

  final double? initialPrice;
  final String? initialNote;

  @override
  State<_QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends State<_QuoteSheet> {
  late final _price = TextEditingController(
    text: widget.initialPrice == null ? '' : _money(widget.initialPrice),
  );
  late final _note = TextEditingController(text: widget.initialNote ?? '');
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final v = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) {
      setState(() => _error = AppStrings.ShopRequests.invalidPrice.tr);
      return;
    }
    Navigator.pop(context, (v, _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSizes.screenPadding.copyWith(
        top: AppSizes.spaceLg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.spaceLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            AppStrings.ShopRequests.sendPrice,
            style: const TextStyle(fontSize: AppSizes.fontTitle, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: AppSizes.spaceMd),
          TextField(
            controller: _price,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [const EnglishDigitsInputFormatter(), FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: AppStrings.ShopRequests.priceLabel.tr,
              errorText: _error,
            ),
            onChanged: (_) => _error == null ? null : setState(() => _error = null),
          ),
          SizedBox(height: AppSizes.spaceMd),
          TextField(
            controller: _note,
            maxLength: 500,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(labelText: AppStrings.ShopRequests.noteLabel.tr),
          ),
          SizedBox(height: AppSizes.spaceMd),
          AppFilledButton(text: AppStrings.ShopRequests.sendPrice, onTap: _submit),
        ],
      ),
    );
  }
}
