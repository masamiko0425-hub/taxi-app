import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

/// 予約の作成・監視・位置情報の共有をまとめたサービス。
/// GPSは常時送信せず、乗車予定時刻の前後だけ書き込む設計にしている。
class ReservationService {
  final _db = FirebaseFirestore.instance;

  /// 乗車予定時刻の何分前から位置共有を開始するか
  static const trackingStartMinutesBefore = 15;

  CollectionReference<Map<String, dynamic>> get _reservations =>
      _db.collection('reservations');

  Future<String> createReservation({
    required String customerId,
    required DateTime pickupDatetime,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final reservation = Reservation(
      id: '',
      customerId: customerId,
      pickupDatetime: pickupDatetime,
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffAddress: dropoffAddress,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      status: ReservationStatus.pending,
    );
    final docRef = await _reservations.add(reservation.toMap(customerIdValue: customerId));
    return docRef.id;
  }

  /// 予約1件をリアルタイム監視（ステータス変化やドライバー割当を検知）
  Stream<Reservation> watchReservation(String reservationId) {
    return _reservations
        .doc(reservationId)
        .snapshots()
        .where((doc) => doc.exists)
        .map((doc) => Reservation.fromDoc(doc));
  }

  /// 乗車予定時刻が近づいたら status を tracking に更新する判定
  bool shouldStartTracking(DateTime pickupDatetime) {
    final diff = pickupDatetime.difference(DateTime.now()).inMinutes;
    return diff <= trackingStartMinutesBefore && diff >= -60;
  }

  Future<void> updateStatus(String reservationId, ReservationStatus status) {
    return _reservations.doc(reservationId).update({
      'status': statusToString(status),
    });
  }

  /// 顧客側の現在地を送信する（trackingステータスの間だけ呼び出す想定）
  Future<void> updateCustomerLocation({
    required String reservationId,
    required double lat,
    required double lng,
  }) {
    return _reservations
        .doc(reservationId)
        .collection('customer_location')
        .doc('current')
        .set({
      'lat': lat,
      'lng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ドライバー側が顧客の位置をリアルタイムで受け取る
  Stream<Map<String, double>?> watchCustomerLocation(String reservationId) {
    return _reservations
        .doc(reservationId)
        .collection('customer_location')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return {
        'lat': (data['lat'] as num).toDouble(),
        'lng': (data['lng'] as num).toDouble(),
      };
    });
  }
}
