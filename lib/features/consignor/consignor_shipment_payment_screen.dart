import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:global_logistics_app/core/providers/payments_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/features/consignor/widgets/consignor_assignment_picker_sheet.dart';
import 'package:global_logistics_app/features/consignor/widgets/consignor_shipment_payment_section.dart';

class ConsignorShipmentPaymentScreen extends ConsumerStatefulWidget {
  const ConsignorShipmentPaymentScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<ConsignorShipmentPaymentScreen> createState() =>
      _ConsignorShipmentPaymentScreenState();
}

class _ConsignorShipmentPaymentScreenState
    extends ConsumerState<ConsignorShipmentPaymentScreen> {
  List<ConsignorAssignmentPreview>? _assignments;
  bool _loadingAssignments = true;
  int _paymentRefreshSignal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAssignments());
  }

  Future<void> _loadAssignments() async {
    final shipments = ref.read(consignorShipmentsProvider).valueOrNull ?? const [];
    final shipment = _findShipment(shipments);
    if (shipment == null) {
      if (mounted) setState(() => _loadingAssignments = false);
      return;
    }
    try {
      final previews = await loadConsignorAssignmentPreviews(ref, shipment);
      if (!mounted) return;
      setState(() {
        _assignments = previews;
        _loadingAssignments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assignments = const [];
        _loadingAssignments = false;
      });
    }
  }

  ShipmentModel? _findShipment(List<ShipmentModel> shipments) {
    for (final s in shipments) {
      if (s.id == widget.shipmentId || s.publicId == widget.shipmentId) {
        return s;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(consignorShipmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWarm,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.payments,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _paymentRefreshSignal++);
              ref.invalidate(consignorShipmentsProvider);
              ref.invalidate(paymentsProvider);
              _loadAssignments();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: async.when(
        data: (shipments) {
          final shipment = _findShipment(shipments);
          if (shipment == null) {
            return Center(child: Text(context.l10n.shipmentNotFound));
          }
          if (_loadingAssignments) {
            return const Center(child: CircularProgressIndicator());
          }
          final assignments = _assignments ?? const [];
          final paymentEnabled = consignorBookingPaymentEnabled(
            shipment,
            assignments,
          );
          return ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              ConsignorShipmentPaymentSection(
                shipmentId: shipment.id,
                enabled: paymentEnabled,
                refreshSignal: _paymentRefreshSignal,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userFacingMessage(e))),
      ),
    );
  }
}
