import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/auth_web_frame.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// The wizard has a different number of screens per business type, so the
/// progress shown to the user is four stable stages instead of a raw count.
enum RegistrationStage {
  business,
  account,
  place,
  review;

  int get number => index + 1;

  String get labelKey => switch (this) {
    RegistrationStage.business => AppStrings.Registration.stageBusiness,
    RegistrationStage.account => AppStrings.Registration.stageAccount,
    RegistrationStage.place => AppStrings.Registration.stagePlace,
    RegistrationStage.review => AppStrings.Registration.stageReview,
  };
}

/// Shared frame for every registration screen: back button, soft brand
/// background, stage progress, a large illustration with a plain-language
/// title + explanation, the screen's content, and a pinned Back / Next bar.
class RegistrationStepScaffold extends StatelessWidget {
  const RegistrationStepScaffold({
    super.key,
    required this.stage,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onNext,
    this.nextLabelKey,
    this.nextEnabled = true,
    this.onBack,
  });

  final RegistrationStage stage;
  final IconData icon;

  /// Translation keys (or already translated text).
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// When null the screen advances by tapping a choice, so no footer.
  final VoidCallback? onNext;
  final String? nextLabelKey;
  final bool nextEnabled;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final back = onBack ?? () => context.pop();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(ToukhIcons.back), onPressed: back),
      ),
      body: RegistrationBackground(
        child: SafeArea(
          bottom: onNext == null,
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceSm,
              bottom: AppSizes.space2xl,
            ),
            child: AuthWebCentered(
              maxWidth: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegistrationStageHeader(
                    stage: stage,
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                  ),
                  SizedBox(height: AppSizes.spaceXl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: onNext == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: AuthWebCentered(
                maxWidth: 640,
                child: RegistrationStepNavFooter(
                  onBack: back,
                  onNext: onNext!,
                  nextLabelKey: nextLabelKey,
                  nextEnabled: nextEnabled,
                ),
              ),
            ),
    );
  }
}

/// Four-segment progress, "Step x of 4 · stage", then the picture on the
/// side with the title above its explanation.
class RegistrationStageHeader extends StatelessWidget {
  const RegistrationStageHeader({
    super.key,
    required this.stage,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final RegistrationStage stage;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationStageProgress(stage: stage),
        SizedBox(height: AppSizes.spaceLg),
        // Picture sits on the side; title above its explanation next to it.
        Row(
          children: [
            RegistrationIllustration(icon: icon, size: 76),
            SizedBox(width: AppSizes.spaceBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceXs),
                  CustomText(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppSizes.fontLabel,
                      height: 1.45,
                      color: AppColors.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RegistrationStageProgress extends StatelessWidget {
  const RegistrationStageProgress({super.key, required this.stage});

  final RegistrationStage stage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final s in RegistrationStage.values) ...[
              if (s.index > 0) SizedBox(width: AppSizes.spaceXs),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: s.index <= stage.index
                        ? AppColors.secondColor
                        : AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: AppSizes.spaceSm),
        CustomText(
          AppStrings.Registration.stageOf.trParams({
            'step': '${stage.number}',
            'total': '${RegistrationStage.values.length}',
            'stage': stage.labelKey.tr,
          }),
          style: const TextStyle(
            fontSize: AppSizes.fontCaption,
            fontWeight: FontWeight.w700,
            color: AppColors.secondColor,
          ),
        ),
      ],
    );
  }
}

/// Large duotone picture in a tinted circle: the "image" of each step.
class RegistrationIllustration extends StatelessWidget {
  const RegistrationIllustration({
    super.key,
    required this.icon,
    this.size = 56,
    this.color = AppColors.secondColor,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.tint(context, color),
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        icon,
        size: size * 0.55,
        color: color,
        duotoneSecondaryOpacity: 0.35,
      ),
    );
  }
}

/// A titled block of the form with a one-line explanation of what to do.
class RegistrationSectionCard extends StatelessWidget {
  const RegistrationSectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceBase),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spaceBase),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RegistrationIllustration(icon: icon, size: 44),
                SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title,
                        style: TextStyle(
                          fontSize: AppSizes.fontBody,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (hint != null)
                        CustomText(
                          hint!,
                          style: TextStyle(
                            fontSize: AppSizes.fontCaption,
                            height: 1.4,
                            color: AppColors.muted(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceBase),
            child,
          ],
        ),
      ),
    );
  }
}

/// Soft brand-tinted page background.
class RegistrationBackground extends StatelessWidget {
  const RegistrationBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).scaffoldBackgroundColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(AppColors.tint(context, AppColors.appColor), base),
            base,
            base,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: child,
    );
  }
}
