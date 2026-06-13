/// Picks the first non-empty string from [map] using [keys] in order.
String gdnGrnPickString(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return '';
}

DateTime? gdnGrnPickDate(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    final t = DateTime.tryParse(v.toString());
    if (t != null) return t;
  }
  return null;
}

/// Linked GDN verification QR on GRN payloads (origin reference).
String gdnGrnPickOriginGdnQrCode(Map<String, dynamic> map) {
  final direct = gdnGrnPickString(map, const [
    'gdnUrl',
    'gdn_url',
    'originGdnQrCodeValue',
    'origin_gdn_qr_code_value',
    'gdnQrCodeValue',
    'gdn_qr_code_value',
    'originQrCodeValue',
    'origin_qr_code_value',
    'gdnVerificationUrl',
    'gdnVerifyUrl',
    'linkedGdnQrCodeValue',
    'linked_gdn_qr_code_value',
  ]);
  if (direct.isNotEmpty) return direct;

  for (final key in [
    'gdn',
    'linkedGdn',
    'originGdn',
    'gdnDocument',
    'sourceGdn',
  ]) {
    final v = map[key];
    if (v is! Map) continue;
    final nested = gdnGrnPickString(Map<String, dynamic>.from(v), const [
      'gdnUrl',
      'gdn_url',
      'qrCodeValue',
      'qr_code_value',
      'verificationUrl',
      'verifyUrl',
    ]);
    if (nested.isNotEmpty) return nested;
  }
  return '';
}

/// Normalized view of a GDN/GRN API payload for UI and PDF.
class GdnGrnDocumentViewModel {
  GdnGrnDocumentViewModel._({
    required this.raw,
    required this.type,
  })  : documentNumber = gdnGrnPickString(raw, const [
          'documentNumber',
          'document_no',
          'documentNo',
        ]),
        issuedAt = gdnGrnPickDate(raw, const [
          'issuedAt',
          'issued_at',
          'createdAt',
          'created_at',
          'receivedAt',
          'received_at',
        ]),
        issuedBy = gdnGrnPickString(raw, const [
          'issuersName',
          'issuerName',
          'issuedBy',
          'issued_by',
          'createdBy',
          'created_by',
        ]),
        consignorName = gdnGrnPickString(raw, const [
          'consignorName',
          'consignor_name',
          'shipperName',
          'issuersName',
          'issuerName',
        ]),
        consignorPhone = gdnGrnPickString(raw, const [
          'consignorPhone',
          'consignor_phone',
          'consignorContact',
          'shipperPhone',
          'shipper_phone',
        ]),
        consigneeName = gdnGrnPickString(raw, const [
          'consigneeName',
          'consignee_name',
          'receiverName',
          'receiver_name',
        ]),
        consigneePhone = gdnGrnPickString(raw, const [
          'consigneeContact',
          'consignee_contact',
          'consigneePhone',
          'receiverPhone',
          'receiver_phone',
        ]),
        driverName = gdnGrnPickString(raw, const [
          'driverName',
          'driver_name',
          'assignedDriverName',
        ]),
        driverId = gdnGrnPickString(raw, const [
          'driverId',
          'driver_id',
          'driverPublicId',
          'nationalId',
          'national_id',
        ]),
        licenseNumber = gdnGrnPickString(raw, const [
          'driverLicenseNo',
          'driver_license_no',
          'licenseNumber',
          'license_number',
          'driverLicense',
          'driver_license',
          'driversLicense',
          'drivers_license',
        ]),
        vehicleType = gdnGrnPickString(raw, const [
          'vehicleType',
          'vehicle_type',
          'vehicleLabel',
        ]),
        plateNumber = gdnGrnPickString(raw, const [
          'vehiclePlateNo',
          'vehicle_plate_no',
          'plateNumber',
          'plate_number',
          'vehiclePlate',
          'vehicle_plate',
          'registrationNumber',
          'registration_number',
          'plate',
        ]),
        loadingLocation = gdnGrnPickString(raw, const [
          'loadingLocation',
          'loading_location',
          'loadingAddress',
          'pickupAddress',
          'origin',
        ]),
        offloadingLocation = gdnGrnPickString(raw, const [
          'offloadingLocation',
          'offloading_location',
          'offloadingAddress',
          'dropoffAddress',
          'destination',
        ]),
        remarks = gdnGrnPickString(raw, const [
          'remarks',
          'remark',
          'notes',
        ]),
        qrCodeValue = gdnGrnPickString(raw, const [
          'grnQrCodeValue',
          'grn_qr_code_value',
          'validateQrCodeValue',
          'validate_qr_code_value',
          'validationQrCodeValue',
          'validation_qr_code_value',
          'qrCodeValue',
          'qr_code_value',
          'verificationUrl',
          'verifyUrl',
        ]),
        originGdnQrCodeValue = gdnGrnPickString(raw, const [
          'gdnUrl',
          'gdn_url',
          'originGdnQrCodeValue',
          'origin_gdn_qr_code_value',
          'gdnQrCodeValue',
          'gdn_qr_code_value',
          'originQrCodeValue',
          'origin_qr_code_value',
          'gdnVerificationUrl',
          'gdnVerifyUrl',
          'linkedGdnQrCodeValue',
          'linked_gdn_qr_code_value',
        ]),
        status = gdnGrnPickString(raw, const ['status']),
        publicId = gdnGrnPickString(raw, const ['publicId', 'public_id', 'id']);

