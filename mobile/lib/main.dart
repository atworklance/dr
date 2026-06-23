import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/cubit/role_selection_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/booking/presentation/pages/specialist_search_page.dart';
import 'features/provider_home/presentation/pages/provider_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const DrPlusApp());
}

/// Root widget. Provides the app-wide auth state + role-selection state, kicks
/// off session restoration, and routes between the auth flow and the
/// authenticated shell.
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
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Switches between the splash, the auth flow, and the authenticated home shell
/// based on [AuthState]. A fade transition keeps the handoff smooth.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final Widget screen = switch (state.status) {
          AuthStatus.unknown ||
          AuthStatus.authenticating =>
            const _SplashScreen(),
          AuthStatus.authenticated => (state.user?.isProvider ?? false)
              ? const ProviderHomePage()
              : const SpecialistSearchPage(),
          AuthStatus.unauthenticated => const LoginPage(),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(screen.runtimeType),
            child: screen,
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services_rounded, color: Colors.white, size: 56),
              SizedBox(height: 16),
              Text(
                'Dr.Plus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
