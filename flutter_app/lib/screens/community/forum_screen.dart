import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../models/community_model.dart';

enum _ForumSort { latest, top, mostDiscussed }

enum _PostAction { copyLink, hide, report }

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  final Set<String> _hiddenPostIds = <String>{};

  bool _isSearching = false;
  _ForumSort _sort = _ForumSort.latest;

  final List<String> _categories = [
    'All',
    'Tips',
    'Questions',
    'Discussion',
    'Challenges'
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadPosts() {
    context.read<CommunityProvider>().loadForumPosts(
          category: _selectedCategory == 'All'
              ? null
              : _selectedCategory.toLowerCase(),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CommunityProvider>().loadMoreForumPosts();
    }
  }

  String _postRoute(ForumPostModel post) => '/forum/post/${post.id}';

  Future<void> _copyPostLink(ForumPostModel post) async {
    await Clipboard.setData(ClipboardData(text: _postRoute(post)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard.')),
    );
  }

  void _reportPost(ForumPostModel post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks — we’ll review this post.')),
    );
  }

  void _hidePost(ForumPostModel post) {
    if (_hiddenPostIds.contains(post.id)) return;
    setState(() {
      _hiddenPostIds.add(post.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post hidden.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _hiddenPostIds.remove(post.id);
            });
          },
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search posts',
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            : const Text('Community Forum'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _isSearching ? Iconsax.close_circle : Iconsax.search_normal),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          PopupMenuButton<_ForumSort>(
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (value) {
              setState(() {
                _sort = value;
              });
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _ForumSort.latest,
                  child: Text('Latest'),
                ),
                PopupMenuItem(
                  value: _ForumSort.top,
                  child: Text('Top'),
                ),
                PopupMenuItem(
                  value: _ForumSort.mostDiscussed,
                  child: Text('Most discussed'),
                ),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
          onTap: (index) {
            setState(() => _selectedCategory = _categories[index]);
            _loadPosts();
          },
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
        ),
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.forumPosts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.forumPosts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  provider.errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final query = _searchController.text.trim().toLowerCase();
          var posts = List<ForumPostModel>.of(provider.forumPosts);
          if (query.isNotEmpty) {
            posts = posts.where(
              (p) {
                final title = p.title.toLowerCase();
                final content = p.content.toLowerCase();
                final tags = p.tags.map((t) => t.toLowerCase()).join(' ');
                return title.contains(query) ||
                    content.contains(query) ||
                    tags.contains(query);
              },
            ).toList();
          }

          posts = posts.where((p) => !_hiddenPostIds.contains(p.id)).toList();

          posts.sort((a, b) {
            final pinnedA = a.isPinned ? 1 : 0;
            final pinnedB = b.isPinned ? 1 : 0;
            final pinnedCmp = pinnedB.compareTo(pinnedA);
            if (pinnedCmp != 0) return pinnedCmp;

            switch (_sort) {
              case _ForumSort.top:
                return b.likes.compareTo(a.likes);
              case _ForumSort.mostDiscussed:
                return b.commentsCount.compareTo(a.commentsCount);
              case _ForumSort.latest:
                return b.createdAt.compareTo(a.createdAt);
            }
          });

          if (posts.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadPosts(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return provider.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox(height: 80);
                }

                final post = posts[index];
                return _buildPostCard(post, index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/forum/create'),
        icon: const Icon(Iconsax.add),
        label: const Text('New Post'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = _searchController.text.trim();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💬', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            query.isNotEmpty ? 'No results' : 'No posts yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            query.isNotEmpty
                ? 'Try a different search.'
                : 'Be the first to start a discussion!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(ForumPostModel post, int index) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final isLiked =
        currentUserId != null && post.likedBy.contains(currentUserId);
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(_postRoute(post)),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: scheme.primary.withValues(alpha: 0.10),
                      child: Text(
                        post.authorAvatar,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatTimeAgo(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<_PostAction>(
                      icon: Icon(
                        Iconsax.more,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case _PostAction.copyLink:
                            _copyPostLink(post);
                            return;
                          case _PostAction.hide:
                            _hidePost(post);
                            return;
                          case _PostAction.report:
                            _reportPost(post);
                            return;
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: _PostAction.copyLink,
                            child: Text('Copy link'),
                          ),
                          PopupMenuItem(
                            value: _PostAction.hide,
                            child: Text('Hide'),
                          ),
                          PopupMenuItem(
                            value: _PostAction.report,
                            child: Text('Report'),
                          ),
                        ];
                      },
                    ),
                    if (post.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                      ),
                    _buildCategoryChip(post.category),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: post.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: scheme.onSecondaryContainer,
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
                    _buildInteractionButton(
                      icon: isLiked ? Iconsax.heart5 : Iconsax.heart,
                      label: '${post.likes}',
                      color: isLiked ? scheme.error : scheme.onSurfaceVariant,
                      onTap: () => _toggleLike(post),
                    ),
                    const SizedBox(width: 16),
                    _buildInteractionButton(
                      icon: Iconsax.message,
                      label: '${post.commentsCount}',
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    _buildInteractionButton(
                      icon: Iconsax.eye,
                      label: '${post.views}',
                      color: scheme.onSurfaceVariant,
                    ),
                    const Spacer(),
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
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

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: content,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
