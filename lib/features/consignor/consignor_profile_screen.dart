import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/payments_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

class ConsignorProfileScreen extends ConsumerStatefulWidget {
  const ConsignorProfileScreen({super.key});

  @override
  ConsumerState<ConsignorProfileScreen> createState() => _ConsignorProfileScreenState();
}

class _ConsignorProfileScreenState extends ConsumerState<ConsignorProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final p = await ref.read(backendApiProvider).identityGet();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  Future<void> _showPremiumSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    String? actionLabel,
    VoidCallback? onAction,
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
          bottom: MediaQuery.viewInsetsOf(ctx).bottom +
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      onAction();
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildInput(TextEditingController controller, String label, {TextInputType? type}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    final fn = TextEditingController(text: _profile?['firstName'] as String? ?? '');
    final ln = TextEditingController(text: _profile?['lastName'] as String? ?? '');
    await _showPremiumSheet(
      title: 'Personal Details',
      subtitle: 'Update your corporate identity and contact information.',
      icon: Icons.person_outline_rounded,
      children: [
        _buildInput(fn, 'First Name'),
        _buildInput(ln, 'Last Name'),
      ],
      actionLabel: 'Save Changes',
      onAction: () async {
        try {
          final base = Map<String, dynamic>.from(_profile ?? {});
          base['firstName'] = fn.text.trim();
          base['lastName'] = ln.text.trim();
          await ref.read(backendApiProvider).identityPut(base);
          await ref.read(authProvider.notifier).refreshProfile();
          await _load();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
        }
      },
    );
  }

  Future<void> _changePassword() async {
    await _showPremiumSheet(
      title: 'Security & Access',
      subtitle: 'For your protection, password changes require multi-factor authentication.',
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
              Icon(Icons.mark_email_read_outlined, color: AppColors.warning, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Please check your registered email for password reset instructions.',
                  style: TextStyle(color: AppColors.warning.withValues(alpha: 0.9), fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
      actionLabel: 'Send Reset Link',
      onAction: () {},
    );
  }

  Future<void> _addShipmentPayment() async {
    final fid = TextEditingController();
    final amt = TextEditingController();
    final refNo = TextEditingController();
    final slip = TextEditingController(text: 'https://example.com/slip.png');
    await _showPremiumSheet(
      title: 'Record Payment',
      subtitle: 'Submit a new payment record for your financial ledger.',
      icon: Icons.receipt_long_rounded,
      children: [
        _buildInput(fid, 'Finance ID'),
        _buildInput(amt, 'Amount', type: TextInputType.number),
        _buildInput(refNo, 'Reference Number'),
        _buildInput(slip, 'Receipt URL'),
      ],
      actionLabel: 'Submit Record',
      onAction: () async {
        try {
          await ref.read(backendApiProvider).shipmentFinanceCreatePayment({
            'shipmentFinanceId': fid.text.trim(),
            'paidAmount': double.tryParse(amt.text.trim()) ?? 0,
            'referenceNo': refNo.text.trim(),
            'slipUrl': slip.text.trim(),
            'paidAt': DateTime.now().toUtc().toIso8601String(),
          });
          ref.invalidate(paymentsProvider);
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
        }
      },
    );
  }

  Future<void> _showLanguagePicker() async {
    await _showPremiumSheet(
      title: 'App Language',
      subtitle: 'Choose your preferred language for the interface.',
      icon: Icons.language_rounded,
      children: [
        _buildLanguageOption('🇺🇸', 'English (US)', true),
        _buildLanguageOption('🇪🇹', 'Amharic', false),
      ],
      actionLabel: 'Confirm Selection',
      onAction: () {},
    );
  }

  Widget _buildLanguageOption(String flag, String name, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.borderLight, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      ),
    );
  }

  Future<void> _showLegal() async {
    await _showPremiumSheet(
      title: 'Legal & Privacy',
      subtitle: 'Global Logistics PLC policies.',
      icon: Icons.policy_outlined,
      children: [
        const Text(
          'Your data is protected under our strict corporate privacy policies. We do not share shipping metrics or personal details with unauthorized third parties.\n\nFor full terms of service, please visit our website.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.6, fontSize: 15),
        ),
      ],
      actionLabel: 'Acknowledge',
      onAction: () {},
    );
  }

  Future<void> _showSupport() async {
    await _showPremiumSheet(
      title: 'Contact Support',
      subtitle: '24/7 priority help desk for consignors.',
      icon: Icons.support_agent_rounded,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.phone_rounded, color: AppColors.primary),
          ),
          title: const Text('Phone Support', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('+251 900 000 000'),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.email_rounded, color: AppColors.primary),
          ),
          title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('support@global-logistics.com'),
        ),
      ],
      actionLabel: 'Close',
      onAction: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canBook = auth.canCreateConsignorBooking;
    final rawStatus = (auth.accountStatus ?? '').trim();
    final statusLabel = canBook
        ? (rawStatus.isEmpty ? 'APPROVED' : rawStatus.toUpperCase())
        : (rawStatus.toUpperCase() == 'VERIFIED'
              ? 'VERIFIED (WAITING ADMIN APPROVAL)'
              : (rawStatus.isEmpty
                    ? 'PENDING ADMIN APPROVAL'
                    : '${rawStatus.toUpperCase()} (WAITING ADMIN APPROVAL)'));
    final payments = ref.watch(paymentsProvider);
    final shipments = ref.watch(consignorShipmentsProvider);
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
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Profile',
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
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            (auth.displayName ?? 'C').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.displayName ?? 'Consignor',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: canBook ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: canBook ? AppColors.success : AppColors.warning,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
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
                        title: 'Active Orders',
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
                        title: 'Payments',
                        value: payments.maybeWhen(
                          data: (list) => list.length.toString(),
                          orElse: () => '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Grouped Settings Lists
                  const _ListHeader('Account Details'),
                  _buildListGroup([
                    _buildListItem(Icons.person_outline_rounded, 'Personal Details', 'Corporate info', onTap: _editProfile),
                    _buildListItem(Icons.shield_outlined, 'Security', 'Password & 2FA', onTap: _changePassword),
                    _buildListItem(Icons.account_balance_wallet_outlined, 'Financial Ledger', 'Records & invoices', onTap: _addShipmentPayment),
                  ]),

                  const _ListHeader('Logistics'),
                  _buildListGroup([
                    _buildListItem(Icons.history_rounded, 'Shipment Archive', 'Past load history', onTap: () => context.push('/consignor/shipments')),
                  ]),

                  const _ListHeader('Preferences & Support'),
                  _buildListGroup([
                    _buildListItem(Icons.language_rounded, 'Language', 'English (US)', onTap: _showLanguagePicker),
                    _buildListItem(Icons.notifications_none_rounded, 'Notifications', 'Push alerts', trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
                      activeThumbColor: AppColors.surface,
                    )),
                    _buildListItem(Icons.support_agent_rounded, 'Help Desk', '24/7 priority support', onTap: _showSupport),
                    _buildListItem(Icons.policy_outlined, 'Legal', 'Privacy & terms', onTap: _showLegal),
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
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceHighlight, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.textPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5, color: AppColors.textTertiary),
      ),
    );
  }
}
