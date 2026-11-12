import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/core/media/safe_image_pick.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Pharmacy photo gallery. Any photo can be marked as an offer; customers
/// see offers on the pharmacy profile with a "Request this offer" button.
class PharmacyGalleryScreen extends StatelessWidget {
  const PharmacyGalleryScreen({super.key});

  static const int kMaxPhotos = 20;

  Future<void> _add(BuildContext context, String providerId) async {
    final file = await pickImageFromSource(context, ImageSource.gallery);
    if (file == null || !context.mounted) return;
    try {
      await context.withAppLoading(
        () => getIt<ProviderGalleryRepository>().addImages(providerId, [file]),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Settings.pharmacyGalleryUploadFailed.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth is! Authenticated) return const SizedBox.shrink();
    final providerId = auth.profile.uid;
    final scheme = Theme.of(context).colorScheme;
    final repo = getIt<ProviderGalleryRepository>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Settings.pharmacyGalleryTitle),
      ),
      body: StreamBuilder<List<ProviderGalleryItem>>(
        stream: repo.watchGallery(providerId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          final offers = items.where((i) => i.isOffer).length;
          return ListView(
            padding: AppSizes.screenPadding.copyWith(bottom: 96),
            children: [
              CustomText(
                AppStrings.Settings.pharmacyGalleryHint,
                style: TextStyle(
                  fontSize: AppSizes.fontBody,
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              CustomText(
                AppStrings.Settings.pharmacyGalleryCount.trParams({
                  'count': '${items.length}',
                  'max': '$kMaxPhotos',
                  'offers': '$offers',
                }),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSizes.spaceMd),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(ToukhIcons.gallery, size: 48, color: scheme.outline),
                      const SizedBox(height: AppSizes.spaceSm),
                      CustomText(
                        AppStrings.Settings.pharmacyGalleryEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.spaceSm,
                    mainAxisSpacing: AppSizes.spaceSm,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _GalleryTile(
                    item: items[i],
                    onTap: () => _showEditSheet(context, providerId, items[i]),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<ProviderGalleryItem>>(
        stream: repo.watchGallery(providerId),
        builder: (context, snap) {
          final full = (snap.data?.length ?? 0) >= kMaxPhotos;
          if (full) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _add(context, providerId),
            icon: Icon(ToukhIcons.add),
            label: CustomText(AppStrings.Settings.pharmacyGalleryAdd),
          );
        },
      ),
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    String providerId,
    ProviderGalleryItem item,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GalleryItemSheet(providerId: providerId, item: item),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.item, required this.onTap});

  final ProviderGalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final caption = item.caption ?? '';
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            HavitNetworkImage(imageUrl: item.url, fit: BoxFit.cover),
            if (item.isOffer)
              PositionedDirectional(
                top: 8,
                start: 8,
                child: _OfferBadge(color: scheme.primary),
              ),
            if (caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: CustomText(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              top: 6,
              end: 6,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black45,
                child: Icon(ToukhIcons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsFill.tag, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          CustomText(
            AppStrings.Settings.pharmacyGalleryOfferBadge,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryItemSheet extends StatefulWidget {
  const _GalleryItemSheet({required this.providerId, required this.item});

  final String providerId;
  final ProviderGalleryItem item;

  @override
  State<_GalleryItemSheet> createState() => _GalleryItemSheetState();
}

class _GalleryItemSheetState extends State<_GalleryItemSheet> {
  late bool _isOffer = widget.item.isOffer;
  late final _caption = TextEditingController(text: widget.item.caption ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await getIt<ProviderGalleryRepository>().updateImage(
        providerId: widget.providerId,
        itemId: widget.item.id,
        isOffer: _isOffer,
        caption: _caption.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnack.show(
        context,
        message: AppStrings.Common.success.tr,
        state: AppSnackState.success,
        icon: ToukhIcons.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.show(
        context,
        message: AppStrings.Settings.pharmacyGallerySaveFailed.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Settings.pharmacyGalleryDeleteTitle),
        content: CustomText(AppStrings.Settings.pharmacyGalleryDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: CustomText(AppStrings.Common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: CustomText(AppStrings.Settings.pharmacyGalleryDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await getIt<ProviderGalleryRepository>().deleteImage(
        providerId: widget.providerId,
        item: widget.item,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.show(
        context,
        message: AppStrings.Settings.pharmacyGallerySaveFailed.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.spaceLg,
        0,
        AppSizes.spaceLg,
        MediaQuery.viewInsetsOf(context).bottom + AppSizes.spaceLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: HavitNetworkImage(
                  imageUrl: widget.item.url,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isOffer,
              onChanged: _busy ? null : (v) => setState(() => _isOffer = v),
              title: CustomText(
                AppStrings.Settings.pharmacyGalleryMarkOffer,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: CustomText(
                AppStrings.Settings.pharmacyGalleryMarkOfferHint,
                style: t.bodySmall,
              ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            TextField(
              controller: _caption,
              enabled: !_busy,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: AppStrings.Settings.pharmacyGalleryCaption.tr,
                hintText: AppStrings.Settings.pharmacyGalleryCaptionHint.tr,
              ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            AppFilledButton(
              text: AppStrings.Common.save,
              onTap: _busy ? null : _save,
            ),
            const SizedBox(height: AppSizes.spaceSm),
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: Icon(ToukhIcons.delete),
              label: CustomText(AppStrings.Settings.pharmacyGalleryDelete),
            ),
          ],
        ),
      ),
    );
  }
}
