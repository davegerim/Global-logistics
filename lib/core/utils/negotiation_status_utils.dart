bool isNegotiationSettled(String? rawStatus) {
  final status = (rawStatus ?? '').trim().toUpperCase();
  if (status.isEmpty) return false;

  const settledKeywords = <String>[
    'ACCEPT',
    'APPROV',
    'ASSIGN',
    'SELECT',
    'AGREED',
    'SETTLED',
    'COMPLETED',
    'CLOSED',
    'REJECT',
    'DECLIN',
    'CANCEL',
    'EXPIRE',
  ];

  for (final keyword in settledKeywords) {
    if (status.contains(keyword)) return true;
  }
  return false;
}
