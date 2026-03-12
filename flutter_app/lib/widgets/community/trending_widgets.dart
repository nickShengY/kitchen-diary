import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Trending topic card
class TrendingTopicCard extends StatelessWidget {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int postCount;
  final bool isFollowing;
  final VoidCallback? onTap;
  final VoidCallback? onFollow;

  const TrendingTopicCard({
    super.key,
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.postCount = 0,
    this.isFollowing = false,
    this.onTap,
    this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCount(postCount)} posts',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Follow button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onFollow?.call();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isFollowing ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFollowing ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFollowing ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// Compact trending topic chip
class TrendingTopicChip extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isSelected;
  final VoidCallback? onTap;

  const TrendingTopicChip({
    super.key,
    required this.name,
    required this.emoji,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hashtag chip
class HashtagChip extends StatelessWidget {
  final String hashtag;
  final int? count;
  final bool isTrending;
  final VoidCallback? onTap;

  const HashtagChip({
    super.key,
    required this.hashtag,
    this.count,
    this.isTrending = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$hashtag',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
              ),
            ),
            if (isTrending) ...[
              const SizedBox(width: 4),
              const Text('🔥', style: TextStyle(fontSize: 12)),
            ],
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(count!),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// Trending hashtags section
class TrendingHashtagsSection extends StatelessWidget {
  final List<TrendingHashtag> hashtags;
  final String title;
  final Function(String)? onHashtagTap;
  final VoidCallback? onSeeAll;

  const TrendingHashtagsSection({
    super.key,
    required this.hashtags,
    this.title = 'Trending Hashtags',
    this.onHashtagTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: hashtags.asMap().entries.map((entry) {
              final hashtag = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: HashtagChip(
                  hashtag: hashtag.tag,
                  count: hashtag.count,
                  isTrending: entry.key < 3,
                  onTap: () => onHashtagTap?.call(hashtag.tag),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Trending hashtag data
class TrendingHashtag {
  final String tag;
  final int count;
  final double growthPercent;

  const TrendingHashtag({
    required this.tag,
    required this.count,
    this.growthPercent = 0,
  });
}

/// Trending posts section
class TrendingSection extends StatelessWidget {
  final String title;
  final String emoji;
  final List<Widget> children;
  final VoidCallback? onSeeAll;

  const TrendingSection({
    super.key,
    required this.title,
    required this.emoji,
    required this.children,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

/// Mention suggestion popup
class MentionSuggestionList extends StatelessWidget {
  final List<MentionSuggestion> suggestions;
  final Function(MentionSuggestion)? onSelect;

  const MentionSuggestionList({
    super.key,
    required this.suggestions,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  suggestion.emoji ?? '👨‍🍳',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            title: Text(
              suggestion.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '@${suggestion.username}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            onTap: () => onSelect?.call(suggestion),
          );
        },
      ),
    );
  }
}

/// Mention suggestion data
class MentionSuggestion {
  final String id;
  final String username;
  final String displayName;
  final String? emoji;
  final String? avatarUrl;

  const MentionSuggestion({
    required this.id,
    required this.username,
    required this.displayName,
    this.emoji,
    this.avatarUrl,
  });
}

/// Rich text with highlighted mentions and hashtags
class RichContentText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Function(String)? onMentionTap;
  final Function(String)? onHashtagTap;
  final Function(String)? onLinkTap;
  final int? maxLines;

  const RichContentText({
    super.key,
    required this.text,
    this.style,
    this.onMentionTap,
    this.onHashtagTap,
    this.onLinkTap,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ??
        const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.5,
        );

    final spans = _parseText(text, defaultStyle);

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  List<InlineSpan> _parseText(String text, TextStyle defaultStyle) {
    final List<InlineSpan> spans = [];
    final mentionRegex = RegExp(r'@(\w+)');
    final hashtagRegex = RegExp(r'#(\w+)');
    final linkRegex = RegExp(r'https?://\S+');

    int lastEnd = 0;

    // Find all matches
    final allMatches = <_ParseMatch>[];

    for (final match in mentionRegex.allMatches(text)) {
      allMatches
          .add(_ParseMatch(match.start, match.end, 'mention', match.group(1)!));
    }
    for (final match in hashtagRegex.allMatches(text)) {
      allMatches
          .add(_ParseMatch(match.start, match.end, 'hashtag', match.group(1)!));
    }
    for (final match in linkRegex.allMatches(text)) {
      allMatches
          .add(_ParseMatch(match.start, match.end, 'link', match.group(0)!));
    }

    // Sort by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    for (final match in allMatches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      final color = switch (match.type) {
        'mention' => const Color(0xFF3B82F6),
        'hashtag' => const Color(0xFF8B5CF6),
        'link' => const Color(0xFF10B981),
        _ => defaultStyle.color,
      };

      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: defaultStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        // Note: In real implementation, use WidgetSpan with GestureDetector for tap handling
      ));

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return spans;
  }
}

class _ParseMatch {
  final int start;
  final int end;
  final String type;
  final String value;

  _ParseMatch(this.start, this.end, this.type, this.value);
}
