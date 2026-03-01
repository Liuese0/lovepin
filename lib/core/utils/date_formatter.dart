import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Returns a human-friendly relative time string.
  ///
  /// - Under 60 seconds: "just now"
  /// - Under 60 minutes: "5m ago"
  /// - Under 24 hours: "2h ago"
  /// - Yesterday: "yesterday"
  /// - Otherwise: "Feb 28" (or "Feb 28, 2025" if different year)
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return formatDate(dateTime);
    }

    if (difference.inSeconds < 60) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == yesterday) {
      return 'yesterday';
    }

    if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    }

    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Formats a time as "3:42 PM".
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats a date as "Feb 28, 2026".
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Formats a full date and time as "Feb 28, 2026 at 3:42 PM".
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  /// Formats a date for message group headers.
  ///
  /// - Today: "Today"
  /// - Yesterday: "Yesterday"
  /// - This year: "Feb 28"
  /// - Other years: "Feb 28, 2025"
  static String formatMessageGroupHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return 'Today';
    }

    if (dateOnly == yesterday) {
      return 'Yesterday';
    }

    if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    }

    return DateFormat('MMM d, y').format(dateTime);
  }
}
