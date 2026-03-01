import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/core/constants/app_fonts.dart';
import 'package:lovepin/core/router/app_router.dart';
import 'package:lovepin/data/local/local_cache.dart';
import 'package:lovepin/data/supabase/auth_repository.dart';
import 'package:lovepin/data/supabase/couple_repository.dart';
import 'package:lovepin/data/supabase/supabase_client.dart';
import 'package:lovepin/features/auth/providers/auth_provider.dart';

/// Full-screen splash that initialises the local cache and resolves the
/// initial navigation destination based on auth & couple state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await LocalCache.instance.init();

      final user = ref.read(currentUserProvider);
      if (!mounted) return;

      if (user == null) {
        context.goNamed(RouteNames.login);
        return;
      }

      // If the user didn't choose "remember me", sign out on restart.
      if (!LocalCache.instance.getRememberMe()) {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signOut();
        await LocalCache.instance.clear();
        if (!mounted) return;
        context.goNamed(RouteNames.login);
        return;
      }

      // Check if the user has completed profile setup.
      final db = SupabaseClientWrapper.instance;
      final profileRows = await db
          .database('users')
          .select('display_name')
          .eq('id', user.id);

      if (!mounted) return;

      final hasProfile = profileRows.isNotEmpty &&
          profileRows.first['display_name'] != null &&
          (profileRows.first['display_name'] as String).isNotEmpty;

      if (!hasProfile) {
        context.goNamed(RouteNames.profileSetup);
        return;
      }

      // Cache own display name for widget sender label.
      await LocalCache.instance.saveMyDisplayName(
        profileRows.first['display_name'] as String,
      );

      // Check couple status.
      final coupleRepo = ref.read(coupleRepositoryProvider);
      final couple = await coupleRepo.getMyCouple(user.id);

      if (!mounted) return;

      if (couple != null && couple.status.value == 'active') {
        // 로컬 캐시에 커플 정보 저장
        final partner = await coupleRepo.getPartner(couple.id, user.id);
        await LocalCache.instance.saveCoupleInfo(
          coupleId: couple.id,
          partnerId: partner?.id ?? '',
          partnerName: partner?.displayName ?? '',
        );

        if (!mounted) return;
        ref.read(isCoupleLinkedProvider.notifier).state = true;
        context.goNamed(RouteNames.home);
      } else {
        context.goNamed(RouteNames.coupleLink);
      }
    } catch (_) {
      if (mounted) {
        context.goNamed(RouteNames.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pinkGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 64,
                  color: AppColors.pinkDark,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lovepin',
                  style: GoogleFonts.caveat(
                    fontSize: 40,
                    fontWeight: AppFonts.bold,
                    color: AppColors.pinkDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your love, on their home screen',
                  style: GoogleFonts.nunito(
                    fontSize: AppFonts.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}