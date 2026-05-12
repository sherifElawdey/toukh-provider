import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key, required this.existingTitles});

  final List<String> existingTitles;

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    if (t.isEmpty) {
      setState(() => _error = AppStrings.Registration.categoryName.tr);
      return;
    }
    if (widget.existingTitles
        .any((c) => c.toLowerCase() == t.toLowerCase())) {
      setState(() => _error = AppStrings.Registration.duplicateCategory.tr);
      return;
    }
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                CustomText(
                  AppStrings.Registration.addCategory,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                AppTextField(
                  controller: _controller,
                  labelText: AppStrings.Registration.categoryName,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  errorText: _error,
                ),
                SizedBox(height: AppSizes.spaceMd),
                FilledButton(
                  onPressed: _submit,
                  child: CustomText(AppStrings.Common.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
