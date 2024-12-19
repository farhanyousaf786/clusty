import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/post_model.dart';
import '../models/reaction_type.dart';
import '../providers/reactions_provider.dart';
import '../providers/comments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/user_profile/user_profile_screen.dart';
import '../providers/theme_provider.dart';
import '../utils/time_ago_utils.dart';
import 'shimmer_widgets.dart';
import 'comments_sheet.dart'; // Import the CommentsSheet widget

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
    'like': '',
    'love': '',
    'haha': '',
    'wow': '',
    'sad': '',
    'angry': '',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final userReactionAsync = ref.watch(userReactionProvider(post.id));
    final reactionsAsync = ref.watch(postReactionsProvider(post.id));
    final reactions = ref.watch(reactionsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[100],
                            child: Text(
                              (user?.username?[0] ?? 'U').toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      loading: () => ShimmerAvatar(radius: 20),
                      error: (_, __) => CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[100],
                        child: Text(
                          'U',
                          style: GoogleFonts.poppins(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                              user?.username ?? 'Unknown User',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                                letterSpacing: -0.3,
                              ),
                            ),
                            loading: () => ShimmerText(width: 120, height: 20),
                            error: (_, __) => Text(
                              'Unknown User',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                                letterSpacing: -0.3,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TimeAgoUtils.getTimeAgo(post.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                post.content,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          if (post.imageUrl != null)
            Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: userReactionAsync?.type == ReactionType.like
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: userReactionAsync?.type == ReactionType.like
                            ? theme.colorScheme.primary.withOpacity(0.5)
                            : theme.brightness == Brightness.dark
                                ? const Color(0xFF3A3A3A)
                                : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          userReactionAsync?.type == ReactionType.like
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 18,
                          color: userReactionAsync?.type == ReactionType.like
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reactionsAsync.when(
                            data: (reactions) => reactions
                                .where((r) => r.type == ReactionType.like)
                                .length
                                .toString(),
                            loading: () => '...',
                            error: (_, __) => '0',
                          ),
                          style: TextStyle(
                            color: userReactionAsync?.type == ReactionType.like
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final hasReacted = userReactionAsync?.type == ReactionType.love;
                    if (hasReacted) {
                      await ref.read(reactionsProvider.notifier).removeReaction(post.id);
                    } else {
                      await ref.read(reactionsProvider.notifier).addReaction(
                            post.id,
                            ReactionType.love,
                          );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: userReactionAsync?.type == ReactionType.love
                          ? Colors.red.withOpacity(0.1)
                          : theme.brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: userReactionAsync?.type == ReactionType.love
                            ? Colors.red.withOpacity(0.5)
                            : theme.brightness == Brightness.dark
                                ? const Color(0xFF3A3A3A)
                                : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          userReactionAsync?.type == ReactionType.love
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: userReactionAsync?.type == ReactionType.love
                              ? Colors.red
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reactionsAsync.when(
                            data: (reactions) => reactions
                                .where((r) => r.type == ReactionType.love)
                                .length
                                .toString(),
                            loading: () => '...',
                            error: (_, __) => '0',
                          ),
                          style: TextStyle(
                            color: userReactionAsync?.type == ReactionType.love
                                ? Colors.red
                                : theme.textTheme.bodyMedium?.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: CommentsSheet(postId: post.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF3A3A3A)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 6),
                        Consumer(
                          builder: (context, ref, child) {
                            final commentsAsync = ref.watch(postCommentsProvider(post.id));
                            return Text(
                              commentsAsync.when(
                                data: (comments) => comments.length.toString(),
                                loading: () => '...',
                                error: (_, __) => '0',
                              ),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.3,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerAvatar extends StatelessWidget {
  final double radius;

  const ShimmerAvatar({Key? key, required this.radius}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

class ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerText({Key? key, required this.width, required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
