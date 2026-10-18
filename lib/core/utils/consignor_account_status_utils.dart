import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/l10n/app_localizations.dart';

/// Admin account approval display rules (not shipment/offer status).
const _approvedAccountStatuses = {'APPROVED', 'ACTIVE'};

/// Driver account approval display rules.
abstract final class DriverAccountStatusUtils {
  static bool shouldShowAccountStatus(AuthState auth) {
    if (auth.canViewDriverOffers) return false;
    final status = auth.accountStatus?.trim().toUpperCase() ?? '';
    if (status.isNotEmpty && _approvedAccountStatuses.contains(status)) {
      return false;
    }
    return true;
  }

  static String? displayLabel(AuthState auth, AppLocalizations l10n) {
    if (!shouldShowAccountStatus(auth)) return null;
    final rawStatus = (auth.accountStatus ?? '').trim();
    final upper = rawStatus.toUpperCase();
    if (upper == 'VERIFIED') return l10n.verifiedWaitingAdminApproval;
    if (rawStatus.isEmpty || upper == 'UNKNOWN') return l10n.pendingApproval;
    return '$upper (${l10n.waitingAdminApproval})';
  }
}
