/// Shared "initials" logic for avatar-style widgets (person tiles, greeting
/// headers) so it isn't duplicated per widget.
String initialsFor(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(RegExp(r'\s+'));
  final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
  return (first + last).toUpperCase();
}

const _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a date as "14 Sep 2026" without pulling in the intl package.
String formatShortDate(DateTime date) {
  return '${date.day} ${_monthAbbreviations[date.month - 1]} ${date.year}';
}

/// "Just now" / "5m ago" / "3h ago" / "Yesterday" / falls back to
/// formatShortDate beyond a week — used for notification timestamps.
String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatShortDate(date);
}
