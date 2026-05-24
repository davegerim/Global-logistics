import 'package:flutter/widgets.dart';
import 'package:global_logistics_app/l10n/app_localizations.dart';

export 'package:global_logistics_app/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  String translateDynamic(String text) {
    if (text.isEmpty) return text;
    final isAm = l10n.localeName == 'am';

    switch (text) {
      case 'Flatbed': return isAm ? 'ፍላትቤድ (Flatbed)' : 'Flatbed';
      case 'Box truck': return isAm ? 'ቦክስ መኪና' : 'Box truck';
      case 'Curtain-side trailer': return isAm ? 'የጎን መጋረጃ ተጎታች' : 'Curtain-side trailer';
      case 'Reefer': return isAm ? 'ማቀዝቀዣ' : 'Reefer';
      case 'Any': return isAm ? 'ማንኛውም' : 'Any';
      case 'Textile': return isAm ? 'ጨርቃጨርቅ' : 'Textile';
      case 'Electronics': return isAm ? 'ኤሌክትሮኒክስ' : 'Electronics';
      case 'Perishables': return isAm ? 'የሚበላሹ እቃዎች' : 'Perishables';
      case 'General cargo': return isAm ? 'አጠቃላይ ጭነት' : 'General cargo';
      case 'FIXED': return isAm ? 'ቋሚ (FIXED)' : 'FIXED';
      case 'NEGOTIABLE': return isAm ? 'በድርድር (NEGOTIABLE)' : 'NEGOTIABLE';
      case 'Bank transfer': return isAm ? 'የባንክ ዝውውር' : 'Bank transfer';
      case 'Mobile money': return isAm ? 'የሞባይል ገንዘብ' : 'Mobile money';
      case 'USA': return isAm ? 'አሜሪካ' : 'USA';
      case 'Betel': return isAm ? 'ቤቴል' : 'Betel';
      case 'China': return isAm ? 'ቻይና' : 'China';
      case 'Addis': return isAm ? 'አዲስ' : 'Addis';
      case 'Brazil': return isAm ? 'ብራዚል' : 'Brazil';
      case 'Central Hub': return isAm ? 'ማዕከላዊ መናኸሪያ' : 'Central Hub';
      case 'Addis Ababa, Warehouse A': return isAm ? 'አዲስ አበባ፣ መጋዘን ሀ' : 'Addis Ababa, Warehouse A';
      case 'Normal': return isAm ? 'መደበኛ' : 'Normal';
      case 'in a timeline constraint': return isAm ? 'በጊዜ ገደብ ውስጥ' : 'in a timeline constraint';
      case 'nice': return isAm ? 'ጥሩ' : 'nice';
      case 'ETB': return isAm ? 'ብር' : 'ETB';
      case 'System message': return isAm ? 'የስርዓት መልእክት' : 'System message';
      case 'food': return isAm ? 'ምግብ' : 'food';
      case 'SELECTED': return isAm ? 'ተመርጧል' : 'SELECTED';
      case 'DRIVER_ASSIGNED': return isAm ? 'አሽከርካሪ ተመድቧል' : 'DRIVER_ASSIGNED';
      case 'PROFILE_ACTIVATED': return isAm ? 'መገለጫ ነቅቷል' : 'PROFILE_ACTIVATED';
      case 'You have been assigned for freight': return isAm ? 'ለጭነት ተመድበዋል' : 'You have been assigned for freight';
      case 'You have been offered for freight': return isAm ? 'ለጭነት ቅናሽ ቀርቦልዎታል' : 'You have been offered for freight';
      case 'Your Profile has been approved': return isAm ? 'መገለጫዎ ጸድቋል' : 'Your Profile has been approved';
      case 'Notification': return isAm ? 'ማሳወቂያ' : 'Notification';
      case 'You have a new update.': return isAm ? 'አዲስ ዝማኔ አለዎት።' : 'You have a new update.';
      // Notifications & Statuses
      case 'Booking Approved': return isAm ? 'ምዝገባ ጸድቋል' : 'Booking Approved';
      case 'New Offer': return isAm ? 'አዲስ ቅናሽ' : 'New Offer';
      case 'Freight Offloaded': return isAm ? 'ጭነት ወርዷል' : 'Freight Offloaded';
      case 'Freight Arrived': return isAm ? 'ጭነት ደርሷል' : 'Freight Arrived';
      case 'Freight In Transit': return isAm ? 'ጭነት በመጓጓዝ ላይ ነው' : 'Freight In Transit';
      case 'Freight Loaded': return isAm ? 'ጭነት ተጭኗል' : 'Freight Loaded';
      case 'BOOKING_APPROVED': return isAm ? 'ምዝገባ ጸድቋል' : 'BOOKING_APPROVED';
      case 'ADMIN_OFFER': return isAm ? 'የአስተዳዳሪ ቅናሽ' : 'ADMIN_OFFER';
      case 'OFFLOADED': return isAm ? 'ወርዷል' : 'OFFLOADED';
      case 'ARRIVED': return isAm ? 'ደርሷል' : 'ARRIVED';
      case 'IN_TRANSIT': return isAm ? 'በመጓጓዝ ላይ' : 'IN_TRANSIT';
      case 'LOADED': return isAm ? 'ተጭኗል' : 'LOADED';
      case 'ADMIN_APPROVED': return isAm ? 'በአስተዳዳሪ ጸድቋል' : 'ADMIN_APPROVED';
      case 'CONSIGNOR_ACCEPTED': return isAm ? 'በአስጫኝ ተቀባይነት አግኝቷል' : 'CONSIGNOR_ACCEPTED';
      case 'ADMIN_REQUESTED_CHANGE': return isAm ? 'አስተዳዳሪ ለውጥ ጠይቋል' : 'ADMIN_REQUESTED_CHANGE';
      case 'CREATED': return isAm ? 'ተፈጥሯል' : 'CREATED';
      case 'Shipment created': return isAm ? 'ጭነት ተፈጥሯል' : 'Shipment created';
      case 'Shipment approved': return isAm ? 'ጭነት ጸድቋል' : 'Shipment approved';
    }

    // Advanced fallbacks for dynamic content like "Booking food-16 approved"
    if (isAm) {
      if (text.startsWith('Booking ') && text.endsWith(' approved')) {
        final middle = text.substring(8, text.length - 9);
        return 'ምዝገባ $middle ጸድቋል';
      }
      if (text.startsWith('New Offer for Booking ')) {
        final middle = text.substring(22);
        return 'አዲስ ቅናሽ ለምዝገባ $middle';
      }
    }

    return text;
  }
}
