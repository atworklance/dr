import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/cubit/role_selection_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const DrPlusApp());
}

/// Root widget. Provides the app-wide auth state and kicks off session
/// restoration. Feature screens (search/booking) create their own scoped BLoCs
/// from the service locator when navigated to.
class DrPlusApp extends StatelessWidget {
  const DrPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<RoleSelectionCubit>(
          create: (_) => sl<RoleSelectionCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Dr.Plus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6FFF)),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes between authenticated / unauthenticated shells based on [AuthState].
/// Concrete screens are added in subsequent UI blocks; this gate proves the
/// state wiring end-to-end.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final Widget body = switch (state.status) {
          AuthStatus.unknown ||
          AuthStatus.authenticating =>
            const Center(child: CircularProgressIndicator()),
          AuthStatus.authenticated => Center(
              child: Text('Signed in as ${state.user?.fullName ?? ''}'),
            ),
          AuthStatus.unauthenticated => Center(
              child: Text(
                state.failure?.message ?? 'Please sign in to continue.',
              ),
            ),
        };
        return Scaffold(body: SafeArea(child: body));
      },
    );
  }
}
