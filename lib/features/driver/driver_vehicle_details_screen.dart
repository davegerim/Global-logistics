import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
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
        _vehicle = v;
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

  static String _pick(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
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

  @override
  Widget build(BuildContext context) {
    final v = _vehicle;

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
          'Vehicle details',
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
                          'Unable to load vehicle profile. Pull to retry.',
                      icon: Icons.local_shipping_outlined,
                    )
                  else if (v == null || v.isEmpty)
                    const _EmptyCard(
                      message:
                          'No vehicle data yet. Complete registration or contact support.',
                      icon: Icons.directions_car_outlined,
                    )
                  else ...[
                    _HeroVehicleSummary(
                      type: _pick(v, ['type', 'vehicleType']),
                      plate: _pick(v, ['plateNumber', 'plate', 'licensePlate']),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Registration & documents'),
                    _InfoCard(
                      children: [
                        _DetailRow(
                          label: 'Libri number',
                          value: _pick(v, ['libriNumber', 'libri_no']),
                          emptyHint: '—',
                        ),
                        _DetailRowLink(
                          label: 'Libri document',
                          value: _pick(v, ['libriDocument', 'libri_document']),
                          onOpen:
                              _looksLikeUrl(_pick(v, ['libriDocument', 'libri_document']))
                                  ? () => _openUrl(
                                        _pick(v, ['libriDocument', 'libri_document']),
                                      )
                                  : null,
                        ),
                        _DetailRow(
                          label: 'Insurance number',
                          value:
                              _pick(v, ['insuranceNumber', 'insurance_number']),
                          emptyHint: '—',
                        ),
                        _DetailRowLink(
                          label: 'Insurance document',
                          value: _pick(
                            v,
                            ['insuranceDocument', 'insurance_document'],
                          ),
                          onOpen: _looksLikeUrl(
                            _pick(v, ['insuranceDocument', 'insurance_document']),
                          )
                              ? () => _openUrl(
                                    _pick(
                                      v,
                                      ['insuranceDocument', 'insurance_document'],
                                    ),
                                  )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Vehicle notes'),
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
                                  ? 'No additional notes on file.'
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
                      const _SectionLabel('Photo'),
                      _VehiclePhotoCard(
                        url: _pick(v, ['photo', 'photoUrl', 'imageUrl']),
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
    final displayType = type.isEmpty ? 'Vehicle' : type;
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
            'Registered fleet vehicle on your driver profile.',
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emptyHint = '—',
  });

  final String label;
  final String value;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? emptyHint : value;
    final muted = value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              display,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: muted ? AppColors.textTertiary : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowLink extends StatelessWidget {
  const _DetailRowLink({
    required this.label,
    required this.value,
    this.onOpen,
  });

  final String label;
  final String value;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final hasLink = onOpen != null && value.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (value.isEmpty)
                  Text(
                    '—',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                else ...[
                  SelectableText(
                    value,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                  if (hasLink) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open link'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehiclePhotoCard extends StatelessWidget {
  const _VehiclePhotoCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            url,
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
