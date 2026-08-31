import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/pre_service_questions_editor.dart';

class ReviewEditPreServiceQuestionsBody extends StatefulWidget {
  const ReviewEditPreServiceQuestionsBody({super.key});

  @override
  State<ReviewEditPreServiceQuestionsBody> createState() =>
      ReviewEditPreServiceQuestionsBodyState();
}

class ReviewEditPreServiceQuestionsBodyState
    extends State<ReviewEditPreServiceQuestionsBody> {
  final _editorKey = GlobalKey<PreServiceQuestionsEditorState>();

  bool save() {
    final questions = _editorKey.currentState?.commit() ?? const [];
    context.read<RegistrationCubit>().setPreServiceQuestions(questions);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.read<RegistrationCubit>().state;
    return PreServiceQuestionsEditor(
      key: _editorKey,
      initial: draft.preServiceQuestions,
      onChanged: (_) {},
    );
  }
}
