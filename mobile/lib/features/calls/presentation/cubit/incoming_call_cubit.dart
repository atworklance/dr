import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/call_signal_event.dart';
import '../../domain/entities/incoming_call.dart';
import '../../domain/repositories/call_signaling_repository.dart';

part 'incoming_call_state.dart';

/// Listens for incoming consultation calls across the provider's confirmed
/// appointments and exposes the currently ringing call. Acceptance/navigation
/// is handled by the host; this controller only manages signalling state.
class IncomingCallCubit extends Cubit<IncomingCallState> {
  IncomingCallCubit({
    required CallSignalingRepository repository,
    required String currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        super(const IncomingCallState());

  final CallSignalingRepository _repository;
  final String _currentUserId;

  StreamSubscription<CallSignalEvent>? _subscription;

  Future<void> initialize() async {
    _subscription = _repository.events.listen(_onEvent);
    try {
      await _repository.connect(_currentUserId);
      final appointments = await _repository.fetchWatchableAppointments();
      await _repository.watch(appointments);
    } catch (_) {
      // Signalling is best-effort; absence of it simply means no live alerts.
    }
  }

  void _onEvent(CallSignalEvent event) {
    if (isClosed) return;
    switch (event) {
      case IncomingCallReceived(:final call):
        // Ignore self-initiated and keep the first active call if one is ringing.
        if (call.callerId == _currentUserId || state.isRinging) return;
        emit(state.copyWith(current: call));
      case CallCancelled():
        if (state.isRinging) emit(state.copyWith(clearCurrent: true));
      case CallSignalConnection(:final connected):
        emit(state.copyWith(isConnected: connected));
    }
  }

  /// Clears the ringing call (after accept/decline).
  void dismiss() => emit(state.copyWith(clearCurrent: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _repository.dispose();
    return super.close();
  }
}
