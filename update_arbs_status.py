import json

new_en = {
  "bookingPrefix": "Booking #",
  "assignmentPrefix": "Assignment #",
  "statusPendingReview": "Pending review",
  "statusAwaitingDriver": "Awaiting driver",
  "statusDriverAssigned": "Driver assigned",
  "statusGdnIssued": "GDN issued",
  "statusLoading": "Loading",
  "statusInTransit": "In transit",
  "statusAtDestination": "At destination",
  "statusOffloading": "Offloading",
  "statusDelivered": "Delivered",
  "statusCompleted": "Completed",
  "statusCancelled": "Cancelled"
}

new_am = {
  "bookingPrefix": "ትዕዛዝ #",
  "assignmentPrefix": "ስራ #",
  "statusPendingReview": "ግምገማ በመጠባበቅ ላይ",
  "statusAwaitingDriver": "አሽከርካሪ በመጠባበቅ ላይ",
  "statusDriverAssigned": "አሽከርካሪ ተመድቧል",
  "statusGdnIssued": "GDN ተሰጥቷል",
  "statusLoading": "በመጫን ላይ",
  "statusInTransit": "በመንገድ ላይ",
  "statusAtDestination": "መድረሻ ላይ ነው",
  "statusOffloading": "በማራገፍ ላይ",
  "statusDelivered": "ደርሷል",
  "statusCompleted": "ተጠናቋል",
  "statusCancelled": "ተሰርዟል"
}

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_arb = json.load(f)

with open('lib/l10n/app_am.arb', 'r', encoding='utf-8') as f:
    am_arb = json.load(f)

for k, v in new_en.items():
    if k not in en_arb:
        en_arb[k] = v

for k, v in new_am.items():
    if k not in am_arb:
        am_arb[k] = v

with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
    json.dump(en_arb, f, indent=2, ensure_ascii=False)

with open('lib/l10n/app_am.arb', 'w', encoding='utf-8') as f:
    json.dump(am_arb, f, indent=2, ensure_ascii=False)

print("Updated arb files.")
