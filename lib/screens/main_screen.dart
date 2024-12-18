import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/user_provider.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'user_profile_screen.dart';

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
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Clusty',
                style: GoogleFonts.poppins(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: theme.primaryColor,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: theme.primaryColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
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
                            leading: Consumer(
                              builder: (context, ref, child) {
                                final userAsync = ref.watch(userProvider(post.userId));
                                return userAsync.when(
                                  data: (user) => CircleAvatar(
                                    backgroundImage: user?.photoUrl != null
                                        ? NetworkImage(user!.photoUrl!)
                                        : null,
                                    backgroundColor: theme.primaryColor,
                                    child: user?.photoUrl == null
                                        ? Text(
                                            (user?.username?[0] ?? 'U').toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  loading: () => CircleAvatar(
                                    backgroundColor: theme.primaryColor,
                                    child: const CircularProgressIndicator(),
                                  ),
                                  error: (_, __) => CircleAvatar(
                                    backgroundColor: theme.primaryColor,
                                    child: const Icon(Icons.error),
                                  ),
                                );
                              },
                            ),
                            title: Consumer(
                              builder: (context, ref, child) {
                                final userAsync = ref.watch(userProvider(post.userId));
                                return userAsync.when(
                                  data: (user) => Text(
                                    user?.name?.isNotEmpty == true 
                                        ? user!.name! 
                                        : user?.username ?? 'Unknown User',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  loading: () => Text(
                                    'Loading...',
                                    style: GoogleFonts.poppins(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    'Unknown User',
                                    style: GoogleFonts.poppins(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                );
                              },
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(userId: post.userId),
                                ),
                              );
                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: theme.primaryColor,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
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
