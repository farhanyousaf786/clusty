import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/posts_provider.dart';
import '../utils/logger.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({required this.userId, super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _showPosts = false;

  void _togglePosts() {
    setState(() {
      _showPosts = !_showPosts;
    });
  }

  Future<void> _toggleFollow() async {
    try {
      final isFollowing = await ref.read(postsProvider.notifier).isFollowing(widget.userId);
      if (isFollowing) {
        await ref.read(postsProvider.notifier).unfollowUser(widget.userId);
      } else {
        await ref.read(postsProvider.notifier).followUser(widget.userId);
      }
    } catch (e) {
      Logger.e('Error toggling follow', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final userState = ref.watch(userProvider(widget.userId));
    final currentUser = ref.watch(authProvider).value;
    final size = MediaQuery.of(context).size;

    return userState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Profile Header
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: theme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Profile Picture
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Hero(
                            tag: 'profile_${user.id}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: theme.cardColor,
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        // Username
                        Positioned(
                          bottom: 35,
                          left: 140,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (user.createdAt != null)
                                Text(
                                  'Joined ${_formatDate(user.createdAt!)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // User Info Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Section
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatsCard('Posts', user.postsCount.toString(), theme),
                          _buildStatsCard('Followers', user.followersCount.toString(), theme),
                          _buildStatsCard('Following', user.followingCount.toString(), theme),
                        ],
                      ),
                    ),

                    // Follow Button
                    if (currentUser != null && currentUser.id != user.id)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: FutureBuilder<bool>(
                          future: ref.read(postsProvider.notifier).isFollowing(user.id),
                          builder: (context, snapshot) {
                            final isFollowing = snapshot.data ?? false;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing
                                      ? theme.cardColor
                                      : theme.primaryColor,
                                  foregroundColor: isFollowing
                                      ? theme.primaryColor
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    side: isFollowing
                                        ? BorderSide(color: theme.primaryColor)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // About Section
                    if (user.about != null && user.about!.isNotEmpty)
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.about!,
                              style: GoogleFonts.poppins(
                                color: theme.textTheme.bodyMedium?.color,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Posts Section Header
                    InkWell(
                      onTap: _togglePosts,
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
                              _showPosts ? Icons.expand_less : Icons.expand_more,
                              color: theme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Posts Grid
              if (_showPosts)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: Consumer(
                    builder: (context, ref, child) {
                      final userPosts = ref.watch(userPostsProvider(widget.userId));
                      
                      return userPosts.when(
                        data: (posts) {
                          if (posts.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Center(
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
                              ),
                            );
                          }
                          
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final post = posts[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (post.imageUrl != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(15),
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: Image.network(
                                              post.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                Logger.e('Error loading image', error, stackTrace);
                                                return Container(
                                                  color: theme.primaryColor.withOpacity(0.1),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.error_outline,
                                                      color: theme.primaryColor,
                                                      size: 32,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                                                  backgroundImage: user.photoUrl != null
                                                      ? NetworkImage(user.photoUrl!)
                                                      : null,
                                                  child: user.photoUrl == null
                                                      ? Text(
                                                          user.username[0].toUpperCase(),
                                                          style: GoogleFonts.poppins(
                                                            color: theme.primaryColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        user.username,
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w600,
                                                          color: theme.textTheme.titleMedium?.color,
                                                        ),
                                                      ),
                                                      if (post.timestamp != null)
                                                        Text(
                                                          _formatDate(post.timestamp!),
                                                          style: GoogleFonts.poppins(
                                                            color: theme.textTheme.bodySmall?.color,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              post.content,
                                              style: GoogleFonts.poppins(
                                                color: theme.textTheme.bodyLarge?.color,
                                                fontSize: 15,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Row(
                                              children: [
                                                _buildPostStat(
                                                  Icons.favorite_rounded,
                                                  post.likes ?? 0,
                                                  theme,
                                                  onTap: () {
                                                    // TODO: Implement like functionality
                                                  },
                                                ),
                                                const SizedBox(width: 20),
                                                _buildPostStat(
                                                  Icons.comment_rounded,
                                                  post.comments ?? 0,
                                                  theme,
                                                  onTap: () {
                                                    // TODO: Implement comment functionality
                                                  },
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
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                        error: (error, stack) {
                          Logger.e('Error loading posts', error, stack);
                          return SliverToBoxAdapter(
                            child: Center(
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
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostStat(IconData icon, int count, ThemeData theme, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                color: theme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
