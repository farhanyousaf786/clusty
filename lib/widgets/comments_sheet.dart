import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/comments_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/time_ago_utils.dart';
import 'shimmer_widgets.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final currentUser = ref.watch(authProvider).value;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
              ),
            ),
            Flexible(
              child: commentsAsync.when(
                data: (comments) => comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: theme.brightness == Brightness.dark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey[100],
                                  backgroundImage: comment.userPhotoUrl != null
                                      ? NetworkImage(comment.userPhotoUrl!)
                                      : null,
                                  child: comment.userPhotoUrl == null
                                      ? Text(
                                          comment.username[0].toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            color: theme.textTheme.bodyLarge?.color,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.username,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textTheme.bodyLarge?.color,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: theme.textTheme.bodyLarge?.color,
                                          height: 1.3,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              TimeAgoUtils.getTimeAgo(comment.timestamp),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.textTheme.bodyMedium?.color,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            if (comment.userId == currentUser?.id) ...[
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: () async {
                                                  try {
                                                    await ref
                                                        .read(commentsProvider.notifier)
                                                        .deleteComment(
                                                          widget.postId,
                                                          comment.id,
                                                        );
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text(e.toString())),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  size: 14,
                                                  color: theme.textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'Error loading comments',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.poppins(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                        border: InputBorder.none,
                        constraints: const BoxConstraints(
                          maxHeight: 100,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () async {
                      final content = _commentController.text.trim();
                      if (content.isEmpty) return;

                      await ref
                          .read(commentsProvider.notifier)
                          .addComment(widget.postId, content);
                      
                      if (mounted) {
                        _commentController.clear();
                        _focusNode.unfocus();
                      }
                    },
                    icon: Icon(
                      Icons.send_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
