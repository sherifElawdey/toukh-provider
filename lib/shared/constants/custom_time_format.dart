import 'package:intl/intl.dart';

String formatDateLabel(
    DateTime? date, {
      String locale = 'en',
    }) {
  if (date == null) return '—';

  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) {
    return 'Just now';
  }

  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    return minutes == 1
        ? '1 minute ago'
        : '$minutes minutes ago';
  }

  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return hours == 1
        ? '1 hour ago'
        : '$hours hours ago';
  }

  if (diff.inDays == 1) {
    return 'Yesterday';
  }

  if (diff.inDays == 2) {
    return '2 days ago';
  }

  if (diff.inDays < 30) {
    return DateFormat(
      'MMM d, HH:mm',
      locale,
    ).format(date);
  }

  if (diff.inDays < 365) {
    return DateFormat(
      'MMM d, HH:mm',
      locale,
    ).format(date);
  }

  return DateFormat(
    'MMM d, yyyy, HH:mm',
    locale,
  ).format(date);
}