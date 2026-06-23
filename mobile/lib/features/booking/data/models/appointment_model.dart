import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/utils/json_mappers.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_status.dart';
import '../../domain/entities/payment_status.dart';

/// Data-layer representation of [Appointment]. Parses the backend Appointment
/// JSON, including the nested time window, price block, and session handles.
class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.clientId,
    required super.providerId,
    required super.mode,
    required super.start,
    required super.end,
    required super.durationMinutes,
    required super.status,
    required super.paymentStatus,
    required super.priceAmount,
    required super.priceCurrency,
    required super.commissionAmount,
    required super.createdAt,
    super.chatRoomId,
    super.videoChannelName,
  });

  factory AppointmentModel.fromJson(DataMap json) {
    final window =
        (json['timeWindow'] as Map?)?.cast<String, dynamic>() ?? const {};
    final price = (json['price'] as Map?)?.cast<String, dynamic>() ?? const {};
    final session =
        (json['session'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AppointmentModel(
      id: (json['id'] ?? json['_id']).toString(),
      clientId: _idOf(json['client']),
      providerId: _idOf(json['provider']),
      mode: ConsultationMode.fromValue(
        json['consultationMode'] as String? ?? 'online',
      ),
      start: dateTimeFromIso(window['start']) ?? DateTime.now(),
      end: dateTimeFromIso(window['end']) ?? DateTime.now(),
      durationMinutes: intFromJson(json['durationMinutes']),
      status: AppointmentStatus.fromValue(
        json['status'] as String? ?? 'pending_payment',
      ),
      paymentStatus: PaymentStatus.fromValue(
        json['paymentStatus'] as String? ?? 'unpaid',
      ),
      priceAmount: intFromJson(price['amount']),
      priceCurrency: price['currency'] as String? ?? 'USD',
      commissionAmount: intFromJson(json['commissionAmount']),
      createdAt: dateTimeFromIso(json['createdAt']) ?? DateTime.now(),
      chatRoomId: session['chatRoomId'] as String?,
      videoChannelName: session['videoChannelName'] as String?,
    );
  }

  static String _idOf(Object? value) {
    if (value is String) return value;
    if (value is Map) return (value['id'] ?? value['_id']).toString();
    return value?.toString() ?? '';
  }
}
