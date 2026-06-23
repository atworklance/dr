part of 'video_call_cubit.dart';

enum VideoCallStatus {
  /// Nothing has started yet.
  idle,

  /// Awaiting the camera/microphone permission prompt.
  requestingPermissions,

  /// Permission was denied (can be re-requested).
  permissionDenied,

  /// Permission was permanently denied (must open system settings).
  permissionPermanentlyDenied,

  /// Fetching a token and initialising the engine.
  connecting,

  /// Joined the channel; waiting for the other participant.
  waiting,

  /// The remote participant is present — call is live.
  connected,

  /// A fatal error occurred.
  error,

  /// The call has ended.
  ended,
}

class VideoCallState extends Equatable {
  const VideoCallState({
    this.status = VideoCallStatus.idle,
    this.channel,
    this.remoteUid,
    this.isMicMuted = false,
    this.isCameraOff = false,
    this.isFrontCamera = true,
    this.errorMessage,
  });

  final VideoCallStatus status;
  final String? channel;
  final int? remoteUid;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isFrontCamera;
  final String? errorMessage;

  bool get hasRemote => remoteUid != null;

  /// True once the engine is initialised and rendering may occur.
  bool get isLive =>
      status == VideoCallStatus.waiting || status == VideoCallStatus.connected;

  VideoCallState copyWith({
    VideoCallStatus? status,
    String? channel,
    int? remoteUid,
    bool? isMicMuted,
    bool? isCameraOff,
    bool? isFrontCamera,
    String? errorMessage,
    bool clearRemoteUid = false,
    bool clearError = false,
  }) {
    return VideoCallState(
      status: status ?? this.status,
      channel: channel ?? this.channel,
      remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        channel,
        remoteUid,
        isMicMuted,
        isCameraOff,
        isFrontCamera,
        errorMessage,
      ];
}
