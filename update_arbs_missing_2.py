import json

new_en = {
  "shipmentTitle": "Shipment",
  "waitingForDriverAssignment": "Waiting for driver assignment. Once assigned, create GDN before driver can continue status updates.",
  "assignmentLabelCap": "ASSIGNMENT",
  "statusLabelCap": "STATUS",
  "viewGdnForm": "View GDN form",
  "openGdnForm": "Open GDN form",
  "grnCreatedAfterOffload": "GRN can be created after the driver confirms offloaded status.",
  "viewGrnForm": "View GRN form",
  "openGrnForm": "Open GRN form",
  "afterGrnRecordedConfirm": "After GRN is recorded, confirm final receipt here."
}

new_am = {
  "shipmentTitle": "የጭነት ዝርዝር",
  "waitingForDriverAssignment": "የአሽከርካሪ ምደባን በመጠበቅ ላይ። አንዴ ከተመደበ፣ አሽከርካሪው የሁኔታ ዝመናዎችን ከመቀጠሉ በፊት GDN ይፍጠሩ።",
  "assignmentLabelCap": "ምደባ",
  "statusLabelCap": "ሁኔታ",
  "viewGdnForm": "የ GDN ቅጽ ይመልከቱ",
  "openGdnForm": "የ GDN ቅጽ ክፈት",
  "grnCreatedAfterOffload": "አሽከርካሪው ማራገፉን ካረጋገጠ በኋላ GRN መፍጠር ይቻላል።",
  "viewGrnForm": "የ GRN ቅጽ ይመልከቱ",
  "openGrnForm": "የ GRN ቅጽ ክፈት",
  "afterGrnRecordedConfirm": "GRN ከተመዘገበ በኋላ፣ የመጨረሻውን ደረሰኝ እዚህ ያረጋግጡ።"
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