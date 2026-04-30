import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

/// `POST /shipments/create` — `CreateShipmentRequest` per OpenAPI.
class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _loading = TextEditingController();
  final _offloading = TextEditingController();
  final _route = TextEditingController();
  final _goods = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _weight = TextEditingController();
  final _volume = TextEditingController();
  final _vehicle = TextEditingController();
  final _vehicleCount = TextEditingController(text: '1');
  final _timeline = TextEditingController();
  final _price = TextEditingController();
  String _priceType = 'FIXED';

  bool _busy = false;

  @override
  void dispose() {
    _loading.dispose();
    _offloading.dispose();
    _route.dispose();
    _goods.dispose();
    _quantity.dispose();
    _weight.dispose();
    _volume.dispose();
    _vehicle.dispose();
    _vehicleCount.dispose();
    _timeline.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final canBook = ref.read(authProvider).canCreateConsignorBooking;
    if (!canBook) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking is locked until your account is approved by admin.',
          ),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final loadingDate = now.add(const Duration(days: 1));
    final deliveryDate = now.add(const Duration(days: 3));
    setState(() => _busy = true);
    try {
      await ref.read(backendApiProvider).shipmentsCreate({
        'goodType': _goods.text.trim().isEmpty
            ? 'General cargo'
            : _goods.text.trim(),
        'quantity': int.tryParse(_quantity.text.trim()) ?? 1,
        'weight': _weight.text.trim().isEmpty ? '0' : _weight.text.trim(),
        'volume': _volume.text.trim().isEmpty ? '0' : _volume.text.trim(),
        'loadingLocation': _loading.text.trim(),
        'offloadingLocation': _offloading.text.trim(),
        'route': _route.text.trim(),
        'requiredVehicleType': _vehicle.text.trim().isEmpty
            ? 'Any'
            : _vehicle.text.trim(),
        'requiredVehicleNumber': int.tryParse(_vehicleCount.text.trim()) ?? 1,
        'loadingDate': loadingDate.toUtc().toIso8601String(),
        'deliveryDate': deliveryDate.toUtc().toIso8601String(),
        'details': _timeline.text.trim(),
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'priceType': _priceType,
      });
      ref.invalidate(consignorShipmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment created — see console for response.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canBook = auth.canCreateConsignorBooking;
    final rawStatus = (auth.accountStatus ?? '').trim();
    final statusLabel = canBook
        ? (rawStatus.isEmpty ? 'APPROVED' : rawStatus.toUpperCase())
        : (rawStatus.toUpperCase() == 'VERIFIED'
              ? 'VERIFIED (waiting admin approval)'
              : (rawStatus.isEmpty
                    ? 'PENDING ADMIN APPROVAL'
                    : '${rawStatus.toUpperCase()} (waiting admin approval)'));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New booking'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!canBook) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Account status: $statusLabel. Your account is not approved yet, so booking is disabled until admin approval.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            'Create a shipment offer. Dates default to +1 day / +3 days if not provided.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Locations', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _loading,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Loading location *',
              prefixIcon: Icon(Icons.upload_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _offloading,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Offloading location *',
              prefixIcon: Icon(Icons.download_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _route,
            decoration: const InputDecoration(labelText: 'Route (optional)'),
          ),
          const SizedBox(height: 20),
          Text('Cargo', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _goods,
            decoration: const InputDecoration(labelText: 'Type of goods'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weight,
                  decoration: const InputDecoration(
                    labelText: 'Weight (string)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _volume,
            decoration: const InputDecoration(labelText: 'Volume (string)'),
          ),
          const SizedBox(height: 20),
          Text(
            'Vehicle & price',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _vehicle,
            decoration: const InputDecoration(
              labelText: 'Required vehicle type',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehicleCount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Required vehicle count',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Offer price (number)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _priceType,
            items: const [
              DropdownMenuItem(value: 'FIXED', child: Text('FIXED')),
              DropdownMenuItem(value: 'PER_TON', child: Text('PER_TON')),
              DropdownMenuItem(value: 'PER_KM', child: Text('PER_KM')),
            ],
            onChanged: (v) => setState(() => _priceType = v ?? _priceType),
            decoration: const InputDecoration(labelText: 'Price type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeline,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Details / notes'),
          ),
          const SizedBox(height: 28),
          GlPrimaryButton(
            label: 'Submit booking',
            icon: Icons.send_rounded,
            isLoading: _busy,
            onPressed: canBook ? _submit : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
