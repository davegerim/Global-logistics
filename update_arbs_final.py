import json

new_en = {
  "businessProfileUpdated": "Business profile updated",
  "profileUpdatedSuccessfully": "Profile updated successfully",
  "sendButton": "Send",
  "negotiationRoom": "Negotiation room",
  "openShipmentHistory": "Open shipment history"
}

new_am = {
  "businessProfileUpdated": "የንግድ መገለጫ ተዘምኗል",
  "profileUpdatedSuccessfully": "መገለጫ በተሳካ ሁኔታ ተዘምኗል",
  "sendButton": "ላክ",
  "negotiationRoom": "የድርድር ክፍል",
  "openShipmentHistory": "የጭነት ታሪክ ክፈት"
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