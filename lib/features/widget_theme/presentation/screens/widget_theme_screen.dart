import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/core/constants/app_fonts.dart';
import 'package:lovepin/core/constants/app_sizes.dart';
import 'package:lovepin/data/local/local_cache.dart';
import 'package:lovepin/data/models/theme_model.dart';
import 'package:lovepin/data/supabase/theme_repository.dart';

/// Provider that fetches available widget themes.
final widgetThemesProvider =
    FutureProvider.autoDispose<List<WidgetThemeModel>>((ref) async {
  final repo = ThemeRepository();
  return repo.getThemes();
});

/// Provider tracking the currently selected theme ID.
final selectedThemeIdProvider = StateProvider<String?>((ref) {
  return LocalCache.instance.getSelectedThemeId();
});

/// Screen for browsing and selecting widget themes.
class WidgetThemeScreen extends ConsumerWidget {
  const WidgetThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(widgetThemesProvider);
    final selectedId = ref.watch(selectedThemeIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Widget Theme',
          style: GoogleFonts.caveat(
            fontSize: AppFonts.h2,
            fontWeight: AppFonts.bold,
            color: AppColors.pinkDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('settings');
            }
          },
        ),
      ),
      body: themesAsync.when(
        data: (themes) {
          if (themes.isEmpty) {
            return Center(
              child: Text(
                'No themes available yet',
                style: GoogleFonts.nunito(color: AppColors.textSecondary),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = theme.id == selectedId;

              return GestureDetector(
                onTap: () async {
                  ref.read(selectedThemeIdProvider.notifier).state = theme.id;
                  await LocalCache.instance.saveSelectedThemeId(theme.id);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Theme "${theme.name}" applied!'),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.backgroundColorValue,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: isSelected
                        ? Border.all(color: AppColors.pinkDark, width: 3)
                        : Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Preview text
                        Text(
                          'I love you',
                          style: GoogleFonts.caveat(
                            fontSize: 20,
                            fontWeight: AppFonts.bold,
                            color: theme.textColorValue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'just now',
                          style: GoogleFonts.nunito(
                            fontSize: AppFonts.tiny,
                            color: theme.accentColorValue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 2,
                          width: 40,
                          color: theme.accentColorValue.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),

                        // Theme name
                        Text(
                          theme.name,
                          style: GoogleFonts.nunito(
                            fontSize: AppFonts.caption,
                            fontWeight: AppFonts.semiBold,
                            color: theme.textColorValue,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Selected indicator
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 20,
                              color: theme.accentColorValue,
                            ),
                          ),

                        // Premium badge
                        if (theme.isPremium)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.accentColorValue
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusPill,
                                ),
                              ),
                              child: Text(
                                'PRO',
                                style: GoogleFonts.nunito(
                                  fontSize: AppFonts.tiny,
                                  fontWeight: AppFonts.bold,
                                  color: theme.accentColorValue,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.pinkDark),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load themes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(widgetThemesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
