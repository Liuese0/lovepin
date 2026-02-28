import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/core/constants/app_fonts.dart';
import 'package:lovepin/core/constants/app_sizes.dart';
import 'package:lovepin/core/utils/date_formatter.dart';
import 'package:lovepin/data/local/local_cache.dart';
import 'package:lovepin/data/models/message_model.dart';
import 'package:lovepin/data/supabase/message_repository.dart';
import 'package:lovepin/features/auth/providers/auth_provider.dart';

/// Riverpod provider that fetches the message feed for the current couple.
final messageFeedProvider =
    FutureProvider.autoDispose<List<MessageModel>>((ref) async {
  final coupleId = LocalCache.instance.getCoupleId();
  if (coupleId == null || coupleId.isEmpty) return [];

  final repo = MessageRepository();
  final messages = await repo.getMessages(coupleId);

  // Cache for offline use.
  await LocalCache.instance.saveMessages(messages);

  return messages;
});

/// Home screen showing the message feed between the couple.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messageFeedProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lovepin',
          style: GoogleFonts.caveat(
            fontSize: AppFonts.h1,
            fontWeight: AppFonts.bold,
            color: AppColors.pinkDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppColors.pink,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: GoogleFonts.caveat(
                      fontSize: 24,
                      fontWeight: AppFonts.semiBold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send your first love note!',
                    style: GoogleFonts.nunito(
                      fontSize: AppFonts.bodySmall,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.pinkDark,
            onRefresh: () => ref.refresh(messageFeedProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLg,
                vertical: AppSizes.paddingSm,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMine = message.senderId == currentUser?.id;
                return _MessageCard(message: message, isMine: isMine);
              },
            ),
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
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(messageFeedProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single message card in the feed, styled as a polaroid-like card.
class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.isMine,
  });

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: AppSizes.messageMaxWidth),
        margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
        padding: const EdgeInsets.all(AppSizes.messagePadding),
        decoration: BoxDecoration(
          color: isMine ? AppColors.pink : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if any)
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Image.network(
                    message.imageUrl!,
                    height: AppSizes.messageImageMaxHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: AppColors.cream,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),

            // Content text
            Text(
              message.content,
              style: GoogleFonts.nunito(
                fontSize: AppFonts.bodySize,
                color: AppColors.textPrimary,
                height: AppFonts.lineHeightNormal,
              ),
            ),
            const SizedBox(height: AppSizes.messageTimestampSpacing),

            // Timestamp and read status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.formatRelative(message.createdAt),
                  style: GoogleFonts.nunito(
                    fontSize: AppFonts.tiny,
                    color: AppColors.textHint,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? AppColors.pinkDark
                        : AppColors.textHint,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
