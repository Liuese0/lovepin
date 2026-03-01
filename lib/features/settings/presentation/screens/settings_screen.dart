import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/core/constants/app_fonts.dart';
import 'package:lovepin/core/constants/app_sizes.dart';
import 'package:lovepin/core/router/app_router.dart';
import 'package:lovepin/data/local/local_cache.dart';
import 'package:lovepin/data/supabase/couple_repository.dart';
import 'package:lovepin/features/auth/providers/auth_provider.dart';
import 'package:lovepin/services/widget_service.dart';

/// Provider that loads current couple info for the settings screen.
final _coupleInfoProvider = FutureProvider.autoDispose<({String status, String partnerName})>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return (status: 'none', partnerName: '');

  final coupleRepo = ref.read(coupleRepositoryProvider);
  final couple = await coupleRepo.getMyCouple(user.id);
  if (couple == null) return (status: 'none', partnerName: '');

  if (couple.status.value != 'active') {
    return (status: couple.status.value, partnerName: '');
  }

  final partner = await coupleRepo.getPartner(couple.id, user.id);

  // 캐시 갱신
  await LocalCache.instance.saveCoupleInfo(
    coupleId: couple.id,
    partnerId: partner?.id ?? '',
  );

  return (
  status: 'active',
  partnerName: partner?.displayName ?? '',
  );
});

/// Settings screen with account info and sign-out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      await LocalCache.instance.clear();
      await WidgetService.clearWidget();

      if (!context.mounted) return;
      ref.read(isCoupleLinkedProvider.notifier).state = false;
      context.goNamed(RouteNames.login);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.caveat(
            fontSize: AppFonts.h2,
            fontWeight: AppFonts.bold,
            color: AppColors.pinkDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        children: [
          // User info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Row(
                children: [
                  Container(
                    width: AppSizes.avatarMd,
                    height: AppSizes.avatarMd,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pink,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.pinkDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'No email',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Logged in',
                          style: GoogleFonts.nunito(
                            fontSize: AppFonts.caption,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Widget theme
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.palette_outlined,
                color: AppColors.pinkDark,
              ),
              title: const Text('Widget Theme'),
              subtitle: const Text('Customise your widget appearance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(RouteNames.widgetTheme),
            ),
          ),

          // Couple info
          const _CoupleCard(),

          const SizedBox(height: 32),

          // Sign out
          OutlinedButton.icon(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Couple info card that shows real-time status and allows relinking.
class _CoupleCard extends ConsumerWidget {
  const _CoupleCard();

  Future<void> _unlinkCouple(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Couple'),
        content: const Text(
          'Are you sure you want to unlink? '
              'You can reconnect later with a new invite code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final coupleId = LocalCache.instance.getCoupleId();
      if (coupleId != null) {
        final coupleRepo = ref.read(coupleRepositoryProvider);
        await coupleRepo.unlinkCouple(coupleId);
      }
      await LocalCache.instance.clear();
      await WidgetService.clearWidget();

      if (!context.mounted) return;
      ref.read(isCoupleLinkedProvider.notifier).state = false;
      context.goNamed(RouteNames.coupleLink);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unlink: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleAsync = ref.watch(_coupleInfoProvider);

    return coupleAsync.when(
      data: (info) {
        final isLinked = info.status == 'active';
        return Card(
          child: ListTile(
            leading: Icon(
              isLinked ? Icons.favorite : Icons.favorite_outline,
              color: AppColors.pinkDark,
            ),
            title: const Text('Couple'),
            subtitle: Text(
              isLinked
                  ? 'Linked with ${info.partnerName.isNotEmpty ? info.partnerName : 'partner'}'
                  : 'Not linked',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (isLinked) {
                _unlinkCouple(context, ref);
              } else {
                context.goNamed(RouteNames.coupleLink);
              }
            },
          ),
        );
      },
      loading: () => const Card(
        child: ListTile(
          leading: Icon(Icons.favorite_outline, color: AppColors.pinkDark),
          title: Text('Couple'),
          subtitle: Text('Loading...'),
        ),
      ),
      error: (_, __) => Card(
        child: ListTile(
          leading: const Icon(Icons.favorite_outline, color: AppColors.pinkDark),
          title: const Text('Couple'),
          subtitle: const Text('Not linked'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(RouteNames.coupleLink),
        ),
      ),
    );
  }
}