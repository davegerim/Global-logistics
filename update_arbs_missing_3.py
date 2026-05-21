import json

new_en = {
  "welcomeBackTitle": "Welcome Back",
  "signInToManageShipments": "Sign in to manage shipments.",
  "forgotPasswordQuestion": "Forgot password?",
  "dontHaveAnAccount": "Don't have an account?",
  "createAccount": "Create Account",
  "forgotPasswordTitle": "Forgot password",
  "forgotPasswordSubtitle": "Enter your phone number to receive an OTP, then create a new password.",
  "phoneLabel": "Phone",
  "otpCodeLabel": "OTP code",
  "newPasswordLabel": "New password",
  "confirmNewPasswordLabel": "Confirm new password",
  "consignorRegistrationTitle": "Consignor Registration",
  "consignorRegStep1": "Step 1 of 3: Create your account to start managing shipments.",
  "assignedShipmentsTitle": "Assigned shipments",
  "assignedShipmentsDesc": "Accept offers from the Offers tab; admin assigns final routes.",
  "accountStatusPrefix": "Account status: ",
  "openOffersButton": "Open offers",
  "noActiveAssignmentsDesc": "No active assignments. Check new offers.",
  "updateProfileTitle": "Update profile",
  "updateProfileSubtitle": "Photo, licence, lanes",
  "vehicleDetailsTitle": "Vehicle Details",
  "driverLicenseTitle": "Driver License",
  "driverLicenseSubtitle": "Verification & expiry",
  "viewAdminPaymentRecords": "View admin payment records",
  "assignmentsTitle": "Assignments",
  "currentActiveRoutes": "Current active routes",
  "offersCenterTitle": "Offers Center",
  "bidsForNewShipments": "Bids for new shipments",
  "loadAndRouteAlerts": "Load & route alerts",
  "driverTermsAndPrivacy": "Driver terms & privacy",
  "notSpecified": "Not specified",
  "adminMessage": "Admin message",
  "driverMessage": "Driver message",
  "etbCurrency": "ETB",
  "roundsPrefix": "Rounds: ",
  "noAssignmentsYet": "No assignments yet.",
  "bottomNavHome": "Home",
  "bottomNavOffers": "Offers",
  "bottomNavProfile": "Profile"
}

new_am = {
  "welcomeBackTitle": "እንኳን ደህና መጡ",
  "signInToManageShipments": "ጭነቶችን ለማስተዳደር ይግቡ።",
  "forgotPasswordQuestion": "የይለፍ ቃል ረሱ?",
  "dontHaveAnAccount": "መለያ የለዎትም?",
  "createAccount": "መለያ ይፍጠሩ",
  "forgotPasswordTitle": "የይለፍ ቃል ረሱ",
  "forgotPasswordSubtitle": "OTP ለመቀበል ስልክ ቁጥርዎን ያስገቡ፣ ከዚያ አዲስ የይለፍ ቃል ይፍጠሩ።",
  "phoneLabel": "ስልክ",
  "otpCodeLabel": "የ OTP ኮድ",
  "newPasswordLabel": "አዲስ የይለፍ ቃል",
  "confirmNewPasswordLabel": "አዲስ የይለፍ ቃል ያረጋግጡ",
  "consignorRegistrationTitle": "የአስጫኝ ምዝገባ",
  "consignorRegStep1": "ደረጃ 1 ከ 3: ጭነቶችን ማስተዳደር ለመጀመር መለያዎን ይፍጠሩ።",
  "assignedShipmentsTitle": "የተመደቡ ጭነቶች",
  "assignedShipmentsDesc": "ከቅናሾች ትር ላይ ቅናሾችን ይቀበሉ፤ አስተዳዳሪው የመጨረሻ መንገዶችን ይመድባል።",
  "accountStatusPrefix": "የመለያ ሁኔታ: ",
  "openOffersButton": "ቅናሾችን ክፈት",
  "noActiveAssignmentsDesc": "ምንም ገባሪ ምደባዎች የሉም። አዳዲስ ቅናሾችን ያረጋግጡ።",
  "updateProfileTitle": "መገለጫ አዘምን",
  "updateProfileSubtitle": "ፎቶ፣ ፈቃድ፣ መስመሮች",
  "vehicleDetailsTitle": "የተሽከርካሪ ዝርዝሮች",
  "driverLicenseTitle": "የአሽከርካሪ ፈቃድ",
  "driverLicenseSubtitle": "ማረጋገጫ እና የሚያበቃበት ጊዜ",
  "viewAdminPaymentRecords": "የአስተዳዳሪ ክፍያ መዝገቦችን ይመልከቱ",
  "assignmentsTitle": "ምደባዎች",
  "currentActiveRoutes": "የአሁኑ ገባሪ መስመሮች",
  "offersCenterTitle": "የቅናሾች ማዕከል",
  "bidsForNewShipments": "ለአዳዲስ ጭነቶች ጨረታዎች",
  "loadAndRouteAlerts": "የጭነት እና የመንገድ ማሳወቂያዎች",
  "driverTermsAndPrivacy": "የአሽከርካሪ ውሎች እና ግላዊነት",
  "notSpecified": "አልተገለጸም",
  "adminMessage": "የአስተዳዳሪ መልእክት",
  "driverMessage": "የአሽከርካሪ መልእክት",
  "etbCurrency": "ብር",
  "roundsPrefix": "ዙሮች: ",
  "noAssignmentsYet": "እስካሁን ምንም ምደባዎች የሉም።",
  "bottomNavHome": "ዋና ገጽ",
  "bottomNavOffers": "ቅናሾች",
  "bottomNavProfile": "መገለጫ"
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