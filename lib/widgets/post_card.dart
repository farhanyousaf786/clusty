import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/reaction_type.dart';
import '../providers/auth_provider.dart';
import '../providers/comments_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/reactions_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/comments_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/time_ago_utils.dart';
import '../widgets/shimmer_widget.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/comments_sheet.dart';

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

  void _showPostOptions(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.userId == currentUser.id)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Post'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(postsProvider.notifier).deletePost(post.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final currentUser = ref.watch(authProvider).value;
    final reactionsState = ref.watch(reactionsProvider);
    final commentsAsync = ref.watch(postCommentsProvider(post.id));
    final userReaction = currentUser?.id != null
        ? reactionsState.reactions
            .where((r) => r.userId == currentUser?.id && r.postId == post.id)
            .firstOrNull
        : null;

    final postReactions = reactionsState.reactions
        .where((r) => r.postId == post.id)
        .toList();

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
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _showPostOptions(context, ref),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Like button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: userReaction?.type == ReactionType.like
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () async {
                        if (userReaction?.type == ReactionType.like) {
                          await ref.read(reactionsProvider.notifier).removeReaction(post.id);
                        } else {
                          await ref.read(reactionsProvider.notifier).addReaction(
                                post.id,
                                ReactionType.like,
                              );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      postReactions
                          .where((r) => r.type == ReactionType.like)
                          .length
                          .toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Comment button and count
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.comment,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CommentsSheet(postId: post.id),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      commentsAsync.when(
                        data: (comments) => comments.length.toString(),
                        loading: () => '...',
                        error: (_, __) => '0',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
