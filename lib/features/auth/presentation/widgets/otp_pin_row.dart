import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OtpPinRow extends StatelessWidget {
  const OtpPinRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

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
              onChanged: onChanged,
              autofillHints: const [AutofillHints.oneTimeCode],
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
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            border: Border.all(
                              color: active
                                  ? AppColors.appColor
                                  : AppColors.secondColor.withValues(
                                      alpha: 0.22,
                                    ),
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: CustomText(
                              ch,
                              style: TextStyle(
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
