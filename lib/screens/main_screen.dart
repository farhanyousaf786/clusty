import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/posts_provider.dart';
import 'create_post_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final postsState = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trending Topics',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Topic ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${1000 + index * 100} posts',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
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
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Latest Posts',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
          postsState.when(
            data: (posts) {
              if (posts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text('No posts yet'),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: post.userPhotoUrl != null
                                  ? NetworkImage(post.userPhotoUrl!)
                                  : null,
                              backgroundColor: theme.primaryColor,
                              child: post.userPhotoUrl == null
                                  ? Text(
                                      post.username[0].toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              post.username,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            subtitle: Text(
                              DateTime.fromMillisecondsSinceEpoch(post.timestamp).toString(),
                              style: GoogleFonts.poppins(
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                color: theme.primaryColor,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          if (post.imageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.network(
                                post.imageUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.content,
                                  style: GoogleFonts.poppins(
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.favorite_border,
                                      label: '${post.likes}',
                                      onPressed: () {},
                                      theme: theme,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildActionButton(
                                      icon: Icons.comment_outlined,
                                      label: '${post.comments}',
                                      onPressed: () {},
                                      theme: theme,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildActionButton(
                                      icon: Icons.share_outlined,
                                      label: 'Share',
                                      onPressed: () {},
                                      theme: theme,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Post',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: theme.primaryColor, size: 20),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: theme.primaryColor,
      ),
    );
  }
}
