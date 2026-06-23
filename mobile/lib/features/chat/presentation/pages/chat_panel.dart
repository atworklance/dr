import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubit/chat_cubit.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Self-contained in-call chat module. Designed to be shown in a scroll-aware
/// modal bottom sheet over the video call. Provides its own [ChatCubit] and
/// starts the connection immediately.
class ChatPanel extends StatelessWidget {
  const ChatPanel({
    required this.appointmentId,
    required this.currentUserId,
    required this.peerName,
    super.key,
  });

  final String appointmentId;
  final String currentUserId;
  final String peerName;

  /// Opens the panel as a near-full-height modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String appointmentId,
    required String currentUserId,
    required String peerName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        // Lift the sheet above the on-screen keyboard when the composer is focused.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: ChatPanel(
            appointmentId: appointmentId,
            currentUserId: currentUserId,
            peerName: peerName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (_) => ChatCubit(
        repository: sl<ChatRepository>(),
        appointmentId: appointmentId,
        currentUserId: currentUserId,
      )..initialize(),
      child: _ChatView(peerName: peerName),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.peerName});

  final String peerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Header(peerName: peerName),
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) => _buildBody(context, state),
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (p, c) => p.isConnected != c.isConnected,
            builder: (context, state) => ChatComposer(
              enabled: state.isConnected,
              onChanged: (_) => context.read<ChatCubit>().notifyTyping(),
              onSend: (text) => context.read<ChatCubit>().sendMessage(text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatState state) {
    if (state.isConnecting && !state.historyLoaded) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.hasFatalError) {
      return _ErrorBody(
        message: state.errorMessage ?? 'Could not open the conversation.',
        onRetry: () => context.read<ChatCubit>().initialize(),
      );
    }

    final messages = state.messages;
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const _EmptyBody()
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return MessageBubble(
                      message: message,
                      onRetry: () => context.read<ChatCubit>().retry(message),
                    );
                  },
                ),
        ),
        if (state.isPeerTyping)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const TypingIndicator(),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.peerName});

  final String peerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const _PresenceSubtitle(),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresenceSubtitle extends StatelessWidget {
  const _PresenceSubtitle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final (String label, Color color) = switch (state) {
          _ when state.isPeerTyping => ('typing…', AppColors.primary),
          _ when state.isConnected && state.isPeerOnline =>
            ('Online', AppColors.success),
          _ when state.isConnecting => ('Connecting…', AppColors.textTertiary),
          _ => ('Offline', AppColors.textTertiary),
        };
        return Text(label, style: TextStyle(color: color, fontSize: 12.5));
      },
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 56, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.md),
          Text(
            'Start the conversation',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Messages are end-to-end encrypted at rest.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
