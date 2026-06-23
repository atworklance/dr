import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/video_call_cubit.dart';

/// The video surface: the remote participant fills the screen (or a waiting
/// placeholder), with the local camera shown as a rounded picture-in-picture.
class VideoStage extends StatelessWidget {
  const VideoStage({
    required this.engine,
    required this.state,
    required this.specialistName,
    super.key,
  });

  final RtcEngine engine;
  final VideoCallState state;
  final String specialistName;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _buildRemote()),
        Positioned(
          top: topInset + 72,
          right: AppSpacing.lg,
          child: _LocalPreview(engine: engine, cameraOff: state.isCameraOff),
        ),
      ],
    );
  }

  Widget _buildRemote() {
    if (state.status == VideoCallStatus.connected &&
        state.remoteUid != null &&
        state.channel != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: state.remoteUid),
          connection: RtcConnection(channelId: state.channel),
        ),
      );
    }
    return _WaitingForRemote(name: specialistName);
  }
}

class _LocalPreview extends StatelessWidget {
  const _LocalPreview({required this.engine, required this.cameraOff});

  final RtcEngine engine;
  final bool cameraOff;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2330),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: cameraOff
          ? const Center(
              child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28),
            )
          : AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
    );
  }
}

class _WaitingForRemote extends StatelessWidget {
  const _WaitingForRemote({required this.name});

  final String name;

  String get _initials {
    final cleaned = name
        .replaceAll(RegExp('^(dr\\.?|prof\\.?)\\s*', caseSensitive: false), '')
        .trim();
    final parts = cleaned.isEmpty ? <String>[] : cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF101726), Color(0xFF1B2740)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Waiting for them to join…',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
