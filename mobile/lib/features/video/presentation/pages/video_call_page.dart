import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chat/presentation/pages/chat_panel.dart';
import '../cubit/video_call_cubit.dart';
import '../widgets/call_control_bar.dart';
import '../widgets/call_top_bar.dart';
import '../widgets/video_stage.dart';

/// Full-screen live video consultation. Provides the [VideoCallCubit] and starts
/// the permission -> token -> join pipeline immediately.
class VideoCallPage extends StatelessWidget {
  const VideoCallPage({
    required this.appointmentId,
    required this.specialistName,
    super.key,
  });

  final String appointmentId;
  final String specialistName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoCallCubit>(
      create: (_) => sl<VideoCallCubit>()..start(appointmentId),
      child: _VideoCallView(
        appointmentId: appointmentId,
        specialistName: specialistName,
      ),
    );
  }
}

class _VideoCallView extends StatefulWidget {
  const _VideoCallView({
    required this.appointmentId,
    required this.specialistName,
  });

  final String appointmentId;
  final String specialistName;

  @override
  State<_VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<_VideoCallView> {
  Timer? _timer;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimerRunning() {
    if (_timer != null) return;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_startedAt!));
    });
  }

  String get _durationLabel {
    final totalSeconds = _elapsed.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _statusLabel(VideoCallStatus status) => switch (status) {
        VideoCallStatus.connected => 'Connected',
        VideoCallStatus.waiting => 'Waiting to connect',
        _ => 'Connecting…',
      };

  void _openChat(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.id ?? '';
    ChatPanel.show(
      context,
      appointmentId: widget.appointmentId,
      currentUserId: userId,
      peerName: widget.specialistName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await context.read<VideoCallCubit>().hangUp();
      },
      child: BlocConsumer<VideoCallCubit, VideoCallState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == VideoCallStatus.connected) {
            _ensureTimerRunning();
          }
          if (state.status == VideoCallStatus.ended) {
            _timer?.cancel();
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFF0B0F18),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, VideoCallState state) {
    switch (state.status) {
      case VideoCallStatus.idle:
      case VideoCallStatus.requestingPermissions:
      case VideoCallStatus.connecting:
        return _ConnectingView(
          name: widget.specialistName,
          label: state.status == VideoCallStatus.requestingPermissions
              ? 'Requesting camera & microphone…'
              : 'Connecting…',
        );
      case VideoCallStatus.permissionDenied:
        return _PermissionView(
          permanent: false,
          onPrimary: () =>
              context.read<VideoCallCubit>().start(widget.appointmentId),
          onCancel: () => context.read<VideoCallCubit>().hangUp(),
        );
      case VideoCallStatus.permissionPermanentlyDenied:
        return _PermissionView(
          permanent: true,
          onPrimary: () => context.read<VideoCallCubit>().openSystemSettings(),
          onCancel: () => context.read<VideoCallCubit>().hangUp(),
        );
      case VideoCallStatus.error:
        return _ErrorView(
          message: state.errorMessage ?? 'The video session could not start.',
          onClose: () => context.read<VideoCallCubit>().hangUp(),
        );
      case VideoCallStatus.waiting:
      case VideoCallStatus.connected:
        return _buildLiveStack(context, state);
      case VideoCallStatus.ended:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLiveStack(BuildContext context, VideoCallState state) {
    final cubit = context.read<VideoCallCubit>();
    return Stack(
      fit: StackFit.expand,
      children: [
        VideoStage(
          engine: cubit.engine,
          state: state,
          specialistName: widget.specialistName,
        ),
        Align(
          alignment: Alignment.topCenter,
          child: CallTopBar(
            specialistName: widget.specialistName,
            statusLabel: _statusLabel(state.status),
            isLive: state.status == VideoCallStatus.connected,
            durationLabel: _durationLabel,
            onOpenChat: () => _openChat(context),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CallControlBar(
            isMicMuted: state.isMicMuted,
            isCameraOff: state.isCameraOff,
            onToggleMic: cubit.toggleMicrophone,
            onToggleCamera: cubit.toggleCamera,
            onFlipCamera: cubit.flipCamera,
            onHangUp: cubit.hangUp,
          ),
        ),
      ],
    );
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({required this.name, required this.label});

  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.video_camera_front_rounded, color: Colors.white, size: 56),
          const SizedBox(height: AppSpacing.lg),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: AppSpacing.xl),
          const SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({
    required this.permanent,
    required this.onPrimary,
    required this.onCancel,
  });

  final bool permanent;
  final VoidCallback onPrimary;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.perm_camera_mic_rounded, color: Colors.white, size: 64),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Camera & microphone needed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              permanent
                  ? 'Access was turned off. Enable camera and microphone in Settings to join the consultation.'
                  : 'We need access to your camera and microphone to start the video consultation.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: permanent ? 'Open settings' : 'Allow access',
              icon: permanent ? Icons.settings_rounded : Icons.check_rounded,
              onPressed: onPrimary,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Not now',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 64),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Couldn’t connect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Close',
              gradient: false,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
