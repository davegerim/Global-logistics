import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/utils/consignor_account_status_utils.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverLicenseDetailsScreen extends ConsumerStatefulWidget {
  const DriverLicenseDetailsScreen({super.key});

  @override
  ConsumerState<DriverLicenseDetailsScreen> createState() =>
      _DriverLicenseDetailsScreenState();
}

class _DriverLicenseDetailsScreenState
    extends ConsumerState<DriverLicenseDetailsScreen> {
  Map<String, dynamic>? _identity;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ref.read(backendApiProvider).identityGet();
      if (!mounted) return;
      setState(() {
        _identity = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  static bool _looksLikeUrl(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Collects licence-related fields from identity root and common nested maps.
  static List<_LicenseField> _collectFields(BuildContext context, Map<String, dynamic> raw) {
    final seen = <String>{};
    final out = <_LicenseField>[];

    void addPair(String label, dynamic value) {
      if (value == null) return;
      final s = value.toString().trim();
      if (s.isEmpty) return;
      final key = '$label:$s';
      if (seen.contains(key)) return;
      seen.add(key);
      final showAsImage = label == 'Profile photo' && _looksLikeUrl(s);
      out.add(_LicenseField(label, s, showAsImage: showAsImage));
    }

    final directKeys = <String, String>{
      'licenceNumber': context.l10n.licenseNumber,
      'licenseNumber': context.l10n.licenseNumber,
      'licenceDocument': context.l10n.licenseDocument,
      'licenseDocument': context.l10n.licenseDocument,
      'nationalId': context.l10n.nationalId,
      'preferredLanes': context.l10n.preferredLanes,
      'profilePic': context.l10n.profilePhoto,
    };

    void scan(Map<String, dynamic> map) {
      for (final e in directKeys.entries) {
        if (map.containsKey(e.key)) {
          addPair(e.value, map[e.key]);
        }
      }
    }

    scan(raw);

    for (final nest in ['driver', 'driverProfile', 'driverDetails', 'profile']) {
      final n = raw[nest];
      if (n is Map) {
        scan(Map<String, dynamic>.from(n));
      }
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final accountStatusLabel =
        DriverAccountStatusUtils.displayLabel(auth, context.l10n);
    final fields =
        _identity == null ? <_LicenseField>[] : _collectFields(context, _identity!);

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWarm,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.driverLicense,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _LicenseEmptyCard(
                      message:
                          context.l10n.unableToLoadProfileRetry,
                      icon: Icons.badge_outlined,
                    )
                  else ...[
                    _LicenseHero(
                      statusLabel: accountStatusLabel,
                      name: auth.displayName ?? context.l10n.driver,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(context.l10n.verificationAndCredentials),
                    if (fields.isEmpty)
                      _LicenseEmptyCard(
                        message: context.l10n.noLicenseDetailsDesc,
                        icon: Icons.info_outline_rounded,
                      )
                    else
                      _LicenseFieldsCard(
                        fields: fields,
                        onOpenUrl: _openUrl,
                        looksLikeUrl: _looksLikeUrl,
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        context.l10n.documentLinksBrowserDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseField {
  _LicenseField(this.label, this.value, {this.showAsImage = false});

  final String label;
  final String value;
  final bool showAsImage;
}

class _LicenseHero extends StatelessWidget {
  const _LicenseHero({required this.statusLabel, required this.name});

  final String? statusLabel;
  final String name;

  @override
  Widget build(BuildContext context) {
    final badgeColor = AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  context.l10n.licenseDetailsStoredDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

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

class _LicenseFieldsCard extends StatelessWidget {
  const _LicenseFieldsCard({
    required this.fields,
    required this.onOpenUrl,
    required this.looksLikeUrl,
  });

  final List<_LicenseField> fields;
  final Future<void> Function(String url) onOpenUrl;
  final bool Function(String url) looksLikeUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.borderLight),
            _LicenseFieldTile(
              field: fields[i],
              onOpenUrl: fields[i].showAsImage
                  ? null
                  : looksLikeUrl(fields[i].value)
                      ? () => onOpenUrl(fields[i].value)
                      : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _LicenseFieldTile extends StatelessWidget {
  const _LicenseFieldTile({required this.field, this.onOpenUrl});

  final _LicenseField field;
  final VoidCallback? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          if (field.showAsImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  field.value,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceHighlight,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            )
          else
            SelectableText(
              field.value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
            ),
          if (onOpenUrl != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onOpenUrl,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(context.l10n.openLink),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LicenseEmptyCard extends StatelessWidget {
  const _LicenseEmptyCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: AppColors.textTertiary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
