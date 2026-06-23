import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Callbacks surfaced from the Agora engine to the orchestrating BLoC.
class AgoraEventCallbacks {
  const AgoraEventCallbacks({
    required this.onLocalJoined,
    required this.onRemoteJoined,
    required this.onRemoteLeft,
    required this.onError,
  });

  final void Function() onLocalJoined;
  final void Function(int remoteUid) onRemoteJoined;
  final void Function(int remoteUid) onRemoteLeft;
  final void Function(String message) onError;
}

/// Thin wrapper around the Agora RTC engine. Keeps all SDK calls behind an
/// interface so the presentation layer depends on an abstraction; the live
/// [RtcEngine] is exposed only for the platform video views to render.
abstract interface class AgoraVideoService {
  /// The initialised engine. Throws if accessed before [initialize].
  RtcEngine get engine;

  Future<void> initialize(String appId, AgoraEventCallbacks callbacks);
  Future<void> enableVideoPreview();
  Future<void> joinWithUserAccount({
    required String token,
    required String channelId,
    required String userAccount,
  });
  Future<void> setMicrophoneMuted(bool muted);
  Future<void> setCameraDisabled(bool disabled);
  Future<void> switchCamera();
  Future<void> leaveAndRelease();
}

class AgoraVideoServiceImpl implements AgoraVideoService {
  RtcEngine? _engine;

  @override
  RtcEngine get engine {
    final engine = _engine;
    if (engine == null) {
      throw StateError('Agora engine accessed before initialize().');
    }
    return engine;
  }

  @override
  Future<void> initialize(String appId, AgoraEventCallbacks callbacks) async {
    await leaveAndRelease();

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          callbacks.onLocalJoined();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          callbacks.onRemoteJoined(remoteUid);
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          callbacks.onRemoteLeft(remoteUid);
        },
        onError: (ErrorCodeType err, String msg) {
          callbacks.onError(msg.isEmpty ? err.name : msg);
        },
      ),
    );

    _engine = engine;
  }

  @override
  Future<void> enableVideoPreview() async {
    final engine = this.engine;
    await engine.enableVideo();
    await engine.startPreview();
  }

  @override
  Future<void> joinWithUserAccount({
    required String token,
    required String channelId,
    required String userAccount,
  }) {
    return engine.joinChannelWithUserAccount(
      token: token,
      channelId: channelId,
      userAccount: userAccount,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) =>
      engine.muteLocalAudioStream(muted);

  @override
  Future<void> setCameraDisabled(bool disabled) =>
      engine.muteLocalVideoStream(disabled);

  @override
  Future<void> switchCamera() => engine.switchCamera();

  @override
  Future<void> leaveAndRelease() async {
    final engine = _engine;
    if (engine == null) return;
    _engine = null;
    try {
      await engine.leaveChannel();
    } catch (_) {
      // Ignore — releasing regardless.
    }
    await engine.release();
  }
}
