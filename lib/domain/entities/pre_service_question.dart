import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Provider-defined question asked before a home-service request.
class PreServiceQuestion extends Equatable {
  const PreServiceQuestion({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;

  static const maxCount = 3;

  PreServiceQuestion copyWith({String? id, String? text}) {
    return PreServiceQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
      };

  static PreServiceQuestion? fromMap(Map<String, dynamic> data) {
    final text = (data['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) return null;
    final id = (data['id'] as String?)?.trim();
    return PreServiceQuestion(
      id: (id != null && id.isNotEmpty) ? id : const Uuid().v4(),
      text: text,
    );
  }

  /// Parses Firestore `preServiceQuestions` (maps or legacy plain strings).
  static List<PreServiceQuestion> listFromFirestore(dynamic raw) {
    if (raw is! List) return const [];
    final out = <PreServiceQuestion>[];
    for (final e in raw) {
      if (out.length >= maxCount) break;
      if (e is String) {
        final t = e.trim();
        if (t.isEmpty) continue;
        out.add(PreServiceQuestion(id: const Uuid().v4(), text: t));
      } else if (e is Map) {
        final q = fromMap(Map<String, dynamic>.from(e));
        if (q != null) out.add(q);
      }
    }
    return List.unmodifiable(out);
  }

  /// Trims empty rows, caps at [maxCount], keeps stable ids when present.
  static List<PreServiceQuestion> normalize(List<PreServiceQuestion> input) {
    final out = <PreServiceQuestion>[];
    for (final q in input) {
      if (out.length >= maxCount) break;
      final t = q.text.trim();
      if (t.isEmpty) continue;
      final id = q.id.trim().isEmpty ? const Uuid().v4() : q.id.trim();
      out.add(PreServiceQuestion(id: id, text: t));
    }
    return List.unmodifiable(out);
  }

  static PreServiceQuestion blank() =>
      PreServiceQuestion(id: const Uuid().v4(), text: '');

  @override
  List<Object?> get props => [id, text];
}

/// Client answer snapshot stored on a home-service request.
class PreServiceAnswer extends Equatable {
  const PreServiceAnswer({
    required this.questionId,
    required this.question,
    required this.answer,
  });

  final String questionId;
  final String question;
  final String answer;

  Map<String, dynamic> toMap() => {
        'questionId': questionId,
        'question': question,
        'answer': answer,
      };

  static PreServiceAnswer? fromMap(Map<String, dynamic> data) {
    final question = (data['question'] as String?)?.trim() ?? '';
    final answer = (data['answer'] as String?)?.trim() ?? '';
    if (question.isEmpty && answer.isEmpty) return null;
    return PreServiceAnswer(
      questionId: (data['questionId'] as String?)?.trim() ?? '',
      question: question,
      answer: answer,
    );
  }

  static List<PreServiceAnswer> listFromFirestore(dynamic raw) {
    if (raw is! List) return const [];
    final out = <PreServiceAnswer>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final a = fromMap(Map<String, dynamic>.from(e));
      if (a != null) out.add(a);
    }
    return List.unmodifiable(out);
  }

  @override
  List<Object?> get props => [questionId, question, answer];
}
