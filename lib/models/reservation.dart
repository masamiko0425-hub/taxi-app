import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus { pending, assigned, tracking, inProgress, completed, cancelled }

ReservationStatus statusFromString(String value) {
  switch (value) {
    case 'assigned':
      return ReservationStatus.assigned;
    case 'tracking':
      return ReservationStatus.tracking;
    case 'in_progress':
      return ReservationStatus.inProgress;
    case 'completed':
      return ReservationStatus.completed;
    case 'cancelled':
      return ReservationStatus.cancelled;
    default:
      return ReservationStatus.pending;
  }
}

String statusToString(ReservationStatus status) {
  switch (status) {
    case ReservationStatus.assigned:
      return 'assigned';
    case ReservationStatus.tracking:
      return 'tracking';
    case ReservationStatus.inProgress:
      return 'in_progress';
    case ReservationStatus.completed:
      return 'completed';
    case ReservationStatus.cancelled:
      return 'cancelled';
    case ReservationStatus.pending:
      return 'pending';
  }
}

class Reservation {
  final String id;
  final String customerId;
  final String? driverId;
  final DateTime pickupDatetime;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final ReservationStatus status;

  Reservation({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.pickupDatetime,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.status,
  });

  factory Reservation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Reservation(
      id: doc.id,
      customerId: data['customerId'] as String,
      driverId: data['driverId'] as String?,
      pickupDatetime: (data['pickupDatetime'] as Timestamp).toDate(),
      pickupAddress: data['pickupAddress'] as String,
      pickupLat: (data['pickupLat'] as num).toDouble(),
      pickupLng: (data['pickupLng'] as num).toDouble(),
      dropoffAddress: data['dropoffAddress'] as String,
      dropoffLat: (data['dropoffLat'] as num).toDouble(),
      dropoffLng: (data['dropoffLng'] as num).toDouble(),
      status: statusFromString(data['status'] as String),
    );
  }

  Map<String, dynamic> toMap({required String customerIdValue}) {
    return {
      'customerId': customerIdValue,
      'driverId': driverId,
      'pickupDatetime': Timestamp.fromDate(pickupDatetime),
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffAddress': dropoffAddress,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'status': statusToString(status),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
