part of 'role_selection_cubit.dart';

class RoleSelectionState extends Equatable {
  const RoleSelectionState({this.selectedRole});

  final UserRole? selectedRole;

  bool get hasSelection => selectedRole != null;
  bool get isClient => selectedRole == UserRole.client;
  bool get isProvider => selectedRole == UserRole.provider;

  @override
  List<Object?> get props => [selectedRole];
}
