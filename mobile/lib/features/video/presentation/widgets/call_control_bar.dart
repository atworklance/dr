import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The bottom control dock: mute, camera, flip, and end-call. Rendered over a
/// soft gradient scrim so it stays legible on any video background.
class CallControlBar extends StatelessWidget {
  const CallControlBar({
    required this.isMicMuted,
    required this.isCameraOff,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.onHangUp,
    super.key,
  });

  final bool isMicMuted;
  final bool isCameraOff;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Color(0xCC0B0F18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleControl(
            icon: isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: isMicMuted ? 'Unmute' : 'Mute',
            active: isMicMuted,
            onTap: onToggleMic,
          ),
          _CircleControl(
            icon: isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
            label: isCameraOff ? 'Start' : 'Stop',
            active: isCameraOff,
            onTap: onToggleCamera,
          ),
          _CircleControl(
            icon: Icons.cameraswitch_rounded,
            label: 'Flip',
            active: false,
            onTap: onFlipCamera,
          ),
          _CircleControl(
            icon: Icons.call_end_rounded,
            label: 'End',
            active: false,
            danger: true,
            onTap: onHangUp,
          ),
        ],
      ),
    );
  }
}

class _CircleControl extends StatelessWidget {
  const _CircleControl({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = danger
        ? AppColors.danger
        : (active ? Colors.white : Colors.white24);
    final Color foreground =
        danger ? Colors.white : (active ? AppColors.textPrimary : Colors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: danger ? 64 : 58,
              height: danger ? 64 : 58,
              child: Icon(icon, color: foreground, size: danger ? 30 : 26),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
