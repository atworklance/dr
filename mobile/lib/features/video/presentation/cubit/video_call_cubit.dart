import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/media_permission_service.dart';
import '../../domain/entities/rtc_credentials.dart';
import '../../domain/usecases/end_video_session.dart';
import '../../domain/usecases/get_video_token.dart';
import '../../domain/usecases/start_video_session.dart';
import '../../data/services/agora_video_service.dart';

part 'video_call_state.dart';

/// Orchestrates a live video consultation: requests permissions, fetches the
/// Agora token, drives the engine lifecycle, and exposes call controls. The
/// underlying [RtcEngine] is surfaced solely so the platform video views can
/// render the local/remote feeds.
class VideoCallCubit extends Cubit<VideoCallState> {
  VideoCallCubit({
    required GetVideoToken getVideoToken,
    required StartVideoSession startVideoSession,
    required EndVideoSession endVideoSession,
    required AgoraVideoService agoraService,
    required MediaPermissionService permissionService,
  })  : _getVideoToken = getVideoToken,
        _startVideoSession = startVideoSession,
        _endVideoSession = endVideoSession,
        _agoraService = agoraService,
        _permissionService = permissionService,
        super(const VideoCallState());

  final GetVideoToken _getVideoToken;
  final StartVideoSession _startVideoSession;
  final EndVideoSession _endVideoSession;
  final AgoraVideoService _agoraService;
  final MediaPermissionService _permissionService;

  String _appointmentId = '';
  bool _sessionStarted = false;
  bool _teardownDone = false;

  /// The initialised engine for rendering the video views.
  RtcEngine get engine => _agoraService.engine;

  /// Entry point: permissions -> token -> engine join.
  Future<void> start(String appointmentId) async {
    _appointmentId = appointmentId;
    emit(const VideoCallState(status: VideoCallStatus.requestingPermissions));

    final permission = await _permissionService.requestCameraAndMicrophone();
    switch (permission) {
      case MediaPermissionResult.denied:
        emit(state.copyWith(status: VideoCallStatus.permissionDenied));
        return;
      case MediaPermissionResult.permanentlyDenied:
        emit(state.copyWith(status: VideoCallStatus.permissionPermanentlyDenied));
        return;
      case MediaPermissionResult.granted:
        break;
    }

    emit(state.copyWith(status: VideoCallStatus.connecting, clearError: true));
    final result = await _getVideoToken(appointmentId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(status: VideoCallStatus.error, errorMessage: failure.message),
      ),
      (credentials) => _connect(credentials),
    );
  }

  Future<void> _connect(RtcCredentials credentials) async {
    try {
      await _agoraService.initialize(
        credentials.appId,
        AgoraEventCallbacks(
          onLocalJoined: _onLocalJoined,
          onRemoteJoined: _onRemoteJoined,
          onRemoteLeft: _onRemoteLeft,
          onError: _onEngineError,
        ),
      );
      await _agoraService.enableVideoPreview();
      emit(state.copyWith(status: VideoCallStatus.waiting, channel: credentials.channel));

      await _agoraService.joinWithUserAccount(
        token: credentials.token,
        channelId: credentials.channel,
        userAccount: credentials.account,
      );

      // Best-effort backend session-start signal; failure must not abort the call.
      await _startVideoSession(_appointmentId);
      _sessionStarted = true;
    } catch (_) {
      emit(state.copyWith(
        status: VideoCallStatus.error,
        errorMessage: 'Could not start the video session. Please try again.',
      ));
    }
  }

  void _onLocalJoined() {
    // The local preview is already shown in the "waiting" state; no transition
    // is required until a remote participant arrives.
  }

  void _onRemoteJoined(int remoteUid) {
    if (isClosed) return;
    emit(state.copyWith(status: VideoCallStatus.connected, remoteUid: remoteUid));
  }

  void _onRemoteLeft(int remoteUid) {
    if (isClosed) return;
    emit(state.copyWith(status: VideoCallStatus.waiting, clearRemoteUid: true));
  }

  void _onEngineError(String message) {
    if (isClosed) return;
    emit(state.copyWith(status: VideoCallStatus.error, errorMessage: message));
  }

  Future<void> toggleMicrophone() async {
    final muted = !state.isMicMuted;
    await _agoraService.setMicrophoneMuted(muted);
    emit(state.copyWith(isMicMuted: muted));
  }

  Future<void> toggleCamera() async {
    final disabled = !state.isCameraOff;
    await _agoraService.setCameraDisabled(disabled);
    emit(state.copyWith(isCameraOff: disabled));
  }

  Future<void> flipCamera() async {
    await _agoraService.switchCamera();
    emit(state.copyWith(isFrontCamera: !state.isFrontCamera));
  }

  Future<void> hangUp() async {
    await _teardown();
    if (!isClosed) {
      emit(state.copyWith(status: VideoCallStatus.ended, clearRemoteUid: true));
    }
  }

  Future<bool> openSystemSettings() => _permissionService.openSettings();

  Future<void> _teardown() async {
    if (_teardownDone) return;
    _teardownDone = true;
    try {
      await _agoraService.leaveAndRelease();
    } catch (_) {
      // Ignore teardown errors.
    }
    if (_sessionStarted) {
      await _endVideoSession(_appointmentId);
    }
  }

  @override
  Future<void> close() async {
    await _teardown();
    return super.close();
  }
}
