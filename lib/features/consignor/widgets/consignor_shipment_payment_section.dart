import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/payments_provider.dart';
import 'package:global_logistics_app/data/utils/finance_api_utils.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:global_logistics_app/shared/widgets/presigned_url_upload_row.dart';
import 'package:global_logistics_app/shared/widgets/shipment_receipt_upload_row.dart';
import 'package:intl/intl.dart';

/// Consignor payment block on shipment detail: loads finance via
/// GET /shipment-finance/shipment/{shipmentId}, submits via POST /shipment-finance.
class ConsignorShipmentPaymentSection extends ConsumerStatefulWidget {
  const ConsignorShipmentPaymentSection({
    super.key,
    required this.shipmentId,
    this.enabled = true,
    this.refreshSignal = 0,
  });

  final String shipmentId;
  final bool enabled;
  final int refreshSignal;

  @override
  ConsumerState<ConsignorShipmentPaymentSection> createState() =>
      _ConsignorShipmentPaymentSectionState();
}

class _ConsignorShipmentPaymentSectionState
    extends ConsumerState<ConsignorShipmentPaymentSection> {
  String? _shipmentFinanceId;
  double _agreedAmount = 0;
  double _paidAmount = 0;
  double _remainingAmount = 0;
  String _status = '—';
  String _currency = 'ETB';
  List<_PaymentLine> _history = const [];
  bool _loading = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFinance());
  }

  @override
  void didUpdateWidget(ConsignorShipmentPaymentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shipmentId != widget.shipmentId ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.refreshSignal != widget.refreshSignal) {
      _loadFinance();
    }
  }

  Future<void> _loadFinance() async {
    if (!widget.enabled) {
      if (mounted) {
        setState(() {
          _shipmentFinanceId = null;
          _history = const [];
          _loadError = null;
          _loading = false;
        });
      }
      return;
    }

    final shipmentId = widget.shipmentId.trim();
    if (shipmentId.isEmpty) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final raw = await ref
          .read(backendApiProvider)
          .shipmentFinanceByShipment(shipmentId);
      final body = FinanceApiUtils.unwrapPayload(raw);
      final payments = (body['payments'] as List?) ?? const [];
      final history = <_PaymentLine>[];
      for (final p in payments) {
        if (p is! Map) continue;
        final m = p.cast<String, dynamic>();
        final amount = (m['paidAmount'] as num?)?.toDouble() ??
            (m['amount'] as num?)?.toDouble() ??
            0;
        history.add(
          _PaymentLine(
            amount: amount,
            currency: (body['priceCurrency'] as String?) ?? 'ETB',
            status: m['status'] as String? ?? '—',
            paidAt: DateTime.tryParse(m['paidAt'] as String? ?? '') ??
                DateTime.now(),
            referenceNo: m['referenceNo'] as String?,
          ),
        );
      }
      history.sort((a, b) => b.paidAt.compareTo(a.paidAt));

      if (!mounted) return;
      setState(() {
        _shipmentFinanceId = FinanceApiUtils.financePublicId(raw);
        _agreedAmount = (body['agreedAmount'] as num?)?.toDouble() ?? 0;
        _paidAmount = (body['paidAmount'] as num?)?.toDouble() ?? 0;
        _remainingAmount = (body['remainingAmount'] as num?)?.toDouble() ?? 0;
        _status = body['status'] as String? ?? '—';
        _currency = (body['priceCurrency'] as String?) ?? 'ETB';
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  static String _formatAmount(double value) {
    if (value.truncateToDouble() == value) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  bool get _isFullyPaid => _remainingAmount <= 0;

  Future<void> _openPaymentSheet() async {
    if (_isFullyPaid) return;
    final financeId = _shipmentFinanceId;
    if (financeId == null || financeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.paymentRecordNotReady),
        ),
      );
      return;
    }

    final amt = TextEditingController();
    final refNo = TextEditingController();
    final slip = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final remainingText = _remainingAmount > 0
        ? 'Outstanding: ${_formatAmount(_remainingAmount)} $_currency'
        : null;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? amountError;
        String? slipError;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
        margin: EdgeInsets.only(top: MediaQuery.paddingOf(ctx).top + 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 32,
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
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.recordPayment,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.submitNewPaymentRecord,
                style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
              if (remainingText != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    remainingText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SheetField(
                controller: amt,
                label: formFieldLabel('Paid amount', required: true),
                type: TextInputType.number,
                errorText: amountError,
                onChanged: () {
                  if (amountError != null) {
                    setSheetState(() => amountError = null);
                  }
                },
              ),
              _SheetField(
                controller: refNo,
                label: 'Reference number',
              ),
              ShipmentReceiptUploadRow(slipController: slip),
              if (slipError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    slipError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              PresignedUploadAttachedHint(
                controller: slip,
                message: l10n.paymentReceiptAttached,
              ),
              const SizedBox(height: 28),
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
                    final paid = double.tryParse(amt.text.trim());
                    var hasError = false;
                    if (paid == null || paid <= 0) {
                      setSheetState(() {
                        amountError = l10n.fieldMustBeValidPositiveNumber(
                          'Paid amount',
                        );
                      });
                      hasError = true;
                    }
                    final slipUrl = slip.text.trim();
                    if (slipUrl.isEmpty) {
                      setSheetState(() => slipError = l10n.uploadPaymentReceipt);
                      hasError = true;
                    }
                    if (hasError) return;
                    final refText = refNo.text.trim();
                    try {
                      await ref
                          .read(backendApiProvider)
                          .shipmentFinanceCreatePayment({
                        'shipmentFinanceId': financeId,
                        'paidAmount': paid,
                        'referenceNo': refText,
                        'slipUrl': slipUrl,
                        'paidAt': DateTime.now().toUtc().toIso8601String(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(userFacingMessage(e))),
                      );
                    }
                  },
                  child: const Text(
                    'Submit payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );

    // Defer disposal: the sheet exit animation may still reference controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      amt.dispose();
      refNo.dispose();
      slip.dispose();
    });

    if (!mounted || submitted != true) return;

    // Let the sheet exit animation fully finish before triggering rebuilds.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    await _loadFinance();
    ref.invalidate(paymentsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.paymentSubmittedSuccessfully)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd(l10n.localeName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  l10n.payments,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight, thickness: 1.5),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.enabled)
                  Text(
                    'Payment is available once a driver is assigned to this booking.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  )
                else if (_loading)
                  const LinearProgressIndicator()
                else if (_loadError != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userFacingMessage(_loadError!),
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadFinance,
                        child: Text(context.l10n.tryAgain),
                      ),
                    ],
                  )
                else ...[
                  _FinanceSummaryStrip(
                    agreed: _agreedAmount,
                    paid: _paidAmount,
                    remaining: _remainingAmount,
                    currency: _currency,
                    status: _status,
                  ),
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Payment history',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._history.map(
                      (line) => _HistoryTile(line: line, dateFmt: dateFmt),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GlPrimaryButton(
                    label: l10n.recordPayment,
                    icon: Icons.upload_file_rounded,
                    onPressed: _shipmentFinanceId == null || _isFullyPaid
                        ? null
                        : _openPaymentSheet,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceSummaryStrip extends StatelessWidget {
  const _FinanceSummaryStrip({
    required this.agreed,
    required this.paid,
    required this.remaining,
    required this.currency,
    required this.status,
  });

  final double agreed;
  final double paid;
  final double remaining;
  final String currency;
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final isPaid =
        normalized.contains('PAID') && !normalized.contains('UNPAID');
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primarySoft,
            AppColors.primarySoft.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Agreed',
                  value:
                      '${_ConsignorShipmentPaymentSectionState._formatAmount(agreed)} $currency',
                ),
              ),
              Expanded(
                child: _SummaryCell(
                  label: 'Paid',
                  value:
                      '${_ConsignorShipmentPaymentSectionState._formatAmount(paid)} $currency',
                  highlight: paid > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Remaining',
                  value:
                      '${_ConsignorShipmentPaymentSectionState._formatAmount(remaining)} $currency',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.line, required this.dateFmt});

  final _PaymentLine line;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_ConsignorShipmentPaymentSectionState._formatAmount(line.amount)} ${line.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    dateFmt.format(line.paidAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              line.status.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentLine {
  const _PaymentLine({
    required this.amount,
    required this.currency,
    required this.status,
    required this.paidAt,
    this.referenceNo,
  });

  final double amount;
  final String currency;
  final String status;
  final DateTime paidAt;
  final String? referenceNo;
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.type,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? type;
  final String? errorText;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: formContainerBorderColor(
            errorText: errorText,
            normal: AppColors.borderLight,
          ),
          width: formContainerBorderWidth(
            errorText: errorText,
            normal: 1.5,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        onChanged: (_) => onChanged?.call(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
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
}
