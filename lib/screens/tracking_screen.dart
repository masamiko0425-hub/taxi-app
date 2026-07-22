import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';

class TrackingScreen extends StatefulWidget {
  final String reservationId;
  const TrackingScreen({super.key, required this.reservationId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _service = ReservationService();
  StreamSubscription<Position>? _positionSub;
  bool _isSharingLocation = false;

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  /// 予約が tracking ステータスになったら位置情報の送信を開始する。
  /// 常時取得は行わず、このタイミングだけ Geolocator のストリームを購読する。
  Future<void> _startSharingIfNeeded(Reservation reservation) async {
    if (_isSharingLocation) return;
    if (reservation.status != ReservationStatus.tracking) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) return;
    }

    _isSharingLocation = true;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // 20m移動するごとに更新（バッテリー配慮）
      ),
    ).listen((position) {
      _service.updateCustomerLocation(
        reservationId: widget.reservationId,
        lat: position.latitude,
        lng: position.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('まもなくお迎え')),
      body: StreamBuilder<Reservation>(
        stream: _service.watchReservation(widget.reservationId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reservation = snapshot.data!;
          _startSharingIfNeeded(reservation);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ステータス: ${statusToString(reservation.status)}'),
                    Text(DateFormat('HH:mm').format(reservation.pickupDatetime)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<Map<String, double>?>(
                  stream: _service.watchCustomerLocation(widget.reservationId),
                  builder: (context, locSnapshot) {
                    final customerLoc = locSnapshot.data;
                    final markers = <Marker>{
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: LatLng(reservation.pickupLat, reservation.pickupLng),
                        infoWindow: const InfoWindow(title: '乗車地点'),
                      ),
                      if (customerLoc != null)
                        Marker(
                          markerId: const MarkerId('customer'),
                          position: LatLng(customerLoc['lat']!, customerLoc['lng']!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                          infoWindow: const InfoWindow(title: 'お客様'),
                        ),
                    };
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(reservation.pickupLat, reservation.pickupLng),
                        zoom: 15,
                      ),
                      markers: markers,
                    );
                  },
                ),
              ),
              if (reservation.status == ReservationStatus.tracking)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('お客様の位置情報を共有中', style: TextStyle(color: Colors.green)),
                ),
            ],
          );
        },
      ),
    );
  }
}
