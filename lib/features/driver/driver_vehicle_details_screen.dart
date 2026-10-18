import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/data/utils/role_profile_utils.dart';
import 'package:global_logistics_app/shared/widgets/network_document_preview.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverVehicleDetailsScreen extends ConsumerStatefulWidget {
  const DriverVehicleDetailsScreen({super.key});

  @override
  ConsumerState<DriverVehicleDetailsScreen> createState() =>
      _DriverVehicleDetailsScreenState();
}

class _DriverVehicleDetailsScreenState
    extends ConsumerState<DriverVehicleDetailsScreen> {
  Map<String, dynamic>? _vehicle;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = ref.read(authProvider).userPublicId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = StateError('Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = await ref.read(backendApiProvider).vehiclesProfile(id);
      if (!mounted) return;
      setState(() {
        _vehicle = RoleProfileUtils.flattenForFieldLookup(v);
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

  static String _pick(Map<String, dynamic>? m, List<String> keys) {
    if (m == null) return '';
    return RoleProfileUtils.firstStringField(m, keys) ?? '';
  }

  static bool _looksLikeUrl(String s) => RoleProfileUtils.looksLikeUrl(s);

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openDocument(String url) async {
    if (!_looksLikeUrl(url)) return;
    await _openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final v = _vehicle;
    final libreDocument = _pick(v, RoleProfileUtils.vehicleLibreDocumentKeys);
    final libreDocumentSec =
        _pick(v, RoleProfileUtils.vehicleLibreDocumentSecKeys);
    final insuranceDocument =
        _pick(v, RoleProfileUtils.vehicleInsuranceDocumentKeys);

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
          context.l10n.vehicleDetailsTitle,
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
                    _EmptyCard(
                      message:
                          context.l10n.unableToLoadVehicleRetry,
                      icon: Icons.local_shipping_outlined,
                    )
                  else if (v == null || v.isEmpty)
                    _EmptyCard(
                      message:
                          context.l10n.noVehicleDataYet,
                      icon: Icons.directions_car_outlined,
                    )
                  else ...[
                    _HeroVehicleSummary(
                      type: _pick(v, ['type', 'vehicleType']),
                      plate: _pick(v, ['plateNumber', 'plate', 'licensePlate']),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(context.l10n.registrationAndDocuments),
                    _InfoCard(
                      children: [
                        _DetailRowDocument(
                          label: context.l10n.libreDocument,
                          value: libreDocument,
                          onOpen: () => _openDocument(libreDocument),
                        ),
                        _DetailRowDocument(
                          label: context.l10n.libreDocumentSec,
                          value: libreDocumentSec,
                          onOpen: () => _openDocument(libreDocumentSec),
                        ),
                        _DetailRowDocument(
                          label: context.l10n.insuranceDocument,
                          value: insuranceDocument,
                          onOpen: () => _openDocument(insuranceDocument),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(context.l10n.vehicleNotes),
                    _InfoCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _pick(v, ['details', 'description']).isEmpty
                                  ? context.l10n.noAdditionalNotes
                                  : _pick(v, ['details', 'description']),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_pick(v, ['photo', 'photoUrl', 'imageUrl']).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionLabel(context.l10n.photoTitle),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NetworkDocumentPreview(
                          url: _pick(v, ['photo', 'photoUrl', 'imageUrl']),
                          aspectRatio: 16 / 10,
                          borderRadius: 28,
                          onTap: () => _openDocument(
                            _pick(v, ['photo', 'photoUrl', 'imageUrl']),
                          ),
                        ),
                      ),
                    ],
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

class _HeroVehicleSummary extends StatelessWidget {
  const _HeroVehicleSummary({required this.type, required this.plate});

  final String type;
  final String plate;

  @override
  Widget build(BuildContext context) {
    final displayType = type.isEmpty ? context.l10n.vehicle : type;
    final displayPlate = plate.isEmpty ? '—' : plate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E4A42), Color(0xFF0A5C52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayPlate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.registeredFleetVehicle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

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
        children: _joinDividers(children),
      ),
    );
  }

  List<Widget> _joinDividers(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) {
        out.add(const Divider(height: 1, color: AppColors.borderLight));
      }
    }
    return out;
  }
}

class _DetailRowDocument extends StatelessWidget {
  const _DetailRowDocument({
    required this.label,
    required this.value,
    this.onOpen,
  });

  final String label;
  final String value;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (value.isEmpty)
            Text(
              '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
            )
          else
            NetworkDocumentPreview(
              url: value,
              onTap: onOpen,
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
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
