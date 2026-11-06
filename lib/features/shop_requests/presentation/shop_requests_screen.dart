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

/// Special requests sent to this shop: review each list, mark every item in
/// stock (with its price and an optional note) or not, and send it to the
/// customer, who accepts it (it becomes an order) or declines it. The shop
/// can also decline the whole request.
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
    if (request.items.isNotEmpty) return _priceList(context);
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

  Future<void> _priceList(BuildContext context) async {
    final result = await showModalBottomSheet<(List<Map<String, dynamic>>, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ListPricingSheet(request: request),
    );
    if (result == null || !context.mounted) return;
    await _call(context, {
      'requestId': request.id,
      'action': 'quote',
      'items': result.$1,
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
                  child: r.items.isEmpty
                      ? CustomText(
                          r.text.isEmpty ? AppStrings.ShopRequests.photoOnly : r.text,
                          style: TextStyle(fontSize: AppSizes.fontBody, color: scheme.onSurface, height: 1.45),
                        )
                      : ShopRequestItemsList(request: r),
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
            SizedBox(height: AppSizes.spaceSm),
            _StatusPrompt(text: _promptFor(r.status).tr, color: statusColor),
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
                          : r.items.isNotEmpty
                              ? AppStrings.ShopRequests.priceList
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

/// What the shop should do (or wait for) at each step.
String _promptFor(ShopRequestStatus status) => switch (status) {
      ShopRequestStatus.pending => AppStrings.ShopRequests.promptPending,
      ShopRequestStatus.quoted || ShopRequestStatus.accepting => AppStrings.ShopRequests.promptQuoted,
      ShopRequestStatus.accepted => AppStrings.ShopRequests.promptAccepted,
      ShopRequestStatus.declined => AppStrings.ShopRequests.promptDeclined,
      ShopRequestStatus.cancelled => AppStrings.ShopRequests.promptCancelled,
    };

class _StatusPrompt extends StatelessWidget {
  const _StatusPrompt({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsRegular.info, size: 16, color: color),
          SizedBox(width: AppSizes.spaceXs),
          Expanded(
            child: CustomText(
              text,
              style: TextStyle(fontSize: AppSizes.fontCaption, height: 1.4, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// The customer's list, with the shop's answer for each item once priced.
class ShopRequestItemsList extends StatelessWidget {
  const ShopRequestItemsList({super.key, required this.request});

  final ShopRequest request;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = request;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in r.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.available == null
                      ? PhosphorIconsRegular.circle
                      : item.available!
                          ? PhosphorIconsFill.checkCircle
                          : PhosphorIconsFill.xCircle,
                  size: 16,
                  color: item.available == null
                      ? scheme.onSurfaceVariant
                      : item.available!
                          ? AppColors.success
                          : AppColors.error,
                ),
                SizedBox(width: AppSizes.spaceXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        item.text,
                        style: TextStyle(
                          fontSize: AppSizes.fontLabel,
                          color: scheme.onSurface,
                          decoration: item.available == false ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (item.note != null)
                        CustomText(
                          item.note!,
                          style: TextStyle(fontSize: AppSizes.fontCaption, color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (item.available == true)
                  CustomText(
                    AppStrings.ShopRequests.priceEgp.trParams({'price': _money(item.priceEgp)}),
                    style: const TextStyle(fontSize: AppSizes.fontLabel, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        if (r.pricedPerItem) ...[
          const Divider(height: AppSizes.spaceMd),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.ShopRequests.itemsCount.trParams({
                    'available': '${r.availableCount}',
                    'total': '${r.items.length}',
                  }),
                  style: TextStyle(fontSize: AppSizes.fontCaption, color: scheme.onSurfaceVariant),
                ),
              ),
              CustomText(
                AppStrings.ShopRequests.total.trParams({'price': _money(r.quotedPriceEgp)}),
                style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Price the list item by item: in stock (price, optional note) or not.
class _ListPricingSheet extends StatefulWidget {
  const _ListPricingSheet({required this.request});

  final ShopRequest request;

  @override
  State<_ListPricingSheet> createState() => _ListPricingSheetState();
}

class _ListPricingSheetState extends State<_ListPricingSheet> {
  late final List<bool?> _available = [for (final i in widget.request.items) i.available];
  late final List<TextEditingController> _prices = [
    for (final i in widget.request.items)
      TextEditingController(text: i.available == true ? _money(i.priceEgp) : ''),
  ];
  late final List<TextEditingController> _notes = [
    for (final i in widget.request.items) TextEditingController(text: i.note ?? ''),
  ];
  late final _note = TextEditingController(text: widget.request.providerNote ?? '');
  String? _error;

  @override
  void dispose() {
    for (final c in [..._prices, ..._notes, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _price(int i) {
    final v = double.tryParse(toEnglishDigits(_prices[i].text.trim()).replaceAll(',', '.'));
    return v == null || v <= 0 ? null : v;
  }

  double get _total {
    var sum = 0.0;
    for (var i = 0; i < _available.length; i++) {
      if (_available[i] == true) sum += _price(i) ?? 0;
    }
    return sum;
  }

  void _submit() {
    if (_available.any((a) => a == null)) {
      setState(() => _error = AppStrings.ShopRequests.answerAll.tr);
      return;
    }
    if (!_available.contains(true)) {
      setState(() => _error = AppStrings.ShopRequests.needOne.tr);
      return;
    }
    for (var i = 0; i < _available.length; i++) {
      if (_available[i] == true && _price(i) == null) {
        setState(() => _error = AppStrings.ShopRequests.invalidPrice.tr);
        return;
      }
    }
    final items = widget.request.items;
    Navigator.pop(context, (
      [
        for (var i = 0; i < items.length; i++)
          {
            'id': items[i].id,
            'available': _available[i],
            if (_available[i] == true) 'priceEgp': _price(i),
            'note': _notes[i].text.trim(),
          },
      ],
      _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = widget.request.items;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSizes.screenPadding,
            child: CustomText(
              AppStrings.ShopRequests.priceList,
              style: const TextStyle(fontSize: AppSizes.fontTitle, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceMd),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const Divider(height: AppSizes.spaceLg),
              itemBuilder: (context, i) {
                if (i == items.length) {
                  return TextField(
                    controller: _note,
                    maxLength: 500,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(labelText: AppStrings.ShopRequests.noteLabel.tr),
                  );
                }
                final a = _available[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomText(
                      items[i].text,
                      style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppSizes.spaceSm),
                    SegmentedButton<bool>(
                      emptySelectionAllowed: true,
                      segments: [
                        ButtonSegment(
                          value: true,
                          icon: const Icon(PhosphorIconsRegular.checkCircle),
                          label: Text(AppStrings.ShopRequests.inStock.tr),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: const Icon(PhosphorIconsRegular.xCircle),
                          label: Text(AppStrings.ShopRequests.outOfStock.tr),
                        ),
                      ],
                      selected: {?a},
                      onSelectionChanged: (v) => setState(() {
                        _available[i] = v.isEmpty ? null : v.first;
                        _error = null;
                      }),
                    ),
                    if (a == true) ...[
                      SizedBox(height: AppSizes.spaceSm),
                      TextField(
                        controller: _prices[i],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          const EnglishDigitsInputFormatter(),
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(labelText: AppStrings.ShopRequests.priceLabel.tr, isDense: true),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                    ],
                    if (a != null) ...[
                      SizedBox(height: AppSizes.spaceSm),
                      TextField(
                        controller: _notes[i],
                        maxLength: 200,
                        decoration: InputDecoration(labelText: AppStrings.ShopRequests.itemNote.tr, isDense: true),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceSm, bottom: AppSizes.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    CustomText(
                      _error!,
                      style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: AppSizes.fontCaption),
                    ),
                    SizedBox(height: AppSizes.spaceXs),
                  ],
                  CustomText(
                    AppStrings.ShopRequests.total.trParams({'price': _money(_total)}),
                    style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: AppSizes.spaceSm),
                  AppFilledButton(text: AppStrings.ShopRequests.sendToCustomer, onTap: _submit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
