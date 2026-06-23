part of 'incoming_call_cubit.dart';

class IncomingCallState extends Equatable {
  const IncomingCallState({this.current, this.isConnected = false});

  final IncomingCall? current;
  final bool isConnected;

  bool get isRinging => current != null;

  IncomingCallState copyWith({
    IncomingCall? current,
    bool? isConnected,
    bool clearCurrent = false,
  }) {
    return IncomingCallState(
      current: clearCurrent ? null : (current ?? this.current),
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [current, isConnected];
}
