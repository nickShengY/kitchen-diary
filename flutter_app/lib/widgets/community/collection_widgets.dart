import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';

/// Recipe collection card with cover grid
class CollectionCard extends StatelessWidget {
  final String id;
  final String name;
  final String emoji;
  final List<String> coverImages;
  final int itemCount;
  final bool isPublic;
  final bool isCollaborative;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const CollectionCard({
    super.key,
    required this.id,
    required this.name,
    required this.emoji,
    this.coverImages = const [],
    this.itemCount = 0,
    this.isPublic = true,
    this.isCollaborative = false,
    this.onTap,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover grid
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: _buildCoverGrid(),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isPublic) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                            ],
                            if (isCollaborative) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.group_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$itemCount recipes',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onMore != null)
                    IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: onMore,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverGrid() {
    if (coverImages.isEmpty) {
      return Container(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'No recipes yet',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (coverImages.length == 1) {
      return CachedNetworkImage(
        imageUrl: coverImages[0],
        fit: BoxFit.cover,
      );
    }

    if (coverImages.length == 2) {
      return Row(
        children: coverImages
            .map((url) => Expanded(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                ))
            .toList(),
      );
    }

    // 3+ images - 2x2 grid
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: coverImages[0],
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: coverImages[1],
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: coverImages[2],
                  fit: BoxFit.cover,
                ),
              ),
              if (coverImages.length > 3) ...[
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: coverImages[3],
                        fit: BoxFit.cover,
                      ),
                      if (coverImages.length > 4)
                        Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: Center(
                            child: Text(
                              '+${coverImages.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else
                Expanded(child: Container(color: AppColors.surface)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact collection chip for selection
class CollectionChip extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isSelected;
  final int? itemCount;
  final VoidCallback? onTap;

  const CollectionChip({
    super.key,
    required this.name,
    required this.emoji,
    this.isSelected = false,
    this.itemCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (itemCount != null)
                  Text(
                    '$itemCount recipes',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Save to collection bottom sheet
class SaveToCollectionSheet extends StatefulWidget {
  final List<CollectionOption> collections;
  final Set<String> selectedIds;
  final Function(Set<String>)? onSave;
  final VoidCallback? onCreateNew;

  const SaveToCollectionSheet({
    super.key,
    required this.collections,
    this.selectedIds = const {},
    this.onSave,
    this.onCreateNew,
  });

  static Future<Set<String>?> show(
    BuildContext context, {
    required List<CollectionOption> collections,
    Set<String> selectedIds = const {},
    VoidCallback? onCreateNew,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveToCollectionSheet(
        collections: collections,
        selectedIds: selectedIds,
        onCreateNew: onCreateNew,
      ),
    );
  }

  @override
  State<SaveToCollectionSheet> createState() => _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState extends State<SaveToCollectionSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    const Text(
                      'Save to Collection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.onCreateNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Collections list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.collections.length,
                  itemBuilder: (context, index) {
                    final collection = widget.collections[index];
                    final isSelected = _selected.contains(collection.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CollectionChip(
                        name: collection.name,
                        emoji: collection.emoji,
                        itemCount: collection.itemCount,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.remove(collection.id);
                            } else {
                              _selected.add(collection.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              // Save button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _selected.isEmpty
                            ? 'Remove from all'
                            : 'Save to ${_selected.length} collection${_selected.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Collection option data
class CollectionOption {
  final String id;
  final String name;
  final String emoji;
  final int itemCount;
  final bool isDefault;

  const CollectionOption({
    required this.id,
    required this.name,
    required this.emoji,
    this.itemCount = 0,
    this.isDefault = false,
  });
}

/// Create collection dialog
class CreateCollectionDialog extends StatefulWidget {
  final Function(String name, String emoji, bool isPublic)? onCreate;

  const CreateCollectionDialog({
    super.key,
    this.onCreate,
  });

  static Future<void> show(
    BuildContext context, {
    Function(String name, String emoji, bool isPublic)? onCreate,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CreateCollectionDialog(onCreate: onCreate),
    );
  }

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '📚';
  bool _isPublic = true;

  final _emojis = ['📚', '❤️', '🎯', '✨', '⭐', '🍳', '🍔', '🍰', '🔥', '💪'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Collection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 20),

            // Name input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g., Weekend Brunch',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Emoji picker
            const Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Privacy toggle
            Row(
              children: [
                Icon(
                  _isPublic ? Icons.public : Icons.lock_outline,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isPublic ? 'Public collection' : 'Private collection',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                  activeColor: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isNotEmpty) {
                        widget.onCreate?.call(
                          _nameController.text,
                          _selectedEmoji,
                          _isPublic,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
