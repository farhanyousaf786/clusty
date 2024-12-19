import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/post_card.dart';
import '../../../providers/posts_provider.dart';
import '../../../utils/logger.dart';

class UserProfilePosts extends ConsumerWidget {
  final String userId;
  final ThemeData theme;
  final bool showPosts;
  final VoidCallback onTogglePosts;

  const UserProfilePosts({
    super.key,
    required this.userId,
    required this.theme,
    required this.showPosts,
    required this.onTogglePosts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Posts Section Header
        InkWell(
          onTap: onTogglePosts,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  'Posts',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const Spacer(),
                Icon(
                  showPosts ? Icons.expand_less : Icons.expand_more,
                  color: theme.primaryColor,
                ),
              ],
            ),
          ),
        ),

        // Posts Grid
        if (showPosts)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer(
              builder: (context, ref, child) {
                final userPosts = ref.watch(userPostsProvider(userId));
                
                return userPosts.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.post_add_rounded,
                                size: 48,
                                color: theme.primaryColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No posts yet',
                                style: GoogleFonts.poppins(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) => PostCard(post: posts[index]),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) {
                    Logger.e('Error loading posts', error, stack);
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Error loading posts',
                              style: GoogleFonts.poppins(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              error.toString(),
                              style: GoogleFonts.poppins(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
