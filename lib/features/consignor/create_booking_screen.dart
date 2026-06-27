import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/utils/consignor_account_status_utils.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
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

  bool _busy = false;
  DateTime? _loadingDate;
  DateTime? _deliveryDate;
  final Map<String, String?> _fieldErrors = {};

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors.remove(key));
    }
  }

  bool _validateForm() {
    final l10n = context.l10n;
    final errors = <String, String?>{};

    if (isFormFieldEmpty(_loading.text)) {
      errors['loading'] = l10n.fieldIsRequired(l10n.loadingLocation);
    }
    if (isFormFieldEmpty(_offloading.text)) {
      errors['offloading'] = l10n.fieldIsRequired(l10n.offloadingLocation);
    }
    if (_loadingDate == null) {
      errors['loadingDate'] = l10n.fieldIsRequired(l10n.loadingDateTime);
    }
    if (_deliveryDate == null) {
      errors['deliveryDate'] = l10n.fieldIsRequired(l10n.deliveryDateTime);
    }
    if (isFormFieldEmpty(_goods.text)) {
      errors['goods'] = l10n.fieldIsRequired(l10n.typeOfGoods);
    }
    if (isFormFieldEmpty(_vehicle.text)) {
      errors['vehicle'] = l10n.fieldIsRequired(l10n.vehicleType);
    }
    if (isFormFieldEmpty(_price.text)) {
      errors['price'] = l10n.fieldIsRequired(l10n.offerPrice);
    } else if (!isPositiveNumber(_price.text)) {
      errors['price'] = l10n.fieldMustBeValidPositiveNumber(l10n.offerPrice);
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

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
    if (!_validateForm()) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendApiProvider).shipmentsCreate({
        'goodType': _goods.text.trim(),
        'quantity': int.tryParse(_quantity.text.trim()) ?? 1,
        'weight': _weight.text.trim().isEmpty ? '0' : _weight.text.trim(),
        'volume': _volume.text.trim().isEmpty ? '0' : _volume.text.trim(),
        'loadingLocation': _loading.text.trim(),
        'offloadingLocation': _offloading.text.trim(),
        'route': _route.text.trim(),
        'requiredVehicleType': _vehicle.text.trim(),
        'requiredVehicleNumber': int.tryParse(_vehicleCount.text.trim()) ?? 1,
        'loadingDate': _loadingDate!.toUtc().toIso8601String(),
        'deliveryDate': _deliveryDate!.toUtc().toIso8601String(),
        'details': _timeline.text.trim(),
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'priceType': 'FIXED',
      });
      ref.invalidate(consignorShipmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.shipmentCreatedSuccessfully),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<DateTime?> _pickDateTime({required DateTime initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Widget _buildDateInput({
    required String label,
    required IconData icon,
    required String fieldKey,
    required DateTime? value,
    required Future<void> Function() onTap,
    required String emptyHint,
    bool required = false,
  }) {
    final errorText = _fieldErrors[fieldKey];
    final displayFmt = DateFormat.yMMMd().add_jm();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: formContainerBorderColor(errorText: errorText),
          width: formContainerBorderWidth(errorText: errorText),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          isFocused: false,
          decoration: InputDecoration(
            isDense: true,
            labelText: formFieldLabel(label, required: required),
            errorText: errorText,
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            labelStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            prefixIcon: Container(
              alignment: Alignment.center,
              width: 44,
              child: Icon(
                icon,
                color: AppColors.primary.withValues(alpha: 0.8),
                size: 20,
              ),
            ),
            suffixIcon: Icon(
              Icons.event_rounded,
              color: AppColors.primary.withValues(alpha: 0.8),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          child: Text(
            value == null ? emptyHint : displayFmt.format(value.toLocal()),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: value == null
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : AppColors.textPrimary,
              fontSize: value == null ? 13 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String fieldKey,
    int? maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    bool required = false,
  }) {
    final errorText = _fieldErrors[fieldKey];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: formContainerBorderColor(errorText: errorText),
          width: formContainerBorderWidth(errorText: errorText),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines == null ? 1 : null,
        keyboardType: keyboardType,
        onChanged: (_) => _clearFieldError(fieldKey),
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          labelText: formFieldLabel(label, required: required),
          hintText: hint,
          errorText: errorText,
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.only(top: (maxLines != null && maxLines > 1) ? 12 : 0),
            alignment: (maxLines != null && maxLines > 1) ? Alignment.topCenter : Alignment.center,
            width: 44,
            child: Icon(icon, color: AppColors.primary.withValues(alpha: 0.8), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: (maxLines != null && maxLines > 1) ? 12 : 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.borderLight.withValues(alpha: 0.5),
            thickness: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canBook = auth.canCreateConsignorBooking;
    final accountStatusLabel =
        ConsignorAccountStatusUtils.displayLabel(auth, context.l10n);

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWarm,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.createBookingTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.heroCardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.l10n.newShipment,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.createNewShipmentOfferDesc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notice if not approved
          if (!canBook && accountStatusLabel != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.l10n.statusPrefix}$accountStatusLabel',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.accountPendingAdminApprovalDesc,
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Form Sections
          _buildSection(
            title: context.l10n.routeAndLogistics,
            icon: Icons.map_outlined,
            children: [
              _buildInput(
                controller: _loading,
                fieldKey: 'loading',
                label: context.l10n.loadingLocation,
                hint: 'e.g. Addis Ababa, Warehouse A',
                icon: Icons.upload_rounded,
                required: true,
              ),
              _buildDateInput(
                label: context.l10n.loadingDateTime,
                icon: Icons.schedule_rounded,
                fieldKey: 'loadingDate',
                value: _loadingDate,
                emptyHint: context.l10n.selectLoadingDateTime,
                required: true,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await _pickDateTime(
                    initial: _loadingDate ?? now.add(const Duration(days: 1)),
                  );
                  if (picked == null) return;
                  setState(() {
                    _loadingDate = picked;
                    _fieldErrors.remove('loadingDate');
                  });
                },
              ),
              _buildInput(
                controller: _offloading,
                fieldKey: 'offloading',
                label: context.l10n.offloadingLocation,
                hint: 'e.g. Adama, Central Hub',
                icon: Icons.download_rounded,
                required: true,
              ),
              _buildDateInput(
                label: context.l10n.deliveryDateTime,
                icon: Icons.event_available_rounded,
                fieldKey: 'deliveryDate',
                value: _deliveryDate,
                emptyHint: context.l10n.selectDeliveryDateTime,
                required: true,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await _pickDateTime(
                    initial: _deliveryDate ??
                        _loadingDate ??
                        now.add(const Duration(days: 3)),
                  );
                  if (picked == null) return;
                  setState(() {
                    _deliveryDate = picked;
                    _fieldErrors.remove('deliveryDate');
                  });
                },
              ),
              _buildInput(
                controller: _route,
                fieldKey: 'route',
                label: context.l10n.preferredRouteOptional,
                hint: 'Specific highways or transit points',
                icon: Icons.alt_route_rounded,
              ),
            ],
          ),

          _buildSection(
            title: context.l10n.cargoInformation,
            icon: Icons.inventory_2_outlined,
            children: [
              _buildInput(
                controller: _goods,
                fieldKey: 'goods',
                label: context.l10n.typeOfGoods,
                hint: 'e.g. Electronics, Textiles, Perishables',
                icon: Icons.category_outlined,
                required: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _quantity,
                      fieldKey: 'quantity',
                      label: context.l10n.quantity,
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      controller: _weight,
                      fieldKey: 'weight',
                      label: context.l10n.weight,
                      hint: 'e.g. 5000 kg',
                      icon: Icons.scale_rounded,
                    ),
                  ),
                ],
              ),
              _buildInput(
                controller: _volume,
                fieldKey: 'volume',
                label: context.l10n.volume,
                hint: 'e.g. 20 cubic meters',
                icon: Icons.view_in_ar_rounded,
              ),
            ],
          ),

          _buildSection(
            title: context.l10n.vehicleAndPricing,
            icon: Icons.local_shipping_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildInput(
                      controller: _vehicle,
                      fieldKey: 'vehicle',
                      label: context.l10n.vehicleType,
                      hint: 'e.g. Flatbed, Reefer',
                      icon: Icons.fire_truck_outlined,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _buildInput(
                      controller: _vehicleCount,
                      fieldKey: 'vehicleCount',
                      label: context.l10n.count,
                      icon: Icons.tag_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _buildInput(
                controller: _price,
                fieldKey: 'price',
                label: context.l10n.offerPrice,
                hint: 'e.g. 15000',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                required: true,
              ),
            ],
          ),

          _buildSection(
            title: context.l10n.additionalDetails,
            icon: Icons.note_alt_outlined,
            children: [
              _buildInput(
                controller: _timeline,
                fieldKey: 'timeline',
                label: context.l10n.specialInstructions,
                hint: 'Any fragile handling, timeline constraints, or documentation needed...',
                icon: Icons.edit_note_rounded,
                maxLines: 3,
              ),
            ],
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            child: GlPrimaryButton(
              label: context.l10n.publishBookingOffer,
              icon: Icons.rocket_launch_rounded,
              isLoading: _busy,
              onPressed: canBook ? _submit : null,
              useGoldAccent: true,
            ),
          ),
        ],
      ),
    );
  }
}

