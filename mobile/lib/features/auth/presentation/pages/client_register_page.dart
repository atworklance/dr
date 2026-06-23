import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/client_registration.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';

/// Patient registration form.
class ClientRegisterPage extends StatefulWidget {
  const ClientRegisterPage({super.key});

  @override
  State<ClientRegisterPage> createState() => _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  Gender _gender = Gender.undisclosed;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final phone = _phone.text.trim();
    context.read<AuthBloc>().add(
          AuthClientRegisterRequested(
            ClientRegistration(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              phone: phone.isEmpty ? null : phone,
              gender: _gender,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state.status == AuthStatus.unauthenticated &&
            state.failure != null) {
          AppSnackBar.showError(context, state.failure!.message);
        }
      },
      builder: (context, state) {
        return AuthScaffold(
          showBack: true,
          title: 'Create your account',
          subtitle: 'A few details and you’re ready to find care.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'First name',
                        controller: _firstName,
                        hint: 'Jane',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.required(v, field: 'First name'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Last name',
                        controller: _lastName,
                        hint: 'Doe',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.required(v, field: 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Phone (optional)',
                  controller: _phone,
                  hint: '+14155552671',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppSpacing.lg),
                _GenderSelector(
                  value: _gender,
                  onChanged: (g) => setState(() => _gender = g),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPasswordField(
                  label: 'Password',
                  controller: _password,
                  hint: 'At least 8 characters',
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Create account',
                  isLoading: state.isBusy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final g in Gender.values)
              ChoiceChip(
                label: Text(_label(g)),
                selected: value == g,
                onSelected: (_) => onChanged(g),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: value == g ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.surfaceMuted,
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }

  String _label(Gender g) => switch (g) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
        Gender.undisclosed => 'Prefer not to say',
      };
}
