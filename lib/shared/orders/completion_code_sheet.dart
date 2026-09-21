import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_sizes.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_text.dart';

/// Opens a modal bottom sheet that prompts the provider / driver to enter the
/// customer's 6-digit completion code. Returns the entered code string when
/// confirmed, or `null` when dismissed.
Future<String?> showCompletionCodeSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _CompletionCodeSheet(),
  );
}

class _CompletionCodeSheet extends StatefulWidget {
  const _CompletionCodeSheet();

  @override
  State<_CompletionCodeSheet> createState() => _CompletionCodeSheetState();
}

class _CompletionCodeSheetState extends State<_CompletionCodeSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.spaceXl,
        right: AppSizes.spaceXl,
        top: AppSizes.spaceMd,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            'Enter customer code',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: AppFonts.family,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceSm),
          Text(
            'Ask the customer for the 6-digit code shown on their order screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: AppSizes.fontBody,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSizes.spaceXl),
          _PinRow(controller: _controller, focusNode: _focusNode),
          const SizedBox(height: AppSizes.spaceXl),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final ready = value.text.length == 6;
              return AppFilledButton(
                text: 'Confirm',
                onTap: ready
                    ? () => Navigator.of(context).pop(_controller.text)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Six individual digit boxes backed by a single hidden [TextField].
class _PinRow extends StatelessWidget {
  const _PinRow({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: AppColors.inputTextHidden,
                height: 1.2,
                letterSpacing: 18,
              ),
              cursorColor: AppColors.appColor,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              return IgnorePointer(
                child: Row(
                  children: List.generate(6, (i) {
                    final has = i < controller.text.length;
                    final ch = has ? controller.text[i] : '';
                    final active =
                        focusNode.hasFocus && i == controller.text.length;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill(context),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(
                              color: active
                                  ? AppColors.appColor
                                  : AppColors.secondColor
                                      .withValues(alpha: 0.22),
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: CustomText(
                              ch,
                              style: TextStyle(
                                fontFamily: AppFonts.family,
                                fontSize: AppSizes.fontHeadline,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
