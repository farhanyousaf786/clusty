import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../providers/user_provider.dart';
import '../providers/reactions_provider.dart';
import '../screens/user_profile_screen.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;
  final bool showComments;
  final VoidCallback? onCommentTap;

  const PostCard({
    super.key,
    required this.post,
    this.showComments = true,
    this.onCommentTap,
  });

  static const reactionEmojis = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😠',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userReactionAsync = ref.watch(userReactionProvider(post.id));
    final reactionsAsync = ref.watch(postReactionsProvider(post.id));
    final reactions = ref.watch(reactionsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[850]
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[800]!
              : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          if (theme.brightness == Brightness.dark)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final userAsync = ref.watch(userProvider(post.userId));
                    return userAsync.when(
                      data: (user) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: post.userId),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: user?.photoUrl == null
                              ? Text(
                                  (user?.username?[0] ?? 'U').toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: theme.colorScheme.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      loading: () => CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      error: (_, __) => CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.error.withOpacity(0.2),
                        child: Icon(Icons.error, color: theme.colorScheme.error),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final userAsync = ref.watch(userProvider(post.userId));
                          return userAsync.when(
                            data: (user) => Text(
                              user?.name?.isNotEmpty == true 
                                  ? user!.name! 
                                  : user?.username ?? 'Unknown User',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            loading: () => Container(
                              width: 100,
                              height: 16,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            error: (_, __) => Text(
                              'Unknown User',
                              style: GoogleFonts.poppins(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, y').format(
                          DateTime.fromMillisecondsSinceEpoch(post.timestamp),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Post Content
          if (post.imageUrl != null) ...[
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Actions Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                // Like button that shows reactions popup
                Consumer(
                  builder: (context, ref, child) {
                    final userReactionAsync = ref.watch(userReactionProvider(post.id));
                    final reactionsAsync = ref.watch(postReactionsProvider(post.id));
                    final reactions = ref.watch(reactionsProvider);

                    return GestureDetector(
                      onLongPressStart: (details) {
                        _showReactionsPopup(context, ref, details.globalPosition);
                      },
                      onTapUp: (details) {
                        // Toggle like on tap
                        ref.read(reactionsProvider.notifier).toggleReaction(post.id, 'like');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: userReactionAsync.when(
                            data: (reaction) => reaction != null
                                ? theme.colorScheme.primary.withOpacity(0.15)
                                : theme.brightness == Brightness.dark
                                    ? Colors.grey[800]!.withOpacity(0.5)
                                    : theme.colorScheme.surface.withOpacity(0.1),
                            loading: () => theme.brightness == Brightness.dark
                                ? Colors.grey[800]!.withOpacity(0.5)
                                : theme.colorScheme.surface.withOpacity(0.1),
                            error: (_, __) => theme.brightness == Brightness.dark
                                ? Colors.grey[800]!.withOpacity(0.5)
                                : theme.colorScheme.surface.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            userReactionAsync.when(
                              data: (reaction) => Text(
                                reaction?.type != null 
                                    ? reactionEmojis[reaction!.type]! 
                                    : '👍',
                                style: const TextStyle(fontSize: 18),
                              ),
                              loading: () => const Text('👍', style: TextStyle(fontSize: 18)),
                              error: (_, __) => const Text('👍', style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 8),
                            if (ref.read(reactionsProvider.notifier).isLoading(post.id, userReactionAsync.when(
                              data: (reaction) => reaction?.type ?? 'like',
                              loading: () => 'like',
                              error: (_, __) => 'like',
                            )))
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            else
                              Text(
                                reactionsAsync.when(
                                  data: (counts) => counts.values.fold(0, (sum, count) => sum + count).toString(),
                                  loading: () => '0',
                                  error: (_, __) => '0',
                                ),
                                style: GoogleFonts.poppins(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                if (showComments)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]!.withOpacity(0.5)
                          : theme.colorScheme.surface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${post.comments}',
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReactionsPopup(BuildContext context, WidgetRef ref, Offset position) {
    final theme = Theme.of(context);
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: theme.brightness == Brightness.dark
          ? const Color.fromARGB(255, 3, 3, 3)
          : theme.colorScheme.surface,
      elevation: theme.brightness == Brightness.dark ? 16 : 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.transparent,
          width: 1,
        ),
      ),
      items: reactionEmojis.entries.map((entry) {
        final isLoading = ref.watch(reactionsProvider.select(
          (state) => state['${post.id}:${entry.key}'] ?? false,
        ));

        return PopupMenuItem(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabled: !isLoading,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.value,
                style: const TextStyle(fontSize: 24),
              ),
              if (isLoading) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            ref.read(reactionsProvider.notifier).toggleReaction(post.id, entry.key);
          },
        );
      }).toList(),
    );
  }
}
