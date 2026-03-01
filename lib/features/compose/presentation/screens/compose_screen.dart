import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/core/constants/app_fonts.dart';
import 'package:lovepin/core/constants/app_sizes.dart';
import 'package:lovepin/core/utils/image_compressor.dart';
import 'package:lovepin/data/local/local_cache.dart';
import 'package:lovepin/data/models/template_model.dart';
import 'package:lovepin/data/supabase/message_repository.dart';
import 'package:lovepin/data/supabase/template_repository.dart';
import 'package:lovepin/features/auth/providers/auth_provider.dart';
import 'package:lovepin/features/home/presentation/screens/home_screen.dart';
import 'package:lovepin/services/widget_service.dart';

/// Provider that loads message templates.
final templatesProvider =
    FutureProvider.autoDispose<List<TemplateModel>>((ref) async {
  final repo = TemplateRepository();
  return repo.getTemplates(isPremium: false);
});

/// Compose screen where the user writes and sends a love note.
class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _sending = false;
  TemplateCategory? _selectedCategory;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (xFile == null) return;
    setState(() => _selectedImage = File(xFile.path));
  }

  Future<void> _send() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a message or add a photo')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final coupleId = LocalCache.instance.getCoupleId();
      if (coupleId == null || coupleId.isEmpty) {
        throw Exception('No couple linked');
      }

      final messageRepo = MessageRepository();

      String? imageUrl;
      String? thumbnailUrl;

      // Upload image if selected.
      if (_selectedImage != null) {
        final compressed = await ImageCompressor.compressImage(
          _selectedImage!,
        );
        final thumb = await ImageCompressor.generateThumbnail(
          _selectedImage!,
        );

        imageUrl = await messageRepo.uploadImage(compressed, coupleId);
        thumbnailUrl = await messageRepo.uploadThumbnail(thumb, coupleId);
      }

      final message = await messageRepo.sendMessage(
        coupleId: coupleId,
        senderId: user.id,
        content: content.isEmpty ? '❤️' : content,
        imageUrl: imageUrl,
        imageThumbnailUrl: thumbnailUrl,
      );

      // Update the home screen widget with sender name.
      await WidgetService.updateWidget(
        message,
        senderName: LocalCache.instance.getMyDisplayName() ?? 'Your Love',
      );

      if (!mounted) return;

      // Reset form.
      _messageController.clear();
      setState(() => _selectedImage = null);

      // Refresh message feed.
      ref.invalidate(messageFeedProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Love note sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _useTemplate(TemplateModel template) {
    _messageController.text = template.content;
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compose',
          style: GoogleFonts.caveat(
            fontSize: AppFonts.h2,
            fontWeight: AppFonts.bold,
            color: AppColors.pinkDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    child: Image.file(
                      _selectedImage!,
                      height: AppSizes.cardImageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textPrimary,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (_selectedImage != null) const SizedBox(height: 16),

            // Message text field
            TextField(
              controller: _messageController,
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write your love note...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(color: AppColors.pinkDark),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(
                    Icons.image_outlined,
                    color: AppColors.pinkDark,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Template categories
            Text(
              'Quick Templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Category chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TemplateCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.displayLabel),
                  selected: isSelected,
                  selectedColor: AppColors.pink,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? cat : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Template list
            templatesAsync.when(
              data: (templates) {
                final filtered = _selectedCategory != null
                    ? templates
                        .where((t) => t.category == _selectedCategory)
                        .toList()
                    : templates;

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLg),
                    child: Text(
                      'No templates available',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((template) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          template.content,
                          style: GoogleFonts.nunito(
                            fontSize: AppFonts.bodySmall,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        onTap: () => _useTemplate(template),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingLg),
                  child:
                      CircularProgressIndicator(color: AppColors.pinkDark),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
