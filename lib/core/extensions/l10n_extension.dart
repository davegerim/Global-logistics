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
    }

    return text;
  }
}
