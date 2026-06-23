import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_role.dart';

part 'role_selection_state.dart';

/// Drives the registration role-selection screen. Only [UserRole.client] and
/// [UserRole.provider] are self-selectable; admins are provisioned out-of-band.
class RoleSelectionCubit extends Cubit<RoleSelectionState> {
  RoleSelectionCubit() : super(const RoleSelectionState());

  void select(UserRole role) {
    if (role == UserRole.admin) return; // not self-registerable
    emit(RoleSelectionState(selectedRole: role));
  }

  void selectClient() => select(UserRole.client);

  void selectProvider() => select(UserRole.provider);

  void reset() => emit(const RoleSelectionState());
}
