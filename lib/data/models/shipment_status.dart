enum ShipmentStatus {
  pendingReview,
  awaitingDriver,
  driverAssigned,
  gdnIssued,
  loading,
  inTransit,
  atDestination,
  offloading,
  delivered,
  completed,
  cancelled,
}

extension ShipmentStatusX on ShipmentStatus {
  String get label => switch (this) {
        ShipmentStatus.pendingReview => 'Pending review',
        ShipmentStatus.awaitingDriver => 'Awaiting driver',
        ShipmentStatus.driverAssigned => 'Driver assigned',
        ShipmentStatus.gdnIssued => 'GDN issued',
        ShipmentStatus.loading => 'Loading',
        ShipmentStatus.inTransit => 'In transit',
        ShipmentStatus.atDestination => 'At destination',
        ShipmentStatus.offloading => 'Offloading',
        ShipmentStatus.delivered => 'Delivered',
        ShipmentStatus.completed => 'Completed',
        ShipmentStatus.cancelled => 'Cancelled',
      };
}
