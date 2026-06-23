import 'package:equatable/equatable.dart';

import '../../../../core/entities/consultation_mode.dart';
import 'appointment_status.dart';
import 'payment_status.dart';

/// A booked appointment between a client and a specialist, including the
/// real-time session handles (chat room + video channel) provisioned by the
/// backend at creation time.
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.mode,
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.status,
    required this.paymentStatus,
    required this.priceAmount,
    required this.priceCurrency,
    required this.commissionAmount,
    required this.createdAt,
    this.chatRoomId,
    this.videoChannelName,
  });

  final String id;
  final String clientId;
  final String providerId;
  final ConsultationMode mode;
  final DateTime start;
  final DateTime end;
  final int durationMinutes;
  final AppointmentStatus status;
  final PaymentStatus paymentStatus;

  /// Price in integer minor currency units.
  final int priceAmount;
  final String priceCurrency;
  final int commissionAmount;

  final DateTime createdAt;
  final String? chatRoomId;
  final String? videoChannelName;

  double get priceMajor => priceAmount / 100;
  bool get requiresPayment => paymentStatus == PaymentStatus.unpaid;
  bool get isUpcoming => status.isActive && end.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        clientId,
        providerId,
        mode,
        start,
        end,
        durationMinutes,
        status,
        paymentStatus,
        priceAmount,
        priceCurrency,
        commissionAmount,
        createdAt,
        chatRoomId,
        videoChannelName,
      ];
}
