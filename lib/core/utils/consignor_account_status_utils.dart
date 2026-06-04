import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/l10n/app_localizations.dart';

/// Admin account approval display rules (not shipment/offer status).
const _approvedAccountStatuses = {'APPROVED', 'ACTIVE'};

/// Consignor account approval display rules.
abstract final class ConsignorAccountStatusUtils {
  static const _approvedStatuses = _approvedAccountStatuses;

  /// Approved accounts must not show a status badge or status line in the UI.
  static bool shouldShowAccountStatus(AuthState auth) {
    if (auth.isConsignorApproved == true) return false;
    final status = auth.accountStatus?.trim().toUpperCase() ?? '';
    if (status.isEmpty) return false;
    return !_approvedStatuses.contains(status);
  }

  /// Label for non-approved consignor accounts; null when [shouldShowAccountStatus] is false.
  static String? displayLabel(AuthState auth, AppLocalizations l10n) {
    if (!shouldShowAccountStatus(auth)) return null;
    final rawStatus = (auth.accountStatus ?? '').trim();
    if (rawStatus.toUpperCase() == 'VERIFIED') {
      return l10n.verifiedWaitingAdminApproval;
    }
    if (rawStatus.isEmpty) return l10n.pendingAdminApproval;
    return '${rawStatus.toUpperCase()} (${l10n.waitingAdminApproval})';
  }

  /// Home hero card uses a slightly different waiting-approval suffix.
  static String? homeDisplayLabel(AuthState auth, AppLocalizations l10n) {
    if (!shouldShowAccountStatus(auth)) return null;
    final rawStatus = (auth.accountStatus ?? '').trim();
    if (rawStatus.toUpperCase() == 'VERIFIED') {
      return l10n.verifiedWaitingAdminApproval;
    }
    if (rawStatus.isEmpty) return l10n.pendingAdminApproval;
    return '${rawStatus.toUpperCase()} (waiting admin approval)';
  }
}

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
