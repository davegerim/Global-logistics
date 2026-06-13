import 'dart:typed_data';

import 'package:global_logistics_app/features/documents/gdn_grn_document_view_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Serializable payload for [gdnGrnPdfBuildFromWork] (background isolate).
class GdnGrnPdfWork {
  const GdnGrnPdfWork({
    required this.regularTtf,
    required this.boldTtf,
    required this.logoPng,
    required this.raw,
    required this.type,
  });

  final Uint8List regularTtf;
  final Uint8List boldTtf;
  final Uint8List logoPng;
  final Map<String, dynamic> raw;
  final String type;
}

const _kCompany = 'Global Logistics PLC';
const _kAddress = 'Addis Ababa, Ethiopia';
const _kPhone = '+251 94 660 8888';

final _kBorder = PdfColor.fromHex('E5E7EB');
final _kHeaderFill = PdfColor.fromHex('F3F4F6');
final _kBrand = PdfColor.fromHex('0E4A42');

/// Builds PDF bytes off the UI isolate. Uses only `pdf` + view model (no Flutter / plugins).
Future<Uint8List> gdnGrnPdfBuildFromWork(GdnGrnPdfWork work) async {
  final vm = GdnGrnDocumentViewModel.from(work.raw, work.type);
  final pw.ThemeData? theme;
  if (work.regularTtf.isEmpty || work.boldTtf.isEmpty) {
    theme = null;
  } else {
    final baseFont = pw.Font.ttf(ByteData.sublistView(work.regularTtf));
    final boldFont = pw.Font.ttf(ByteData.sublistView(work.boldTtf));
    theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      fontFallback: [baseFont],
    );
  }

  final logo = pw.MemoryImage(work.logoPng);

  final issuedStr = vm.issuedAt != null
      ? '${vm.issuedAt!.toLocal()}'.split('.').first
      : '—';
  final docNo = vm.documentNumber.isNotEmpty ? vm.documentNumber : vm.publicId;
  final issuedBy = vm.issuedBy.isNotEmpty ? vm.issuedBy : '—';
  var rows = vm.goodsTableRows();
  if (rows.isEmpty) {
    rows = [
      ['—', '—', '—', '—', '—'],
    ];
  }

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: theme,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 52,
                  height: 52,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _kCompany,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _kBrand,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(_kAddress, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(_kPhone, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: _kBorder, thickness: 0.8),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                vm.pdfTitle,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _metaBlock('Document No', docNo.isNotEmpty ? docNo : '—'),
                ),
                pw.Expanded(
                  child: _metaBlock('Issued At', issuedStr),
                ),
                pw.Expanded(
                  child: _metaBlock('Issued By', issuedBy),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _card('Consignor', vm.consignorName, vm.consignorPhone)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _card('Consignee', vm.consigneeName, vm.consigneePhone)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _cardDriverVehicle(
                    'Driver',
                    vm.driverName,
                    idLine: vm.driverId.isNotEmpty ? 'ID: ${vm.driverId}' : null,
                    extra: vm.licenseNumber.isNotEmpty
                        ? 'License: ${vm.licenseNumber}'
                        : null,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _cardDriverVehicle(
                    'Vehicle',
                    vm.vehicleType.isNotEmpty
                        ? 'Type: ${vm.vehicleType}'
                        : '—',
                    extra: vm.plateNumber.isNotEmpty ? 'Plate: ${vm.plateNumber}' : null,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Goods Details',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: _kBorder, width: 0.6),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.6),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _kHeaderFill),
                  children: ['Type', 'Quantity', 'Weight', 'Volume', 'Packaging']
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...rows.map(
                  (r) => pw.TableRow(
                    children: r
                        .map(
                          (c) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              c.isEmpty ? '—' : c,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            if (vm.type == 'GRN' && vm.grnExtraSummary().isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(vm.grnExtraSummary(), style: const pw.TextStyle(fontSize: 9)),
            ],
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _locBlock('Loading Location', vm.loadingLocation),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _locBlock('Offloading Location', vm.offloadingLocation),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Remarks',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              vm.remarks.isNotEmpty ? vm.remarks : ' ',
              style: const pw.TextStyle(fontSize: 9),
            ),
            if (vm.type == 'GRN' &&
                (vm.originGdnQrCodeValue.isNotEmpty ||
                    vm.qrCodeValue.isNotEmpty)) ...[
              pw.SizedBox(height: 14),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (vm.originGdnQrCodeValue.isNotEmpty)
                    pw.Expanded(
                      child: _qrVerificationBlock(
                        heading: 'ORIGIN REFERENCE',
                        title: 'Scan to View Original GDN',
                        subtitle: 'Compare loaded vs received data digitally.',
                        data: vm.originGdnQrCodeValue,
                      ),
                    ),
                  if (vm.originGdnQrCodeValue.isNotEmpty &&
                      vm.qrCodeValue.isNotEmpty)
                    pw.SizedBox(width: 12),
                  if (vm.qrCodeValue.isNotEmpty)
                    pw.Expanded(
                      child: _qrVerificationBlock(
                        heading: 'GRN VERIFICATION',
                        title: 'Document Authenticity',
                        subtitle: 'Official proof of cargo receipt at destination.',
                        data: vm.qrCodeValue,
                      ),
                    ),
                ],
              ),
            ] else if (vm.qrCodeValue.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: vm.qrCodeValue,
                  width: 96,
                  height: 96,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Scan to verify document authenticity',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
  return await doc.save(  );
}

pw.Widget _qrVerificationBlock({
  required String heading,
  required String title,
  required String subtitle,
  required String data,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _kBorder, width: 0.7),
      borderRadius: pw.BorderRadius.circular(6),
      color: PdfColor.fromHex('F9FAFB'),
    ),
    child: pw.Column(
      children: [
        pw.Text(
          heading,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
            letterSpacing: 0.4,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: data,
            width: 84,
            height: 84,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: heading == 'ORIGIN REFERENCE'
                ? PdfColor.fromHex('2563EB')
                : PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
      ],
    ),
  );
}

pw.Widget _metaBlock(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    ],
  );
}

pw.Widget _locBlock(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        value.isNotEmpty ? value : '—',
        style: const pw.TextStyle(fontSize: 9),
      ),
    ],
  );
}

pw.Widget _card(String title, String name, String phone) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _kBorder, width: 0.7),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          name.isNotEmpty ? name : '—',
          style: const pw.TextStyle(fontSize: 9),
        ),
        if (phone.isNotEmpty) pw.Text(phone, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );
}

pw.Widget _cardDriverVehicle(
  String title,
  String firstLine, {
  String? idLine,
  String? extra,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _kBorder, width: 0.7),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(firstLine, style: const pw.TextStyle(fontSize: 9)),
        if (idLine != null) pw.Text(idLine, style: const pw.TextStyle(fontSize: 9)),
        if (extra != null) pw.Text(extra, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );
}
