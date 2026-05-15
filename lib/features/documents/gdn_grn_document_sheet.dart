import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/features/documents/gdn_grn_document_view_model.dart';
import 'package:global_logistics_app/features/documents/gdn_grn_pdf.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Opens the GDN/GRN detail bottom sheet with summary, QR, and PDF download.
Future<void> showGdnGrnDocumentSheet(
  BuildContext context, {
  required DocumentRef documentRef,
  required DateFormat dateFmt,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GdnGrnDocumentSheet(
      documentRef: documentRef,
      dateFmt: dateFmt,
    ),
  );
}

class GdnGrnDocumentSheet extends ConsumerStatefulWidget {
  const GdnGrnDocumentSheet({
    super.key,
    required this.documentRef,
    required this.dateFmt,
  });

  final DocumentRef documentRef;
  final DateFormat dateFmt;

  @override
  ConsumerState<GdnGrnDocumentSheet> createState() => _GdnGrnDocumentSheetState();
}

class _GdnGrnDocumentSheetState extends ConsumerState<GdnGrnDocumentSheet> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _loading = true;
  String? _error;
  GdnGrnDocumentViewModel? _vm;
  bool _pdfBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(backendApiProvider);
      final map = widget.documentRef.type == 'GDN'
          ? await api.gdnGet(widget.documentRef.id)
          : await api.grnGet(widget.documentRef.id);
      if (!mounted) return;
      setState(() {
        _vm = GdnGrnDocumentViewModel.from(map, widget.documentRef.type);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingMessage(e);
        _vm = GdnGrnDocumentViewModel.from(
          {
            'publicId': widget.documentRef.id,
            if (widget.documentRef.documentNumber != null)
              'documentNumber': widget.documentRef.documentNumber,
            if (widget.documentRef.qrCodeValue != null)
              'qrCodeValue': widget.documentRef.qrCodeValue,
            if (widget.documentRef.status != null) 'status': widget.documentRef.status,
            'issuedAt': widget.documentRef.availableAt.toIso8601String(),
          },
          widget.documentRef.type,
        );
        _loading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    final vm = _vm;
    if (vm == null || _pdfBusy) return;
    setState(() => _pdfBusy = true);
    try {
      final bytes = await buildGdnGrnPdf(vm: vm);
      final base = vm.documentNumber.isNotEmpty ? vm.documentNumber : vm.publicId;
      final safe = base.replaceAll(RegExp(r'[^\w\-]+'), '_');
      final filename = '${safe.isEmpty ? 'document' : safe}.pdf';

      final dir = await _getDownloadDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        _messengerKey.currentState
          ?..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Successfully saved to Downloads folder.\n$filename',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        _messengerKey.currentState
          ?..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(userFacingMessage(e)),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext;
    }
    return await getApplicationDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.jms();
    final vm = _vm;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.backgroundWarm,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (vm?.documentNumber ??
                                              widget.documentRef.documentNumber ??
                                              '—')
                                          .toString(),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                    if (vm != null)
                                      Text(
                                        widget.dateFmt.format(
                                          vm.issuedAt?.toLocal() ??
                                              widget.documentRef.availableAt.toLocal(),
                                        ),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textTertiary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  vm?.issuedAt != null
                                      ? timeFmt.format(vm!.issuedAt!.toLocal())
                                      : timeFmt.format(widget.documentRef.availableAt.toLocal()),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surfaceMuted,
                                  foregroundColor: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          if (vm != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _DocInfoCard(
                                          title: context.l10n.consignor,
                                          lines: [
                                            vm.consignorName,
                                            if (vm.consignorPhone.isNotEmpty) vm.consignorPhone,
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _DocInfoCard(
                                          title: context.l10n.consignee,
                                          lines: [
                                            vm.consigneeName,
                                            if (vm.consigneePhone.isNotEmpty) vm.consigneePhone,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _DocInfoCard(
                                          title: context.l10n.driver,
                                          lines: [
                                            if (vm.driverName.isNotEmpty) vm.driverName else '—',
                                            if (vm.driverId.isNotEmpty) 'ID: ${vm.driverId}',
                                            if (vm.licenseNumber.isNotEmpty)
                                              'License: ${vm.licenseNumber}',
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _DocInfoCard(
                                          title: context.l10n.vehicle,
                                          lines: [
                                            if (vm.vehicleType.isNotEmpty)
                                              'Type: ${vm.vehicleType}'
                                            else
                                              '—',
                                            if (vm.plateNumber.isNotEmpty)
                                              'Plate: ${vm.plateNumber}',
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Goods Details',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _GoodsTable(rows: vm.goodsTableRows()),
                                  if (vm.type == 'GRN' && vm.grnExtraSummary().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      vm.grnExtraSummary(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _LocationBlock(
                                          label: context.l10n.loadingLocation,
                                          value: vm.loadingLocation,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _LocationBlock(
                                          label: context.l10n.offloadingLocation,
                                          value: vm.offloadingLocation,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Remarks',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    vm.remarks.isNotEmpty ? vm.remarks : '—',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  if (vm.qrCodeValue.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Center(
                                      child: QrImageView(
                                        data: vm.qrCodeValue,
                                        version: QrVersions.auto,
                                        size: 140,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Scan to verify document authenticity',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: (_loading || vm == null || _pdfBusy) ? null : _downloadPdf,
                      icon: _pdfBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _pdfBusy ? 'Preparing…' : 'Download PDF',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }
}

class _DocInfoCard extends StatelessWidget {
  const _DocInfoCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final filtered = lines.where((s) => s.trim().isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Text(
              '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else
            ...filtered.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isNotEmpty ? value : '—',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _GoodsTable extends StatelessWidget {
  const _GoodsTable({required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final data = rows.isEmpty
        ? [
            ['—', '—', '—', '—', '—'],
          ]
        : rows;
    final headers = ['Type', context.l10n.quantity, context.l10n.weight, context.l10n.volume, 'Packaging'];
    return Table(
      border: TableBorder.all(color: AppColors.borderLight, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.1),
        2: FlexColumnWidth(1.1),
        3: FlexColumnWidth(1.1),
        4: FlexColumnWidth(1.4),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
          children: headers
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text(
                    h,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              )
              .toList(),
        ),
        ...data.map(
          (r) => TableRow(
            children: r
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      c.isEmpty ? '—' : c,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
