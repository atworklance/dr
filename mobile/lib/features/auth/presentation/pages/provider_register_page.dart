import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/entities/geo_point.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/provider_registration.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';

const List<String> _specialtyOptions = [
  'cardiology',
  'dermatology',
  'pediatrics',
  'psychology',
  'dentistry',
  'neurology',
  'orthopedics',
  'gynecology',
  'general medicine',
  'nutrition',
];

const List<String> _currencyOptions = [
  'USD',
  'EUR',
  'GBP',
  'AED',
  'SAR',
  'EGP',
  'NGN',
];

const List<int> _durationOptions = [15, 30, 45, 60];

/// Provider registration form — captures account, professional profile,
/// consultation modes, pricing, and (when offering clinic visits) a location.
class ProviderRegisterPage extends StatefulWidget {
  const ProviderRegisterPage({super.key});

  @override
  State<ProviderRegisterPage> createState() => _ProviderRegisterPageState();
}

class _ProviderRegisterPageState extends State<ProviderRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _headline = TextEditingController();
  final _years = TextEditingController();
  final _onlineFee = TextEditingController();
  final _clinicFee = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  String? _primarySpecialty;
  final Set<String> _extraSpecialties = {};
  bool _offersOnline = true;
  bool _offersClinic = false;
  String _currency = 'USD';
  int _duration = 30;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _password,
      _displayName,
      _headline,
      _years,
      _onlineFee,
      _clinicFee,
      _clinicAddress,
      _latitude,
      _longitude,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _toMinorUnits(String major) =>
      (double.parse(major.trim()) * 100).round();

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_primarySpecialty == null) {
      AppSnackBar.showError(context, 'Choose your primary specialty.');
      return;
    }
    if (!_offersOnline && !_offersClinic) {
      AppSnackBar.showError(context, 'Select at least one consultation mode.');
      return;
    }

    final modes = <ConsultationMode>[
      if (_offersOnline) ConsultationMode.online,
      if (_offersClinic) ConsultationMode.clinic,
    ];
    final specialties = <String>{_primarySpecialty!, ..._extraSpecialties}.toList();

    GeoPoint? clinicLocation;
    if (_offersClinic) {
      final lat = double.tryParse(_latitude.text.trim());
      final lng = double.tryParse(_longitude.text.trim());
      if (lat == null || lng == null) {
        AppSnackBar.showError(context, 'Enter a valid clinic latitude/longitude.');
        return;
      }
      clinicLocation = GeoPoint(longitude: lng, latitude: lat);
    }

    final registration = ProviderRegistration(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      displayName: _displayName.text.trim(),
      headline: _headline.text.trim().isEmpty ? null : _headline.text.trim(),
      primarySpecialty: _primarySpecialty!,
      specialties: specialties,
      yearsOfExperience: int.tryParse(_years.text.trim()),
      consultationModes: modes,
      onlineFee: _offersOnline ? _toMinorUnits(_onlineFee.text) : 0,
      clinicFee: _offersClinic ? _toMinorUnits(_clinicFee.text) : 0,
      currency: _currency,
      sessionDurationMinutes: _duration,
      clinicLocation: clinicLocation,
      clinicAddress:
          _offersClinic && _clinicAddress.text.trim().isNotEmpty
              ? _clinicAddress.text.trim()
              : null,
    );

    context.read<AuthBloc>().add(AuthProviderRegisterRequested(registration));
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
          title: 'Provider sign-up',
          subtitle: 'Set up your professional profile. Approval follows review.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel('Account'),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'First name',
                        controller: _firstName,
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
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPasswordField(
                  label: 'Password',
                  controller: _password,
                  hint: 'At least 8 characters',
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel('Professional profile'),
                AppTextField(
                  label: 'Display name',
                  controller: _displayName,
                  hint: 'Dr. Jane Doe',
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, field: 'Display name'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Headline (optional)',
                  controller: _headline,
                  hint: 'Consultant Cardiologist · 12y experience',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                _LabeledDropdown<String>(
                  label: 'Primary specialty',
                  value: _primarySpecialty,
                  hint: 'Select your specialty',
                  items: _specialtyOptions,
                  itemLabel: _titleCase,
                  onChanged: (v) => setState(() {
                    _primarySpecialty = v;
                    _extraSpecialties.remove(v);
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                _MultiChipField(
                  label: 'Additional specialties (optional)',
                  options: _specialtyOptions
                      .where((s) => s != _primarySpecialty)
                      .toList(),
                  selected: _extraSpecialties,
                  itemLabel: _titleCase,
                  onToggle: (s) => setState(() {
                    _extraSpecialties.contains(s)
                        ? _extraSpecialties.remove(s)
                        : _extraSpecialties.add(s);
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Years of experience (optional)',
                  controller: _years,
                  prefixIcon: Icons.workspace_premium_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel('Consultation & pricing'),
                _ModeToggles(
                  online: _offersOnline,
                  clinic: _offersClinic,
                  onOnline: (v) => setState(() => _offersOnline = v),
                  onClinic: (v) => setState(() => _offersClinic = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_offersOnline) ...[
                  AppTextField(
                    label: 'Online fee ($_currency)',
                    controller: _onlineFee,
                    hint: '45.00',
                    prefixIcon: Icons.videocam_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        Validators.positiveAmount(v, field: 'Online fee'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (_offersClinic) ...[
                  AppTextField(
                    label: 'Clinic fee ($_currency)',
                    controller: _clinicFee,
                    hint: '60.00',
                    prefixIcon: Icons.local_hospital_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        Validators.positiveAmount(v, field: 'Clinic fee'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Clinic address',
                    controller: _clinicAddress,
                    prefixIcon: Icons.place_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Latitude',
                          controller: _latitude,
                          hint: '25.2048',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (v) =>
                              Validators.required(v, field: 'Latitude'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          label: 'Longitude',
                          controller: _longitude,
                          hint: '55.2708',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (v) =>
                              Validators.required(v, field: 'Longitude'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _LabeledDropdown<String>(
                        label: 'Currency',
                        value: _currency,
                        items: _currencyOptions,
                        itemLabel: (c) => c,
                        onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _LabeledDropdown<int>(
                        label: 'Session length',
                        value: _duration,
                        items: _durationOptions,
                        itemLabel: (m) => '$m min',
                        onChanged: (v) => setState(() => _duration = v ?? 30),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Create provider account',
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

  static String _titleCase(String value) => value
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: hint == null ? null : Text(hint!),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MultiChipField extends StatelessWidget {
  const _MultiChipField({
    required this.label,
    required this.options,
    required this.selected,
    required this.itemLabel,
    required this.onToggle,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final String Function(String) itemLabel;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(itemLabel(option)),
                selected: selected.contains(option),
                onSelected: (_) => onToggle(option),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceMuted,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: selected.contains(option)
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ModeToggles extends StatelessWidget {
  const _ModeToggles({
    required this.online,
    required this.clinic,
    required this.onOnline,
    required this.onClinic,
  });

  final bool online;
  final bool clinic;
  final ValueChanged<bool> onOnline;
  final ValueChanged<bool> onClinic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            icon: Icons.videocam_rounded,
            label: 'Online',
            selected: online,
            onTap: () => onOnline(!online),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ModeChip(
            icon: Icons.local_hospital_rounded,
            label: 'Clinic',
            selected: clinic,
            onTap: () => onClinic(!clinic),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
