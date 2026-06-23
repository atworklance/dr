import '../entities/call_signal_event.dart';
import '../entities/watchable_appointment.dart';

/// Domain contract for receiving incoming consultation calls. The implementation
/// joins the provider's confirmed appointment rooms over the realtime socket and
/// streams [CallSignalEvent]s.
abstract interface class CallSignalingRepository {
  Stream<CallSignalEvent> get events;

  /// Loads the confirmed appointments whose rooms should be watched.
  Future<List<WatchableAppointment>> fetchWatchableAppointments();

  /// Connects the signalling socket as [currentUserId].
  Future<void> connect(String currentUserId);

  /// Joins the rooms for the given appointments.
  Future<void> watch(List<WatchableAppointment> appointments);

  /// Tears down the connection.
  Future<void> dispose();
}
