import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../availability/presentation/pages/availability_calendar_page.dart';
import '../../../calls/domain/repositories/call_signaling_repository.dart';
import '../../../calls/presentation/cubit/incoming_call_cubit.dart';
import '../../../calls/presentation/widgets/incoming_call_overlay.dart';
import '../../../video/presentation/pages/video_call_page.dart';
import '../../../wallet/presentation/pages/revenue_dashboard_page.dart';

/// The provider's authenticated shell: a bottom-nav between the revenue
/// dashboard and the availability calendar, with a globally-listening incoming
/// call overlay rendered on top.
class ProviderHomePage extends StatelessWidget {
  const ProviderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.select<AuthBloc, String>((b) => b.state.user?.id ?? '');

    return BlocProvider<IncomingCallCubit>(
      create: (_) => IncomingCallCubit(
        repository: sl<CallSignalingRepository>(),
        currentUserId: currentUserId,
      )..initialize(),
      child: const _ProviderHomeView(),
    );
  }
}

class _ProviderHomeView extends StatefulWidget {
  const _ProviderHomeView();

  @override
  State<_ProviderHomeView> createState() => _ProviderHomeViewState();
}

class _ProviderHomeViewState extends State<_ProviderHomeView> {
  int _index = 0;

  void _signOut() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  void _acceptCall(BuildContext context, String appointmentId) {
    context.read<IncomingCallCubit>().dismiss();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoCallPage(
          appointmentId: appointmentId,
          specialistName: 'Patient',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoutAction = [
      IconButton(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
        tooltip: 'Sign out',
      ),
    ];

    final pages = [
      RevenueDashboardPage(appBarActions: logoutAction),
      AvailabilityCalendarPage(appBarActions: logoutAction),
    ];

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Calendar',
              ),
            ],
          ),
        ),
        BlocBuilder<IncomingCallCubit, IncomingCallState>(
          buildWhen: (p, c) => p.current != c.current,
          builder: (context, state) {
            final call = state.current;
            if (call == null) return const SizedBox.shrink();
            return Positioned.fill(
              child: IncomingCallOverlay(
                call: call,
                onAccept: () => _acceptCall(context, call.appointmentId),
                onDecline: () => context.read<IncomingCallCubit>().dismiss(),
              ),
            );
          },
        ),
      ],
    );
  }
}
