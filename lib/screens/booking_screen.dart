import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/reservation_service.dart';
import 'tracking_screen.dart';

class BookingScreen extends StatefulWidget {
  final String customerId;
  const BookingScreen({super.key, required this.customerId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _service = ReservationService();
  final _pickupController = TextEditingController(text: '札幌駅 北口');
  final _dropoffController = TextEditingController(text: '大通公園');

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 30);
  bool _submitting = false;

  final _timeSlots = const [
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 14, minute: 30),
    TimeOfDay(hour: 15, minute: 0),
  ];

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final pickupDatetime = DateTime(
      _selectedDay.year,
