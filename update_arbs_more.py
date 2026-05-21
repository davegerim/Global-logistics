import json
import os
import re

new_en = {
  "welcomeBack": "Welcome back",
  "quickAction": "Quick action",
  "createBooking": "Create booking",
  "createBookingTitle": "Create Booking",
  "statusPrefix": "Status: ",
  "bookingUnlocksAfterAdminApproval": "Booking unlocks after admin approval",
  "noActiveShipmentsCreateBookingToGetStarted": "No active shipments. Create a booking to get started.",
  "viewAll": "View all",
  "newShipment": "New Shipment",
  "createNewShipmentOfferDesc": "Create a new shipment offer. Provide accurate logistics details to match with the best drivers.",
  "accountPendingAdminApprovalDesc": "Your account is pending admin approval. Booking is currently disabled.",
  "fromLabel": "From",
  "toLabel": "To",
  "placedPrefix": "Placed ",
  "estPrefix": "Est. ",
  "approvedLabel": "APPROVED",
  "verifiedWaitingAdminApproval": "VERIFIED (waiting admin approval)",
  "pendingAdminApproval": "PENDING ADMIN APPROVAL",
  "waitingAdminApproval": "WAITING ADMIN APPROVAL",
  "completedLabel": "COMPLETED",
  "cancelledLabel": "CANCELLED",
  "inTransitLabel": "IN TRANSIT",
  "arrivedLabel": "ARRIVED",
  "offloadedLabel": "OFFLOADED",
  "loadedLabel": "LOADED",
  "gdnGeneratedLabel": "GDN GENERATED",
  "grnGeneratedLabel": "GRN GENERATED",
  "consignorAcceptedLabel": "CONSIGNOR ACCEPTED",
  "driverAssignedLabel": "DRIVER ASSIGNED",
  "selectedLabel": "SELECTED",
  "consignorReceivedLabel": "CONSIGNOR RECEIVED",
  "adminApprovedLabel": "ADMIN APPROVED"
}

new_am = {
  "welcomeBack": "እንኳን ደህና መጡ",
  "quickAction": "ፈጣን እርምጃ",
  "createBooking": "ትዕዛዝ ፍጠር",
  "createBookingTitle": "ትዕዛዝ ፍጠር",
  "statusPrefix": "ሁኔታ: ",
  "bookingUnlocksAfterAdminApproval": "የአስተዳዳሪ ማረጋገጫ ሲገኝ ትዕዛዝ ይከፈታል",
  "noActiveShipmentsCreateBookingToGetStarted": "ምንም ገባሪ ጭነት የለም። ለመጀመር ትዕዛዝ ይፍጠሩ።",
  "viewAll": "ሁሉንም እይ",
  "newShipment": "አዲስ ጭነት",
  "createNewShipmentOfferDesc": "አዲስ የጭነት ቅናሽ ይፍጠሩ። ከአሽከርካሪዎች ጋር በትክክል ለማዛመድ ትክክለኛ የሎጂስቲክስ ዝርዝሮችን ያቅርቡ።",
  "accountPendingAdminApprovalDesc": "የእርስዎ መለያ የአስተዳዳሪ ማረጋገጫ በመጠባበቅ ላይ ነው። ትዕዛዝ መፍጠር በአሁኑ ጊዜ ተዘግቷል።",
  "fromLabel": "መነሻ",
  "toLabel": "መድረሻ",
  "placedPrefix": "የታዘዘው ",
  "estPrefix": "ግምት ",
  "approvedLabel": "ተቀባይነት አግኝቷል",
  "verifiedWaitingAdminApproval": "ተረጋግጧል (የአስተዳዳሪ ማረጋገጫ በመጠባበቅ ላይ)",
  "pendingAdminApproval": "የአስተዳዳሪ ማረጋገጫ በመጠባበቅ ላይ",
  "waitingAdminApproval": "የአስተዳዳሪ ማረጋገጫ በመጠባበቅ ላይ",
  "completedLabel": "ተጠናቋል",
  "cancelledLabel": "ተሰርዟል",
  "inTransitLabel": "በመንገድ ላይ",
  "arrivedLabel": "ደርሷል",
  "offloadedLabel": "ወርዷል",
  "loadedLabel": "ተጭኗል",
  "gdnGeneratedLabel": "GDN ተፈጥሯል",
  "grnGeneratedLabel": "GRN ተፈጥሯል",
  "consignorAcceptedLabel": "በአስጫኝ ተቀባይነት አግኝቷል",
  "driverAssignedLabel": "አሽከርካሪ ተመድቧል",
  "selectedLabel": "ተመርጧል",
  "consignorReceivedLabel": "በአስጫኝ ተቀብሏል",
  "adminApprovedLabel": "በአስተዳዳሪ ጸድቋል"
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
