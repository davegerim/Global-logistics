import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/utils/consignor_account_status_utils.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/payments_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/services/presigned_storage_service.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';
import 'package:global_logistics_app/data/utils/role_profile_utils.dart';
import 'package:global_logistics_app/shared/widgets/app_language_picker_sheet.dart';
import 'package:global_logistics_app/shared/widgets/presigned_url_upload_row.dart';

class ConsignorProfileScreen extends ConsumerStatefulWidget {
  const ConsignorProfileScreen({super.key});

  @override
  ConsumerState<ConsignorProfileScreen> createState() =>
      _ConsignorProfileScreenState();
}

class _ConsignorProfileScreenState
    extends ConsumerState<ConsignorProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _consignorProfile;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = ref.read(backendApiProvider);
    try {
      final identity = await api.identityGet();
      if (mounted) setState(() => _profile = identity);
    } catch (_) {}
    try {
      final consignor = await api.consignorsProfile();
      if (mounted) setState(() => _consignorProfile = consignor);
    } catch (_) {}
  }

  Future<void> _showPremiumSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    String? actionLabel,
    Future<void> Function()? onAction,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(top: MediaQuery.paddingOf(ctx).top + 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom:
              MediaQuery.viewInsetsOf(ctx).bottom +
              MediaQuery.paddingOf(ctx).bottom +
              32,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ...children,
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await onAction!();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    TextInputType? type,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: readOnly ? AppColors.surfaceHighlight.withValues(alpha: 0.5) : AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Future<void> _editBusinessProfile() async {
    final businessName = TextEditingController(
      text:
          RoleProfileUtils.stringField(_consignorProfile, 'businessName') ?? '',
    );
    final tradeLicence = TextEditingController(
      text:
          RoleProfileUtils.stringField(_consignorProfile, 'tradeLicence') ?? '',
    );
    Object? saveError;
    var saved = false;
    await _showPremiumSheet(
      title: context.l10n.businessProfile,
      subtitle: context.l10n.updateCompanyAndTradeLicence,
      icon: Icons.business_rounded,
      children: [
        _buildInput(businessName, context.l10n.businessNameOptional),
        PresignedUrlUploadRow(
          urlController: tradeLicence,
          folder: S3Folder.profile,
          buttonLabel: context.l10n.uploadTradeLicence,
          successMessage: context.l10n.tradeLicenceUploaded,
        ),
        PresignedUploadAttachedHint(
          controller: tradeLicence,
          message: context.l10n.tradeLicenceAttached,
        ),
      ],
      actionLabel: context.l10n.saveChanges,
      onAction: () async {
        try {
          await ref
              .read(backendApiProvider)
              .consignorsUpdate(
                businessName: businessName.text.trim().isEmpty
                    ? null
                    : businessName.text.trim(),
                tradeLicence: tradeLicence.text.trim().isEmpty
                    ? null
                    : tradeLicence.text.trim(),
              );
          saved = true;
        } catch (e) {
          saveError = e;
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      businessName.dispose();
      tradeLicence.dispose();
    });
    if (!mounted) return;
    if (saved) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.businessProfileUpdated)));
    } else if (saveError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingMessage(saveError!))));
    }
  }

  Future<void> _editProfile() async {
    final fn = TextEditingController(
      text: _profile?['firstName'] as String? ?? '',
    );
    final ln = TextEditingController(
      text: _profile?['lastName'] as String? ?? '',
    );
    final phone = TextEditingController(
      text: _profile?['phone'] as String? ?? ref.read(authProvider).phone ?? '',
    );
    await _showPremiumSheet(
      title: context.l10n.personalDetails,
      subtitle: context.l10n.updateCorporateIdentity,
      icon: Icons.person_outline_rounded,
      children: [
        _buildInput(fn, context.l10n.firstName),
        _buildInput(ln, context.l10n.lastName),
        _buildInput(phone, context.l10n.phoneNumber, readOnly: true),
      ],
      actionLabel: context.l10n.saveChanges,
      onAction: () async {
        try {
          final base = Map<String, dynamic>.from(_profile ?? {});
          base['firstName'] = fn.text.trim();
          base['lastName'] = ln.text.trim();
          await ref.read(backendApiProvider).identityPut(base);
          await ref.read(authProvider.notifier).refreshProfile();
          await _load();
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
        }
      },
    );
  }

  Future<void> _changePassword() async {
    await _showPremiumSheet(
      title: context.l10n.securityAndAccess,
      subtitle: context.l10n.passwordChangesRequireMfa,
      icon: Icons.shield_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  context.l10n.passwordResetEmailInstructions,
                  style: TextStyle(
                    color: AppColors.warning.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      actionLabel: context.l10n.sendResetLink,
      onAction: () async {},
    );
  }

  Future<void> _showLanguagePicker() async {
    await showAppLanguagePickerSheet(context, ref);
    if (mounted) setState(() {});
  }

  Future<void> _showLegal() async {
    await _showPremiumSheet(
      title: context.l10n.legalAndPrivacy,
      subtitle: context.l10n.consignorPolicies,
      icon: Icons.policy_outlined,
      children: [
        Text(
          context.l10n.privacyPolicyText,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.6,
            fontSize: 15,
          ),
        ),
      ],
      actionLabel: context.l10n.acknowledge,
      onAction: () async {},
    );
  }

  Future<void> _showSupport() async {
    await _showPremiumSheet(
      title: context.l10n.contactSupport,
      subtitle: context.l10n.contactSupportConsignorSubtitle,
      icon: Icons.support_agent_rounded,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_rounded, color: AppColors.primary),
          ),
          title: Text(
            context.l10n.supportHotline,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(context.l10n.consignorPhoneValue),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.email_rounded, color: AppColors.primary),
          ),
          title: Text(
            context.l10n.emailSupport,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(context.l10n.consignorSupportEmailValue),
        ),
      ],
      actionLabel: context.l10n.close,
      onAction: () async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final accountStatusLabel =
        ConsignorAccountStatusUtils.displayLabel(auth, context.l10n);
    final payments = ref.watch(paymentsProvider);
    final shipments = ref.watch(consignorShipmentsProvider);
    final rating = RoleProfileUtils.rating(_consignorProfile);
    final reviewCount = RoleProfileUtils.reviewCount(_consignorProfile);
    final businessName = RoleProfileUtils.stringField(
      _consignorProfile,
      'businessName',
    );
    // Clearance above ConsignorShell bottom nav: SafeArea min bottom (10) + bar (72).
    final bottomNavClearance =
        MediaQuery.paddingOf(context).bottom + 10 + 72 + 24;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: AppColors.backgroundWarm,
            elevation: 0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                context.l10n.profile,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Profile Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            (auth.displayName ?? 'C')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                businessName?.isNotEmpty == true
                                    ? businessName!
                                    : (auth.displayName ??
                                          context.l10n.consignor),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (businessName?.isNotEmpty == true &&
                                  auth.displayName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  auth.displayName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (auth.phone != null && auth.phone!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  auth.phone!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (accountStatusLabel != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    accountStatusLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Elegant Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        title: context.l10n.activeOrders,
                        value: shipments.maybeWhen(
                          data: (list) => list
                              .where(
                                (s) =>
                                    s.status != ShipmentStatus.completed &&
                                    s.status != ShipmentStatus.cancelled,
                              )
                              .length
                              .toString(),
                          orElse: () => '-',
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: context.l10n.payments,
                        value: payments.maybeWhen(
                          data: (list) => list.length.toString(),
                          orElse: () => '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        title: context.l10n.rating,
                        value: RoleProfileUtils.formatRating(rating),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: context.l10n.reviews,
                        value: RoleProfileUtils.formatReviewCount(reviewCount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Grouped Settings Lists
                  _ListHeader(context.l10n.accountDetails),
                  _buildListGroup([
                    _buildListItem(
                      Icons.person_outline_rounded,
                      context.l10n.personalDetails,
                      context.l10n.nameAndContact,
                      onTap: _editProfile,
                    ),
                    _buildListItem(
                      Icons.business_rounded,
                      context.l10n.businessProfile,
                      context.l10n.companyAndTradeLicence,
                      onTap: _editBusinessProfile,
                    ),
                    _buildListItem(
                      Icons.shield_outlined,
                      context.l10n.security,
                      context.l10n.passwordAnd2fa,
                      onTap: _changePassword,
                    ),
                  ]),

                  _ListHeader(context.l10n.logisticsSection),
                  _buildListGroup([
                    _buildListItem(
                      Icons.history_rounded,
                      context.l10n.shipmentArchive,
                      context.l10n.pastLoadHistory,
                      onTap: () => context.push('/consignor/shipments'),
                    ),
                  ]),

                  _ListHeader(context.l10n.preferencesAndSupport),
                  _buildListGroup([
                    _buildListItem(
                      Icons.language_rounded,
                      context.l10n.languageLabel,
                      currentAppLanguageLabel(context, ref),
                      onTap: _showLanguagePicker,
                    ),
                    _buildListItem(
                      Icons.notifications_none_rounded,
                      context.l10n.notifications,
                      context.l10n.pushAlerts,
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                        activeTrackColor: AppColors.primary.withValues(
                          alpha: 0.45,
                        ),
                        activeThumbColor: AppColors.surface,
                      ),
                    ),
                    _buildListItem(
                      Icons.support_agent_rounded,
                      context.l10n.helpDesk,
                      context.l10n.contactSupportConsignorSubtitle,
                      onTap: _showSupport,
                    ),
                    _buildListItem(
                      Icons.policy_outlined,
                      context.l10n.legal,
                      context.l10n.privacyAndTerms,
                      onTap: _showLegal,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (!context.mounted) return;
                        context.go('/login?role=consignor');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        context.l10n.signOut,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomNavClearance),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListItem(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String title;
  const _ListHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.5,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
