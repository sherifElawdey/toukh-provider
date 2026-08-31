import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/pre_service_questions_editor.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterPreServiceQuestionsScreen extends StatefulWidget {
  const RegisterPreServiceQuestionsScreen({super.key});

  @override
  State<RegisterPreServiceQuestionsScreen> createState() =>
      _RegisterPreServiceQuestionsScreenState();
}

class _RegisterPreServiceQuestionsScreenState
    extends State<RegisterPreServiceQuestionsScreen> {
  final _editorKey = GlobalKey<PreServiceQuestionsEditorState>();

  void _next() {
    final editor = _editorKey.currentState;
    final questions = editor?.commit() ?? const [];
    context.read<RegistrationCubit>().setPreServiceQuestions(questions);
    context.push(AppRoutes.registerCredentials);
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.preServiceQuestionsTitle),
      ),
      body: SingleChildScrollView(
        padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.space3xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ToukhServiceLogo(
                size: 56,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            SizedBox(height: AppSizes.spaceMd),
            CustomText(
              AppStrings.Registration.preServiceQuestionsSubtitle.tr,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: AppSizes.spaceLg),
            PreServiceQuestionsEditor(
              key: _editorKey,
              initial: draft.preServiceQuestions,
              onChanged: (_) {},
            ),
            SizedBox(height: AppSizes.spaceXl),
            RegistrationStepNavFooter(
              useSafeArea: false,
              padding: EdgeInsets.zero,
              onBack: () => context.pop(),
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}
