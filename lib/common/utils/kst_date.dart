String kstTodayYmd() {
  final nowUtc = DateTime.now().toUtc();
  final kst = nowUtc.add(const Duration(hours: 9));
  final y = kst.year.toString().padLeft(4, '0');
  final m = kst.month.toString().padLeft(2, '0');
  final d = kst.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

