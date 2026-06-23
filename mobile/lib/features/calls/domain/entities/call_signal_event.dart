import 'incoming_call.dart';

/// Events emitted by the call-signalling transport.
sealed class CallSignalEvent {
  const CallSignalEvent();
}

/// A participant started a call in a watched appointment room.
class IncomingCallReceived extends CallSignalEvent {
  const IncomingCallReceived(this.call);
  final IncomingCall call;
}

/// The active call was ended/cancelled by the other side.
class CallCancelled extends CallSignalEvent {
  const CallCancelled();
}

/// The signalling socket connection state changed.
class CallSignalConnection extends CallSignalEvent {
  const CallSignalConnection({required this.connected});
  final bool connected;
}
