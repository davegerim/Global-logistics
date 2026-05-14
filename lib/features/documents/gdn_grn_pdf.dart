import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:global_logistics_app/features/documents/gdn_grn_document_view_model.dart';
import 'package:global_logistics_app/features/documents/gdn_grn_pdf_worker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Uint8List _byteDataToUint8Copy(ByteData d) {
  return Uint8List.fromList(
    d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes),
  );
}

/// Cached font/logo bytes so we only load them once per app session.
Uint8List? _cachedRegularTtf;
Uint8List? _cachedBoldTtf;
Uint8List? _cachedLogoPng;

Future<void> _ensureAssetsLoaded() async {
  if (_cachedLogoPng == null) {
    final logoData = await rootBundle.load('assets/images/gl_logo.png');
    _cachedLogoPng = Uint8List.fromList(logoData.buffer.asUint8List());
  }
  if (_cachedRegularTtf == null || _cachedBoldTtf == null) {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    if (regularFont is pw.TtfFont && boldFont is pw.TtfFont) {
      _cachedRegularTtf = _byteDataToUint8Copy(regularFont.data);
      _cachedBoldTtf = _byteDataToUint8Copy(boldFont.data);
    } else {
      _cachedRegularTtf = Uint8List(0);
      _cachedBoldTtf = Uint8List(0);
    }
  }
}

/// Loads Noto Sans (Unicode) and the logo on the main isolate, then builds the PDF on a worker isolate.
/// Fonts and logo are cached after the first call so subsequent builds are near-instant.
Future<Uint8List> buildGdnGrnPdf({
  required GdnGrnDocumentViewModel vm,
}) async {
  await _ensureAssetsLoaded();

  final work = GdnGrnPdfWork(
    regularTtf: _cachedRegularTtf!,
    boldTtf: _cachedBoldTtf!,
    logoPng: _cachedLogoPng!,
    raw: Map<String, dynamic>.from(vm.raw),
    type: vm.type,
  );

  return Isolate.run(() async => gdnGrnPdfBuildFromWork(work));
}
