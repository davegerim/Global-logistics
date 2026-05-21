import json

new_en = {
  "shipmentProgress": "Shipment Progress",
  "weightLabelCap": "WEIGHT",
  "volumeLabelCap": "VOLUME",
  "vehicleLabelCap": "VEHICLE",
  "createdLabelCap": "CREATED",
  "priceTypeLabelCap": "PRICE TYPE",
  "priceLabelCap": "PRICE",
  "routeMap": "Route Map",
  "pickupLocationLabel": "PICKUP LOCATION",
  "deliveryDestinationLabel": "DELIVERY DESTINATION",
  "placedOnLabel": "PLACED ON",
  "estArrivalLabel": "EST. ARRIVAL",
  "gdnControlOnceAdminSelects": "GDN control becomes available once admin selects and assigns a driver.",
  "grnControlAfterDriverAssignment": "GRN control becomes available after driver assignment is active.",
  "handoverConfirmed": "Handover confirmed",
  "feedbackToDriver": "Feedback to driver",
  "shareDeliveryNotesOrRate": "Share delivery notes or rate your driver after handover is confirmed.",
  "receiverNameRequired": "Receiver name, quantity and condition note are required.",
  "grnExistsAndCompleted": "GRN exists and consignor confirmation is completed.",
  "grnAlreadyCreatedConfirm": "GRN already created. Confirm final receipt on the shipment screen.",
  "fillFormToCreateGrnAfterOffload": "Fill the form to create GRN after offloading.",
  "grnCreatedSuccessConfirm": "GRN created successfully. Confirm final receipt on the shipment screen.",
  "receiverNameStar": "Receiver name *",
  "receivedQuantityStar": "Received quantity *",
  "receivedWeight": "Received weight",
  "receivedVolume": "Received volume",
  "damageQuantity": "Damage quantity",
  "shortageQuantity": "Shortage quantity",
  "conditionNoteStar": "Condition note *",
  "receivedAt": "Received at",
  "grnAlreadyCreated": "GRN already created",
  "gdnAlreadyGeneratedLocked": "GDN already generated and locked.",
  "fillFormToCreateGdn": "Fill the form to create GDN.",
  "gdnCreatedSuccessEditingDisabled": "GDN created successfully. Editing is disabled.",
  "issuerNameStar": "Issuer name *",
  "consigneeNameStar": "Consignee name *",
  "consigneeContactStar": "Consignee contact *",
  "quantityStar": "Quantity *",
  "packaging": "Packaging",
  "remarks": "Remarks",
  "gdnAlreadyCreated": "GDN already created",
  "trackingLabel": "Tracking",
  "trackingPoints": "Tracking points:",
  "latestLocationPrefix": "Latest: lat ",
  "lonPrefix": " lon ",
  "atPrefix": " @ ",
  "noOfferRoundsYet": "No offer rounds yet.",
  "latestPrice": "Latest price:",
  "typeLabel": "Type"
}

new_am = {
  "shipmentProgress": "የጭነት ሂደት",
  "weightLabelCap": "ክብደት",
  "volumeLabelCap": "መጠን",
  "vehicleLabelCap": "ተሽከርካሪ",
  "createdLabelCap": "ተፈጥሯል",
  "priceTypeLabelCap": "የዋጋ አይነት",
  "priceLabelCap": "ዋጋ",
  "routeMap": "የመንገድ ካርታ",
  "pickupLocationLabel": "የመጫኛ ቦታ",
  "deliveryDestinationLabel": "የማድረሻ ቦታ",
  "placedOnLabel": "የታዘዘበት",
  "estArrivalLabel": "የመድረሻ ግምት",
  "gdnControlOnceAdminSelects": "አስተዳዳሪው አሽከርካሪ ሲመርጥ እና ሲመድብ የ GDN ቁጥጥር ይገኛል።",
  "grnControlAfterDriverAssignment": "የአሽከርካሪ ምደባ ንቁ ከሆነ በኋላ የ GRN ቁጥጥር ይገኛል።",
  "handoverConfirmed": "ርክክብ ተረጋግጧል",
  "feedbackToDriver": "ለአሽከርካሪ አስተያየት",
  "shareDeliveryNotesOrRate": "ርክክብ ከተረጋገጠ በኋላ የማድረሻ ማስታወሻዎችን ያካፍሉ ወይም አሽከርካሪዎን ደረጃ ይስጡ።",
  "receiverNameRequired": "የተቀባዩ ስም፣ ብዛት እና የሁኔታ ማስታወሻ ያስፈልጋሉ።",
  "grnExistsAndCompleted": "GRN አለ እና የአስጫኙ ማረጋገጫ ተጠናቋል።",
  "grnAlreadyCreatedConfirm": "GRN አስቀድሞ ተፈጥሯል። በማጓጓዣ ማያ ገጽ ላይ የመጨረሻውን ደረሰኝ ያረጋግጡ።",
  "fillFormToCreateGrnAfterOffload": "ካራገፉ በኋላ GRN ለመፍጠር ቅጹን ይሙሉ::",
  "grnCreatedSuccessConfirm": "GRN በተሳካ ሁኔታ ተፈጥሯል። በማጓጓዣ ማያ ገጽ ላይ የመጨረሻውን ደረሰኝ ያረጋግጡ።",
  "receiverNameStar": "የተቀባይ ስም *",
  "receivedQuantityStar": "የተቀበሉት ብዛት *",
  "receivedWeight": "የተቀበሉት ክብደት",
  "receivedVolume": "የተቀበሉት መጠን",
  "damageQuantity": "የተጎዳው ብዛት",
  "shortageQuantity": "የጎደለው ብዛት",
  "conditionNoteStar": "የሁኔታ ማስታወሻ *",
  "receivedAt": "የተቀበሉበት ጊዜ",
  "grnAlreadyCreated": "GRN አስቀድሞ ተፈጥሯል",
  "gdnAlreadyGeneratedLocked": "GDN አስቀድሞ ተፈጥሯል እና ተቆልፏል።",
  "fillFormToCreateGdn": "GDN ለመፍጠር ቅጹን ይሙሉ::",
  "gdnCreatedSuccessEditingDisabled": "GDN በተሳካ ሁኔታ ተፈጥሯል። ማስተካከል ተሰናክሏል።",
  "issuerNameStar": "የሰጪው ስም *",
  "consigneeNameStar": "የተቀባይ ስም *",
  "consigneeContactStar": "የተቀባይ ስልክ ቁጥር *",
  "quantityStar": "ብዛት *",
  "packaging": "ማሸጊያ",
  "remarks": "አስተያየቶች",
  "gdnAlreadyCreated": "GDN አስቀድሞ ተፈጥሯል",
  "trackingLabel": "ክትትል",
  "trackingPoints": "የክትትል ነጥቦች:",
  "latestLocationPrefix": "የቅርብ ጊዜ: ኬክሮስ ",
  "lonPrefix": " ኬንትሮስ ",
  "atPrefix": " በ ",
  "noOfferRoundsYet": "እስካሁን ምንም የዋጋ ድርድር የለም።",
  "latestPrice": "የቅርብ ጊዜ ዋጋ:",
  "typeLabel": "አይነት"
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
