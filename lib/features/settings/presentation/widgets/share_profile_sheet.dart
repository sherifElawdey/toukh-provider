import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/menu/presentation/menu_public_url.dart';
import 'package:toukh_provider/features/menu/presentation/sheets/menu_qr_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Settings → "Share profile": the provider's page as a link or a QR code.
///
/// Both carry [publicProfileUrl]. With the Hav-it app installed the link
/// opens the store page in the app (Android App Links / iOS Universal
/// Links); otherwise the website shows the page with an "Order now" button
/// that opens the app or its store listing.
Future<void> showShareProfileSheet(
  BuildContext context, {
  required ProviderProfile profile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxWidth: double.infinity,
      minWidth: MediaQuery.of(context).size.width,
    ),
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
    ),
    builder: (_) => ShareProfileSheet(
      url: publicProfileUrl(profile),
      name: profile.name,
    ),
  );
}

enum _ShareMode { link, qr }

class ShareProfileSheet extends StatefulWidget {
  const ShareProfileSheet({required this.url, required this.name, super.key});

  final String url;
  final String name;

  @override
  State<ShareProfileSheet> createState() => _ShareProfileSheetState();
}

class _ShareProfileSheetState extends State<ShareProfileSheet> {
  static const _fileName = 'havit-profile-qr.png';

  _ShareMode _mode = _ShareMode.link;
  bool _saving = false;
  bool _sharingQr = false;
  Uint8List? _card;

  String get _message =>
      '${AppStrings.Settings.shareProfileMessage.trParams({'name': widget.name.trim()})}\n${widget.url}';

  Rect _origin() {
    final box = context.findRenderObject() as RenderBox?;
    return box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
  }

  void _snack(String key, AppSnackState state, IconData icon) {
    AppSnack.show(context, message: key.tr, state: state, icon: icon);
  }

  /// The shareable 4:5 card (name, QR, caption), drawn once.
  Future<Uint8List?> _qrCard() async {
    return _card ??= await menuQrCardPng(
      url: widget.url,
      name: widget.name,
      caption: AppStrings.Settings.shareProfileQrCaption.tr,
      textDirection: Directionality.of(context),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    _snack(
      AppStrings.Settings.shareProfileCopied,
      AppSnackState.success,
      ToukhIcons.copy,
    );
  }

  Future<void> _shareLink() async {
    await Share.share(_message, sharePositionOrigin: _origin());
  }

  Future<void> _saveQr() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _qrCard();
      if (bytes == null) throw StateError('qr');
      if (!await Gal.hasPermission() && !await Gal.requestPermission()) {
        throw StateError('permission');
      }
      await Gal.putImageBytes(bytes, name: 'havit-profile-qr');
      if (!mounted) return;
      _snack(
        AppStrings.Settings.shareProfileSaved,
        AppSnackState.success,
        ToukhIcons.qrCode,
      );
    } catch (_) {
      if (!mounted) return;
      _snack(
        AppStrings.Settings.shareProfileSaveFailed,
        AppSnackState.error,
        ToukhIcons.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareQr() async {
    if (_sharingQr) return;
    setState(() => _sharingQr = true);
    try {
      final bytes = await _qrCard();
      if (!mounted) return;
      if (bytes == null) {
        _snack(
          AppStrings.FirebaseErrors.tryAgain,
          AppSnackState.error,
          ToukhIcons.error,
        );
        return;
      }
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: _fileName)],
        text: _message,
        sharePositionOrigin: _origin(),
        fileNameOverrides: const [_fileName],
      );
    } finally {
      if (mounted) setState(() => _sharingQr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceMd),
          CustomText(
            AppStrings.Settings.shareProfile,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          CustomText(
            AppStrings.Settings.shareProfileHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          SegmentedButton<_ShareMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _ShareMode.link,
                icon: const Icon(PhosphorIconsRegular.link),
                label: CustomText(AppStrings.Settings.shareProfileLinkTab),
              ),
              ButtonSegment(
                value: _ShareMode.qr,
                icon: Icon(ToukhIcons.qrCode),
                label: CustomText(AppStrings.Settings.shareProfileQrTab),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _mode == _ShareMode.link ? _linkPane(theme) : _qrPane(theme),
          ),
        ],
      ),
    );
  }

  Widget _linkPane(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Column(
      key: const ValueKey('link'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            onTap: _copy,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceMd,
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.link,
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    // URLs read left to right in both languages.
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        widget.url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Icon(
                    ToukhIcons.copy,
                    size: 20,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceLg),
        AppFilledButton(
          text: AppStrings.Settings.shareProfileShareLink,
          icon: PhosphorIconsRegular.shareNetwork,
          onTap: _shareLink,
        ),
        const SizedBox(height: AppSizes.spaceSm),
        AppOutlinedButton(
          text: AppStrings.Settings.shareProfileCopy,
          icon: ToukhIcons.copy,
          onTap: _copy,
        ),
      ],
    );
  }

  Widget _qrPane(ThemeData theme) {
    return Column(
      key: const ValueKey('qr'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceMd),
              child: QrImageView(
                data: widget.url,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        CustomText(
          widget.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spaceLg),
        AppFilledButton(
          text: AppStrings.Settings.shareProfileSaveQr,
          icon: PhosphorIconsRegular.downloadSimple,
          status: _saving ? AppButtonStatus.loading : AppButtonStatus.enabled,
          onTap: _saveQr,
        ),
        const SizedBox(height: AppSizes.spaceSm),
        AppOutlinedButton(
          text: AppStrings.Settings.shareProfileShareQr,
          icon: PhosphorIconsRegular.shareNetwork,
          status: _sharingQr ? AppButtonStatus.loading : AppButtonStatus.enabled,
          onTap: _shareQr,
        ),
      ],
    );
  }
}
