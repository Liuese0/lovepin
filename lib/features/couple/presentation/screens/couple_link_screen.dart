import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/core/constants/app_fonts.dart';
import 'package:lovepin/core/constants/app_sizes.dart';
import 'package:lovepin/core/router/app_router.dart';
import 'package:lovepin/data/local/local_cache.dart';
import 'package:lovepin/data/supabase/auth_repository.dart';
import 'package:lovepin/features/auth/providers/auth_provider.dart';

/// Screen where users create an invite code or join an existing couple.
class CoupleLinkScreen extends ConsumerStatefulWidget {
  const CoupleLinkScreen({super.key});

  @override
  ConsumerState<CoupleLinkScreen> createState() => _CoupleLinkScreenState();
}

class _CoupleLinkScreenState extends ConsumerState<CoupleLinkScreen> {
  final _codeController = TextEditingController();
  String? _generatedCode;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createCouple() async {
    setState(() => _loading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final coupleRepo = ref.read(coupleRepositoryProvider);
      final couple = await coupleRepo.createCouple(user.id);

      setState(() {
        _generatedCode = couple.inviteCode;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create invite: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinCouple() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final coupleRepo = ref.read(coupleRepositoryProvider);
      final couple = await coupleRepo.joinCouple(code, user.id);

      // Cache couple info locally.
      final partner = await coupleRepo.getPartner(couple.id, user.id);
      await LocalCache.instance.saveCoupleInfo(
        coupleId: couple.id,
        partnerId: partner?.id ?? '',
        partnerName: partner?.displayName ?? '',
      );

      if (!mounted) return;
      ref.read(isCoupleLinkedProvider.notifier).state = true;
      context.goNamed(RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingXxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.link,
                  size: 56,
                  color: AppColors.pinkDark,
                ),
                const SizedBox(height: 12),
                Text(
                  'Link with your partner',
                  style: GoogleFonts.caveat(
                    fontSize: 28,
                    fontWeight: AppFonts.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an invite code to share, or enter one '
                      'you received',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: AppFonts.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // --- Create invite ---
                if (_generatedCode == null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _createCouple,
                      icon: const Icon(Icons.add),
                      label: const Text('Generate Invite Code'),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLg),
                      child: Column(
                        children: [
                          Text(
                            'Your invite code',
                            style: GoogleFonts.nunito(
                              fontSize: AppFonts.bodySmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _generatedCode!,
                            style: GoogleFonts.caveat(
                              fontSize: 36,
                              fontWeight: AppFonts.bold,
                              color: AppColors.pinkDark,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _generatedCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copied!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this code with your partner.\n'
                                'It expires in 24 hours.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: AppFonts.caption,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLg,
                      ),
                      child: Text(
                        'OR',
                        style: GoogleFonts.nunito(
                          fontSize: AppFonts.caption,
                          color: AppColors.textSecondary,
                          fontWeight: AppFonts.semiBold,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Join with code ---
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Enter invite code',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  onFieldSubmitted: (_) => _joinCouple(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _joinCouple,
                    child: _loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                        : const Text('Join'),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign out
                TextButton(
                  onPressed: () async {
                    final authRepo = ref.read(authRepositoryProvider);
                    await authRepo.signOut();
                    await LocalCache.instance.clear();
                    if (!mounted) return;
                    context.goNamed(RouteNames.login);
                  },
                  child: Text(
                    "We'll meet again.",
                    style: GoogleFonts.nunito(
                      fontSize: AppFonts.caption,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
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