import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/pre_service_question.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/shared/shared.dart';

/// Editable list of up to [PreServiceQuestion.maxCount] pre-service questions.
class PreServiceQuestionsEditor extends StatefulWidget {
  const PreServiceQuestionsEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final List<PreServiceQuestion> initial;
  final ValueChanged<List<PreServiceQuestion>> onChanged;

  @override
  State<PreServiceQuestionsEditor> createState() =>
      PreServiceQuestionsEditorState();
}

class PreServiceQuestionsEditorState extends State<PreServiceQuestionsEditor> {
  late List<_QuestionRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initial.isEmpty
        ? []
        : widget.initial
            .map(
              (q) => _QuestionRow(
                question: q,
                controller: TextEditingController(text: q.text),
              ),
            )
            .toList();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    super.dispose();
  }

  List<PreServiceQuestion> currentQuestions() {
    return [
      for (final r in _rows)
        PreServiceQuestion(
          id: r.question.id,
          text: r.controller.text,
        ),
    ];
  }

  /// Normalizes and notifies parent; returns normalized list.
  List<PreServiceQuestion> commit() {
    final normalized = PreServiceQuestion.normalize(currentQuestions());
    widget.onChanged(normalized);
    return normalized;
  }

  void _notify() {
    widget.onChanged(currentQuestions());
  }

  void _add() {
    if (_rows.length >= PreServiceQuestion.maxCount) return;
    setState(() {
      final q = PreServiceQuestion.blank();
      _rows.add(
        _QuestionRow(
          question: q,
          controller: TextEditingController(),
        ),
      );
    });
    _notify();
  }

  void _remove(int index) {
    setState(() {
      _rows[index].controller.dispose();
      _rows.removeAt(index);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canAdd = _rows.length < PreServiceQuestion.maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          AppStrings.Registration.preServiceQuestionsHint.tr,
          style: TextStyle(
            fontSize: AppSizes.fontBody,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        SizedBox(height: AppSizes.spaceMd),
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spaceMd),
            child: CustomText(
              AppStrings.Registration.preServiceQuestionsEmpty.tr,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        for (var i = 0; i < _rows.length; i++) ...[
          if (i > 0) SizedBox(height: AppSizes.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rows[i].controller,
                  maxLines: 2,
                  maxLength: 200,
                  onChanged: (_) => _notify(),
                  decoration: InputDecoration(
                    labelText:
                        '${AppStrings.Registration.preServiceQuestionLabel.tr} ${i + 1}',
                    counterText: '',
                  ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.Common.delete.tr,
                onPressed: () => _remove(i),
                icon: Icon(ToukhIcons.delete, color: scheme.error),
              ),
            ],
          ),
        ],
        SizedBox(height: AppSizes.spaceMd),
        AppOutlinedButton(
          text: canAdd
              ? AppStrings.Registration.preServiceQuestionsAdd.tr
              : AppStrings.Registration.preServiceQuestionsMax.tr,
          onTap: canAdd ? _add : null,
          icon: canAdd ? ToukhIcons.add : null,
        ),
      ],
    );
  }
}

class _QuestionRow {
  _QuestionRow({
    required this.question,
    required this.controller,
  });

  final PreServiceQuestion question;
  final TextEditingController controller;
}
