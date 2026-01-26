class AdminMenuDay {
  final String id; // YYYY-MM-DD
  final String dateLabel; // MM.DD
  final String weekdayLabel; // 월/화/...
  final List<String> items;
  final bool isPast;
  final bool isToday;

  AdminMenuDay({
    required this.id,
    required this.dateLabel,
    required this.weekdayLabel,
    required this.items,
    required this.isPast,
    required this.isToday,
  });
}

