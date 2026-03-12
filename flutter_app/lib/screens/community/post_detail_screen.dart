import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../models/community_model.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  String get _postRoute => '/forum/post/${widget.postId}';

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _postRoute));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard.')),
    );
  }

  void _report() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks — we’ll review this post.')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final community = context.read<CommunityProvider>();
    if (community.forumPosts.isEmpty) {
      await community.loadForumPosts();
    }
    await community.loadComments(widget.postId, isForumPost: true);
  }

  Future<void> _toggleLike(ForumPostModel post) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts.')),
      );
      context.push('/login');
      return;
    }

    final isLiked = post.likedBy.contains(user.id);
    await context
        .read<CommunityProvider>()
        .togglePostLike(post.id, user.id, isLiked);
  }

  Future<void> _sendComment(ForumPostModel post) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
      context.push('/login');
      return;
    }

    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final comment = CommentModel(
      id: '',
      recipeId: post.id,
      authorId: user.id,
      authorName: user.displayName,
      authorAvatar: user.avatarEmoji,
      authorPhotoUrl: user.photoUrl,
      content: text,
      createdAt: DateTime.now(),
    );

    final community = context.read<CommunityProvider>();
    final commentId = await community.addComment(comment, isForumPost: true);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
    });

    if (commentId != null) {
      _commentController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to post comment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.more),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyLink();
                  return;
                case 'report':
                  _report();
                  return;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'copy',
                  child: Text('Copy link'),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Text('Report'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, community, _) {
          ForumPostModel? post;
          for (final p in community.forumPosts) {
            if (p.id == widget.postId) {
              post = p;
              break;
            }
          }

          if (post == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final ForumPostModel postData = post;

          final comments = community.comments
              .where((c) =>
                  c.recipeId == widget.postId && c.parentCommentId == null)
              .toList();

          final auth = context.watch<AuthProvider>();
          final currentUser = auth.user;
          final isLiked =
              currentUser != null && postData.likedBy.contains(currentUser.id);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: post.authorPhotoUrl != null
                                ? NetworkImage(post.authorPhotoUrl!)
                                : null,
                            child: post.authorPhotoUrl == null
                                ? Text(
                                    post.authorAvatar,
                                    style: const TextStyle(fontSize: 20),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _formatTimeAgo(post.createdAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          _buildCategoryChip(post.category),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        post.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.content,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (post.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: post.tags.take(5).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _toggleLike(postData),
                            icon: Icon(
                              isLiked ? Iconsax.heart5 : Iconsax.heart,
                              color: isLiked
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${postData.likes}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Iconsax.message,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentsCount}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Iconsax.eye,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${post.views}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Comments',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (comments.isEmpty)
                        Text(
                          'No comments yet. Start the conversation!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final c = comments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      c.authorAvatar,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              c.authorName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            Text(
                                              _formatTimeAgo(c.createdAt),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      color: AppColors
                                                          .textSecondary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.content,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(postData),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed:
                          _isSending ? null : () => _sendComment(postData),
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Iconsax.send_2),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    switch (category) {
      case 'tips':
        color = Colors.green;
        break;
      case 'question':
        color = Colors.blue;
        break;
      case 'challenge':
        color = Colors.orange;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
