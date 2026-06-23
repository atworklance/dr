import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/specialist.dart';
import '../bloc/search/specialist_search_bloc.dart';
import '../widgets/specialist_card.dart';
import 'booking_page.dart';

const List<String> _categories = [
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

/// Specialist directory: search, category + mode filters, infinite-scroll list,
/// and pull-to-refresh. Provides its own [SpecialistSearchBloc] from the DI
/// container and kicks off an initial search.
class SpecialistSearchPage extends StatelessWidget {
  const SpecialistSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpecialistSearchBloc>(
      create: (_) =>
          sl<SpecialistSearchBloc>()..add(const SpecialistSearchRequested(SearchFilter())),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String? _category;
  ConsultationMode? _mode;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<SpecialistSearchBloc>().add(const SpecialistSearchMoreRequested());
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    context.read<SpecialistSearchBloc>().add(
          SpecialistSearchRequested(
            SearchFilter(
              query: query.isEmpty ? null : query,
              specialty: _category,
              mode: _mode,
            ),
          ),
        );
  }

  Future<void> _refresh() async {
    context.read<SpecialistSearchBloc>().add(const SpecialistSearchRefreshed());
  }

  void _openBooking(Specialist specialist) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookingPage(specialist: specialist)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.firstName ?? 'there',
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              firstName: firstName,
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SearchBar(
                controller: _searchController,
                onSubmitted: (_) => _applyFilter(),
                onClear: () {
                  _searchController.clear();
                  _applyFilter();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryBar(
              selected: _category,
              onSelected: (category) {
                setState(() => _category = category);
                _applyFilter();
              },
            ),
            _ModeBar(
              selected: _mode,
              onSelected: (mode) {
                setState(() => _mode = mode);
                _applyFilter();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: BlocBuilder<SpecialistSearchBloc, SpecialistSearchState>(
                  builder: (context, state) => _buildBody(context, state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SpecialistSearchState state) {
    if (state.isLoadingFirstPage) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.status == SearchStatus.failure && state.specialists.isEmpty) {
      return _MessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: state.failure?.message ?? 'Unable to load specialists.',
        actionLabel: 'Retry',
        onAction: _applyFilter,
      );
    }

    if (state.isEmpty) {
      return const _MessageView(
        icon: Icons.search_off_rounded,
        title: 'No specialists found',
        message: 'Try adjusting your filters or search terms.',
      );
    }

    final specialists = state.specialists;
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: specialists.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index >= specialists.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        final specialist = specialists[index];
        return SpecialistCard(
          specialist: specialist,
          onTap: () => _openBooking(specialist),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.onLogout});

  final String firstName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $firstName 👋',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Find the right specialist for you',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Search by name or specialty',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClear,
                ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterPill(
              label: 'All',
              selected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final category = _categories[index - 1];
          return _FilterPill(
            label: _titleCase(category),
            selected: selected == category,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }

  static String _titleCase(String value) => value
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({required this.selected, required this.onSelected});

  final ConsultationMode? selected;
  final ValueChanged<ConsultationMode?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          _FilterPill(
            label: 'Any visit',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterPill(
            label: 'Online',
            icon: Icons.videocam_rounded,
            selected: selected == ConsultationMode.online,
            onTap: () => onSelected(ConsultationMode.online),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterPill(
            label: 'Clinic',
            icon: Icons.local_hospital_rounded,
            selected: selected == ConsultationMode.clinic,
            onTap: () => onSelected(ConsultationMode.clinic),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 64, color: AppColors.textTertiary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
