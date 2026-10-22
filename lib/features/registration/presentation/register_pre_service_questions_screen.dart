import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/pre_service_questions_editor.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
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

    return RegistrationStepScaffold(
      stage: RegistrationStage.business,
      icon: PhosphorIconsDuotone.chatsCircle,
      title: AppStrings.Registration.preServiceQuestionsTitle,
      subtitle: AppStrings.Registration.preServiceQuestionsSubtitle,
      onNext: _next,
      children: [
        PreServiceQuestionsEditor(
          key: _editorKey,
          initial: draft.preServiceQuestions,
          onChanged: (_) {},
        ),
      ],
    );
  }
}
