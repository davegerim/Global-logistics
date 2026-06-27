import 'package:flutter_test/flutter_test.dart';
import 'package:global_logistics_app/core/tracking/tracking_policy.dart';

void main() {
  group('canRunDriverTrackingLoop', () {
    test('requires GDN even for live statuses', () {
      expect(canRunDriverTrackingLoop('IN_TRANSIT', hasGdn: false), isFalse);
      expect(canRunDriverTrackingLoop('ARRIVED', hasGdn: false), isFalse);
    });

    test('allows all post-GDN movement statuses when GDN exists', () {
      expect(canRunDriverTrackingLoop('LOADED', hasGdn: true), isTrue);
      expect(canRunDriverTrackingLoop('IN_TRANSIT', hasGdn: true), isTrue);
      expect(canRunDriverTrackingLoop('ARRIVED', hasGdn: true), isTrue);
      expect(canRunDriverTrackingLoop('OFFLOADED', hasGdn: true), isTrue);
      expect(canRunDriverTrackingLoop('COMPLETED', hasGdn: true), isFalse);
      expect(canRunDriverTrackingLoop('CANCELLED', hasGdn: true), isFalse);
    });
  });

  group('canSendDriverTrackingUpdate', () {
    test('blocks updates without GDN', () {
      expect(canSendDriverTrackingUpdate('LOADED', hasGdn: false), isFalse);
      expect(canSendDriverTrackingUpdate('IN_TRANSIT', hasGdn: false), isFalse);
    });

    test('blocks terminal statuses even with GDN', () {
      expect(canSendDriverTrackingUpdate('COMPLETED', hasGdn: true), isFalse);
      expect(canSendDriverTrackingUpdate('CANCELLED', hasGdn: true), isFalse);
      expect(
        canSendDriverTrackingUpdate('CANCELLED_BY_CONSIGNOR', hasGdn: true),
        isFalse,
      );
      expect(
        canSendDriverTrackingUpdate('CONSIGNOR_RECEIVED', hasGdn: true),
        isFalse,
      );
    });

    test('allows non-terminal post-GDN movement updates', () {
      expect(canSendDriverTrackingUpdate('LOADED', hasGdn: true), isTrue);
      expect(canSendDriverTrackingUpdate('IN_TRANSIT', hasGdn: true), isTrue);
      expect(canSendDriverTrackingUpdate('ARRIVED', hasGdn: true), isTrue);
      expect(canSendDriverTrackingUpdate('OFFLOADED', hasGdn: true), isTrue);
    });
  });
}
