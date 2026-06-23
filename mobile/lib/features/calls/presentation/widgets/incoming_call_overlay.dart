import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/incoming_call.dart';

/// Full-screen incoming-call alert with a pulsing avatar and accept/decline
/// actions. Rendered above the provider shell while a call is ringing.
class IncomingCallOverlay extends StatefulWidget {
  const IncomingCallOverlay({
    required this.call,
    required this.onAccept,
    required this.onDecline,
    this.callerName = 'Patient',
    super.key,
  });

  final IncomingCall call;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final String callerName;

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.callerName.isNotEmpty
        ? widget.callerName.trim()[0].toUpperCase()
        : '?';

    return Material(
      color: const Color(0xF20B0F18),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Text(
                'Incoming consultation',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _PulsingAvatar(controller: _controller, initials: initials),
              const SizedBox(height: AppSpacing.xl),
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.call.startsAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Scheduled ${Formatters.time(widget.call.startsAt!)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallAction(
                    icon: Icons.call_end_rounded,
                    label: 'Decline',
                    color: AppColors.danger,
                    onTap: widget.onDecline,
                  ),
                  _CallAction(
                    icon: Icons.videocam_rounded,
                    label: 'Accept',
                    color: AppColors.success,
                    onTap: widget.onAccept,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingAvatar extends StatelessWidget {
  const _PulsingAvatar({required this.controller, required this.initials});

  final AnimationController controller;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 1.0 + 0.18 * controller.value;
        final opacity = (1 - controller.value).clamp(0.0, 1.0);
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.25 * opacity),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
