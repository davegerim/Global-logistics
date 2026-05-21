import json

new_en = {
  "rating": "Rating",
  "reviews": "Reviews",
  "accountDetails": "Account Details",
  "nameAndContact": "Name & contact",
  "businessProfile": "Business profile",
  "companyAndTradeLicence": "Company & trade licence",
  "security": "Security",
  "passwordAnd2fa": "Password & 2FA",
  "logisticsSection": "Logistics",
  "shipmentArchive": "Shipment Archive",
  "pastLoadHistory": "Past load history",
  "preferencesAndSupport": "Preferences & Support",
  "languageLabel": "Language",
  "pushAlerts": "Push alerts",
  "legal": "Legal",
  "privacyAndTerms": "Privacy & terms",
  "amharicLanguage": "Amharic",
  "englishUs": "English (US)",
  "confirmSelection": "Confirm Selection",
  "gdnGrnHub": "GDN & GRN Hub",
  "viewAllShippingDocumentsDesc": "View all shipping documents for the selected shipment assignment.",
  "selectShipment": "Select Shipment",
  "noGdnGrnForShipment": "This shipment has no active assignment, so no GDN/GRN is available yet.",
  "noGdnGrnRecordsReturned": "No GDN or GRN records were returned for this assignment.",
  "noTypeDocuments": "No {type} documents",
  "trySwitchingFilter": "Try switching the filter to see all available documents.",
  "documentNoPrefix": "No:",
  "allFilter": "ALL",
  "gdnFilter": "GDN",
  "grnFilter": "GRN",
  "goodsDetails": "Goods Details",
  "scanToVerifyAuthenticity": "Scan to verify document authenticity",
  "done": "Done",
  "downloadPdf": "Download PDF",
  "preparingPdf": "Preparing…",
  "licensePrefix": "License:",
  "idPrefix": "ID:",
  "platePrefix": "Plate:",
  "updateCompanyAndTradeLicence": "Update your company name and trade licence",
  "uploadTradeLicence": "Upload trade licence (image or PDF)",
  "tradeLicenceUploaded": "Trade licence uploaded.",
  "saveChanges": "Save Changes",
  "passwordResetEmailInstructions": "Please check your registered email for password reset instructions.",
  "sendResetLink": "Send Reset Link",
  "privacyPolicyText": "Your data is protected under our strict corporate privacy policies. We do not share shipping metrics or personal details with unauthorized third parties.\n\nFor full terms of service, please visit our website.",
  "acknowledge": "Acknowledge",
  "successfullySavedToDownloads": "Successfully saved to Downloads folder.\n{filename}"
}

new_am = {
  "rating": "ደረጃ",
  "reviews": "ግምገማዎች",
  "accountDetails": "የመለያ ዝርዝሮች",
  "nameAndContact": "ስም እና አድራሻ",
  "businessProfile": "የንግድ መገለጫ",
  "companyAndTradeLicence": "ኩባንያ እና የንግድ ፈቃድ",
  "security": "ደህንነት",
  "passwordAnd2fa": "የይለፍ ቃል እና 2FA",
  "logisticsSection": "ሎጂስቲክስ",
  "shipmentArchive": "የጭነት ማህደር",
  "pastLoadHistory": "የቀድሞ ጭነት ታሪክ",
  "preferencesAndSupport": "ምርጫዎች እና ድጋፍ",
  "languageLabel": "ቋንቋ",
  "pushAlerts": "የግፍ ማሳወቂያዎች",
  "legal": "ህጋዊ",
  "privacyAndTerms": "ግላዊነት እና ውሎች",
  "amharicLanguage": "አማርኛ",
  "englishUs": "እንግሊዝኛ (US)",
  "confirmSelection": "ምርጫ አረጋግጥ",
  "gdnGrnHub": "GDN እና GRN ማዕከል",
  "viewAllShippingDocumentsDesc": "ለተመረጠው የጭነት ምደባ ሁሉንም የማጓጓዣ ሰነዶች ይመልከቱ።",
  "selectShipment": "ጭነት ይምረጡ",
  "noGdnGrnForShipment": "ይህ ጭነት ንቁ ምደባ የለውም፣ ስለዚህ GDN/GRN አይገኝም።",
  "noGdnGrnRecordsReturned": "ለዚህ ምደባ ምንም GDN ወይም GRN መዝገብ አልተመለሰም።",
  "noTypeDocuments": "ምንም {type} ሰነዶች የሉም",
  "trySwitchingFilter": "ሁሉንም የሚገኙ ሰነዶችን ለማየት ማጣሪያውን ይቀይሩ።",
  "documentNoPrefix": "ቁጥር:",
  "allFilter": "ሁሉም",
  "gdnFilter": "GDN",
  "grnFilter": "GRN",
  "goodsDetails": "የእቃ ዝርዝሮች",
  "scanToVerifyAuthenticity": "ሰነዱን ለማረጋገጥ ይቃኙ",
  "done": "ተጠናቋል",
  "downloadPdf": "PDF አውርድ",
  "preparingPdf": "በማዘጋጀት ላይ…",
  "licensePrefix": "ፈቃድ:",
  "idPrefix": "መለያ:",
  "platePrefix": "ታርጋ:",
  "updateCompanyAndTradeLicence": "የኩባንያዎን ስም እና የንግድ ፈቃድ ያዘምኑ",
  "uploadTradeLicence": "የንግድ ፈቃድ ይስቀሉ (ምስል ወይም PDF)",
  "tradeLicenceUploaded": "የንግድ ፈቃድ ተስቀልቷል።",
  "saveChanges": "ለውጦችን አስቀምጥ",
  "passwordResetEmailInstructions": "ለይለፍ ቃል ዳግም ማስጀመሪያ መመሪያዎች ለተመዘገበው ኢሜይልዎ ይመልከቱ።",
  "sendResetLink": "ዳግም ማስጀመሪያ ሊንክ ላክ",
  "privacyPolicyText": "የእርስዎ መረጃ በጥብቅ የድርጅት ግላዊነት ፖሊሲዎች በጥበቃ ስር ነው። የማጓጓዣ መለኪያዎችን ወይም የግል ዝርዝሮችን ለያልተፈቀዱ ሶስተኞች አንጋራም።\n\nሙሉ የአገልግሎት ውሎችን ለማንበብ ድረ-ገጻችንን ይጎብኙ።",
  "acknowledge": "ተቀበል",
  "successfullySavedToDownloads": "በተሳካ ሁኔታ ወደ Downloads አቅራቢያ ተቀምጧል።\n{filename}"
}

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_arb = json.load(f)

with open('lib/l10n/app_am.arb', 'r', encoding='utf-8') as f:
    am_arb = json.load(f)

# Add placeholder metadata for parameterized strings
en_arb["@noTypeDocuments"] = {
    "placeholders": {"type": {"type": "String"}}
}
en_arb["@successfullySavedToDownloads"] = {
    "placeholders": {"filename": {"type": "String"}}
}
am_arb["@noTypeDocuments"] = {
    "placeholders": {"type": {"type": "String"}}
}
am_arb["@successfullySavedToDownloads"] = {
    "placeholders": {"filename": {"type": "String"}}
}

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
