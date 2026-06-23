import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/user_role.dart';
import '../cubit/role_selection_cubit.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/role_option_card.dart';
import 'client_register_page.dart';
import 'provider_register_page.dart';

/// "Patient vs Provider" toggle. The selection is held in [RoleSelectionCubit]
/// and routes the user into the matching registration form.
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _continue(BuildContext context, UserRole role) {
    final Widget page = role == UserRole.provider
        ? const ProviderRegisterPage()
        : const ClientRegisterPage();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: 'Join Dr.Plus',
      subtitle: 'Tell us how you’ll use the platform. You can always switch later.',
      child: BlocBuilder<RoleSelectionCubit, RoleSelectionState>(
        builder: (context, state) {
          final cubit = context.read<RoleSelectionCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoleOptionCard(
                icon: Icons.person_search_rounded,
                title: 'I’m a Patient',
                subtitle:
                    'Search specialists, book online or clinic visits, and consult live.',
                selected: state.isClient,
                onTap: cubit.selectClient,
              ),
              const SizedBox(height: AppSpacing.lg),
              RoleOptionCard(
                icon: Icons.medical_information_rounded,
                title: 'I’m a Provider',
                subtitle:
                    'Offer consultations, manage availability, and track your earnings.',
                selected: state.isProvider,
                onTap: cubit.selectProvider,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: state.hasSelection
                    ? () => _continue(context, state.selectedRole!)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
