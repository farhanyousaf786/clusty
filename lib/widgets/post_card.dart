import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reaction_type.dart';
import '../providers/auth_provider.dart';
import '../providers/reactions_provider.dart';
import '../providers/comments_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/comments_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/time_ago_utils.dart';
import '../widgets/shimmer_widget.dart';
import '../widgets/comments_bottom_sheet.dart';

class PostCard extends ConsumerWidget {
  final dynamic post;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onDelete,
  });

  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  void _deletePost(BuildContext context) {
    onDelete?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final currentUser = ref.watch(authProvider).value;
    final reactionsAsync = ref.watch(postReactionsProvider(post.id));
    final userReactionAsync = ref.watch(userReactionProvider(post.id));
    final reactions = ref.watch(reactionsProvider);

    return Card(
      color: theme.colorScheme.surfaceVariant,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: theme.colorScheme.surfaceVariant,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context, post.userId),
                  child: CircleAvatar(
                    backgroundImage: post.userPhotoUrl != null
                        ? NetworkImage(post.userPhotoUrl!)
                        : null,
                    child: post.userPhotoUrl == null
                        ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(context, post.userId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          TimeAgoUtils.getTimeAgo(post.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: Icon(
                    post.category.icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    post.category.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (post.userId == currentUser?.id)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                post.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Image
          if (post.imageUrl != null)
            GestureDetector(
              onTap: () => _showFullImage(context, post.imageUrl!),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                width: double.infinity,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Footer
          Container(
            color: theme.colorScheme.surfaceVariant,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.thumb_up,
                  label: reactionsAsync.when(
                    data: (reactions) => reactions
                        .where((r) => r.type == ReactionType.like)
                        .length
                        .toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  isActive: userReactionAsync?.type == ReactionType.like,
                  onTap: () async {
                    final hasReacted = userReactionAsync?.type == ReactionType.like;
                    if (hasReacted) {
                      await ref.read(reactionsProvider.notifier).removeReaction(post.id);
                    } else {
                      await ref.read(reactionsProvider.notifier).addReaction(
                            post.id,
                            ReactionType.like,
                          );
                    }
                  },
                  theme: theme,
                ),
                _buildActionButton(
                  icon: Icons.comment,
                  label: ref.watch(postCommentsProvider(post.id)).when(
                    data: (comments) => comments.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  isActive: false,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsBottomSheet(
                        postId: post.id,
                      ),
                    );
                  },
                  theme: theme,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  isActive: false,
                  onTap: () {},
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required dynamic label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label is String ? label : label.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