  factory GdnGrnDocumentViewModel.from(Map<String, dynamic> raw, String type) {
    final merged = Map<String, dynamic>.from(raw);
    void liftIfEmpty(String key, dynamic value) {
      if (value == null) return;
      final cur = merged[key];
      if (cur == null || cur.toString().trim().isEmpty) {
        merged[key] = value;
      }
    }

    void mergeMap(dynamic nested) {
      if (nested is! Map) return;
      final m = Map<String, dynamic>.from(nested);
      for (final e in m.entries) {
        liftIfEmpty(e.key, e.value);
      }
    }

    mergeMap(merged['assignment']);
    mergeMap(merged['shipment']);

    // Nested driver / vehicle objects (common when assignment details are grouped).
    for (final key in ['driver', 'assignedDriver', 'driverDetails', 'driverInfo']) {
      final v = merged[key];
      if (v is! Map) continue;
      final d = Map<String, dynamic>.from(v);
      final name = gdnGrnPickString(d, const [
        'driverName',
        'driver_name',
        'name',
        'fullName',
        'full_name',
      ]);
      if (name.isNotEmpty) liftIfEmpty('driverName', name);
      final lic = gdnGrnPickString(d, const [
        'driverLicenseNo',
        'driver_license_no',
        'licenseNumber',
        'license_number',
        'driverLicense',
        'driver_license',
      ]);
      if (lic.isNotEmpty) liftIfEmpty('driverLicenseNo', lic);
      final nid = gdnGrnPickString(d, const [
        'driverId',
        'driver_id',
        'nationalId',
        'national_id',
        'publicId',
        'public_id',
      ]);
      if (nid.isNotEmpty) liftIfEmpty('driverId', nid);
    }
    for (final key in ['vehicle', 'assignedVehicle', 'vehicleDetails', 'vehicleInfo']) {
      final v = merged[key];
      if (v is! Map) continue;
      final m = Map<String, dynamic>.from(v);
      final vType = gdnGrnPickString(m, const [
        'vehicleType',
        'vehicle_type',
        'type',
        'label',
      ]);
      if (vType.isNotEmpty) liftIfEmpty('vehicleType', vType);
      final plate = gdnGrnPickString(m, const [
        'vehiclePlateNo',
        'vehicle_plate_no',
        'plateNumber',
        'plate_number',
        'vehiclePlate',
        'vehicle_plate',
        'plate',
      ]);
      if (plate.isNotEmpty) liftIfEmpty('vehiclePlateNo', plate);
    }

    if (type == 'GRN') {
      final originQr = gdnGrnPickOriginGdnQrCode(merged);
      if (originQr.isNotEmpty) {
        liftIfEmpty('originGdnQrCodeValue', originQr);
      }
    }

    return GdnGrnDocumentViewModel._(raw: merged, type: type);
  }

  final Map<String, dynamic> raw;
  final String type;

  final String documentNumber;
  final DateTime? issuedAt;
  final String issuedBy;
  final String consignorName;
  final String consignorPhone;
  final String consigneeName;
  final String consigneePhone;
  final String driverName;
  final String driverId;
  final String licenseNumber;
  final String vehicleType;
  final String plateNumber;
  final String loadingLocation;
  final String offloadingLocation;
  final String remarks;
  final String qrCodeValue;
  final String originGdnQrCodeValue;
  final String status;
  final String publicId;

  String get pdfTitle =>
      type == 'GDN' ? 'GOOD DELIVERY NOTE (GDN)' : 'GOOD RECEIPT NOTE (GRN)';

  List<List<String>> goodsTableRows() {
    final items = raw['items'] ??
        raw['goodsLines'] ??
        raw['lineItems'] ??
        raw['goodsItems'];
    if (items is List && items.isNotEmpty) {
      final out = <List<String>>[];
      for (final e in items) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        out.add(_rowFromMap(m));
      }
      if (out.isNotEmpty) return out;
    }
    if (type == 'GRN') {
      return [
        [
          gdnGrnPickString(raw, const [
            'goodsDescription',
            'goods_description',
            'description',
          ]),
          gdnGrnPickString(raw, const [
            'receivedQuantity',
            'received_quantity',
            'quantity',
          ]),
          gdnGrnPickString(raw, const [
            'receivedWeight',
            'received_weight',
            'weight',
          ]),
          gdnGrnPickString(raw, const [
            'receivedVolume',
            'received_volume',
            'volume',
          ]),
          gdnGrnPickString(raw, const [
            'conditionNote',
            'condition_note',
            'packagingType',
            'packaging_type',
          ]),
        ],
      ];
    }
    return [
      [
        gdnGrnPickString(raw, const [
          'goodsDescription',
          'goods_description',
          'goodsType',
          'type',
        ]),
        gdnGrnPickString(raw, const ['quantity', 'qty']),
        gdnGrnPickString(raw, const ['weight']),
        gdnGrnPickString(raw, const ['volume']),
        gdnGrnPickString(raw, const [
          'packagingType',
          'packaging_type',
          'packaging',
        ]),
      ],
    ];
  }

  List<String> _rowFromMap(Map<String, dynamic> m) {
    return [
      gdnGrnPickString(m, const [
        'type',
        'goodsType',
        'description',
        'goodsDescription',
      ]),
      gdnGrnPickString(m, const ['quantity', 'qty']),
      gdnGrnPickString(m, const ['weight']),
      gdnGrnPickString(m, const ['volume']),
      gdnGrnPickString(m, const [
        'packagingType',
        'packaging',
        'packaging_type',
      ]),
    ];
  }

  String grnExtraSummary() {
    if (type != 'GRN') return '';
    final d = gdnGrnPickString(raw, const ['damageQuantity', 'damage_quantity']);
    final s = gdnGrnPickString(raw, const ['shortageQuantity', 'shortage_quantity']);
    final parts = <String>[];
    if (d.isNotEmpty) parts.add('Damage qty: $d');
    if (s.isNotEmpty) parts.add('Shortage qty: $s');
    return parts.join(' · ');
  }
}
