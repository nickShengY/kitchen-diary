import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// A reaction with emoji and count
class Reaction {
  final String id;
  final String emoji;
  final String label;
  final int count;
  final bool isSelected;

  const Reaction({
    required this.id,
    required this.emoji,
    required this.label,
    this.count = 0,
    this.isSelected = false,
  });

  Reaction copyWith({int? count, bool? isSelected}) {
    return Reaction(
      id: id,
      emoji: emoji,
      label: label,
      count: count ?? this.count,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Reaction picker popup
class ReactionPicker extends StatelessWidget {
  final List<Reaction> reactions;
  final Function(String reactionId)? onReactionSelected;
  final VoidCallback? onDismiss;

  const ReactionPicker({
    super.key,
    required this.reactions,
    this.onReactionSelected,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required List<Reaction> reactions,
    required Offset position,
    Function(String)? onReactionSelected,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Picker
          Positioned(
            left: position.dx - 100,
            top: position.dy - 60,
            child: ReactionPicker(
              reactions: reactions,
              onReactionSelected: (id) {
                entry.remove();
                onReactionSelected?.call(id);
              },
              onDismiss: () => entry.remove(),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactions.asMap().entries.map((entry) {
            final index = entry.key;
            final reaction = entry.value;
            
            return _ReactionItem(
              reaction: reaction,
              onTap: () {
                HapticFeedback.selectionClick();
                onReactionSelected?.call(reaction.id);
              },
            )
                .animate(delay: Duration(milliseconds: index * 50))
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                  curve: Curves.elasticOut,
                );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 150.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class _ReactionItem extends StatefulWidget {
  final Reaction reaction;
  final VoidCallback? onTap;

  const _ReactionItem({
    required this.reaction,
    this.onTap,
  });

  @override
  State<_ReactionItem> createState() => _ReactionItemState();
}

class _ReactionItemState extends State<_ReactionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.reaction.label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          transform: Matrix4.identity()..scale(_isHovered ? 1.3 : 1.0),
          transformAlignment: Alignment.center,
          child: Text(
            widget.reaction.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}

/// Compact reaction bar showing selected reactions with counts
class ReactionBar extends StatelessWidget {
  final List<Reaction> reactions;
  final Function(String reactionId)? onReactionTap;
  final VoidCallback? onAddReaction;
  final bool showAddButton;
  final bool compact;

  const ReactionBar({
    super.key,
    required this.reactions,
    this.onReactionTap,
    this.onAddReaction,
    this.showAddButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Filter reactions with count > 0
    final activeReactions = reactions.where((r) => r.count > 0).toList();
    
    if (activeReactions.isEmpty && !showAddButton) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...activeReactions.map((reaction) => _ReactionChip(
          reaction: reaction,
          compact: compact,
          onTap: () => onReactionTap?.call(reaction.id),
        )),
        if (showAddButton)
          _AddReactionButton(
            onTap: onAddReaction,
            compact: compact,
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final Reaction reaction;
  final bool compact;
  final VoidCallback? onTap;

  const _ReactionChip({
    required this.reaction,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: reaction.isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: reaction.isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reaction.emoji,
              style: TextStyle(fontSize: compact ? 14 : 16),
            ),
            const SizedBox(width: 4),
            Text(
              _formatCount(reaction.count),
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: reaction.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: reaction.isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _AddReactionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool compact;

  const _AddReactionButton({
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_reaction_outlined,
              size: compact ? 14 : 16,
              color: AppColors.textSecondary,
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              const Text(
                'React',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Social action bar with like, comment, share buttons
class SocialActionBar extends StatelessWidget {
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const SocialActionBar({
    super.key,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_outline,
          label: _formatCount(likes),
          color: isLiked ? Colors.red : null,
          onTap: onLike,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(comments),
          onTap: onComment,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.share_outlined,
          label: shares > 0 ? _formatCount(shares) : null,
          onTap: onShare,
        ),
        const Spacer(),
        _ActionButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
          color: isBookmarked ? AppColors.primary : null,
          onTap: onBookmark,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '';
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: color ?? AppColors.textSecondary,
          ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

