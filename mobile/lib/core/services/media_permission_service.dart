import 'package:permission_handler/permission_handler.dart';

/// Outcome of a camera + microphone permission request.
enum MediaPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

/// Abstraction over the runtime permission prompts required for a video call,
/// keeping the platform dependency out of the BLoC layer.
abstract interface class MediaPermissionService {
  Future<MediaPermissionResult> requestCameraAndMicrophone();
  Future<bool> openSettings();
}

class MediaPermissionServiceImpl implements MediaPermissionService {
  const MediaPermissionServiceImpl();

  @override
  Future<MediaPermissionResult> requestCameraAndMicrophone() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final camera = statuses[Permission.camera] ?? PermissionStatus.denied;
    final mic = statuses[Permission.microphone] ?? PermissionStatus.denied;

    if (camera.isGranted && mic.isGranted) {
      return MediaPermissionResult.granted;
    }
    if (camera.isPermanentlyDenied || mic.isPermanentlyDenied) {
      return MediaPermissionResult.permanentlyDenied;
    }
    return MediaPermissionResult.denied;
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
