import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

/// The selected withdrawal request: amount in minor units + payout method.
typedef WithdrawalRequest = ({int amountMinorUnits, String payoutMethod});

const List<String> _payoutMethods = [
  'Bank transfer',
  'PayPal',
  'Stripe',
  'Wise',
];

/// Bottom-sheet form to request a payout, bounded by [availableMinorUnits].
Future<WithdrawalRequest?> showWithdrawalSheet(
  BuildContext context, {
  required int availableMinorUnits,
  required String currency,
}) {
  return showModalBottomSheet<WithdrawalRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _WithdrawalSheet(
        availableMinorUnits: availableMinorUnits,
        currency: currency,
      ),
    ),
  );
}

class _WithdrawalSheet extends StatefulWidget {
  const _WithdrawalSheet({
    required this.availableMinorUnits,
    required this.currency,
  });

  final int availableMinorUnits;
  final String currency;

  @override
  State<_WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends State<_WithdrawalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _method = _payoutMethods.first;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final base = Validators.positiveAmount(value, field: 'Amount');
    if (base != null) return base;
    final minor = (double.parse(value!.trim()) * 100).round();
    if (minor <= 0) return 'Enter an amount greater than zero.';
    if (minor > widget.availableMinorUnits) {
      return 'Exceeds your available balance.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final minor = (double.parse(_amountController.text.trim()) * 100).round();
    Navigator.of(context).pop(
      (amountMinorUnits: minor, payoutMethod: _method),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request withdrawal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Available: ${Formatters.money(widget.availableMinorUnits, widget.currency)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Amount (${widget.currency})',
              controller: _amountController,
              hint: '0.00',
              prefixIcon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validateAmount,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Payout method',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _method,
              items: [
                for (final method in _payoutMethods)
                  DropdownMenuItem<String>(value: method, child: Text(method)),
              ],
              onChanged: (value) => setState(() => _method = value ?? _method),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Request payout', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
