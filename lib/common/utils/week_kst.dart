DateTime _parseYmd(String ymd) {
  final parts = ymd.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  return DateTime(y, m, d);
}

String _fmtYmd(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Returns monday(YYYY-MM-DD) of the week that includes [ymd] (KST date string).
String mondayOfYmd(String ymd) {
  final dt = _parseYmd(ymd);
  // DateTime.weekday: 1(Mon) .. 7(Sun)
  final diff = dt.weekday - DateTime.monday;
  final monday = dt.subtract(Duration(days: diff));
  return _fmtYmd(monday);
}

String addDaysYmd(String ymd, int days) => _fmtYmd(_parseYmd(ymd).add(Duration(days: days)));

String addWeeksYmd(String ymd, int weeks) => addDaysYmd(ymd, weeks * 7);

