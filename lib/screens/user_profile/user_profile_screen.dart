import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/posts_provider.dart';
import '../../widgets/animated_background.dart';
import '../../utils/time_ago_utils.dart';
import '../../utils/logger.dart';
import 'components/user_profile_header.dart';
import 'components/user_profile_stats.dart';
import 'components/user_profile_posts.dart';
import 'components/user_profile_rating.dart';
import 'components/user_profile_actions.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({required this.userId, super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> with SingleTickerProviderStateMixin {
  bool _showPosts = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _togglePosts() {
    setState(() {
      _showPosts = !_showPosts;
    });
  }

  Future<void> _showRatingDialog(UserModel user) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you rate this profile?'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return IconButton(
                  icon: Icon(
                    rating <= user.rating ? Icons.star : Icons.star_border,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    _submitRating(user.id, rating.toDouble());
                    Navigator.pop(context);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(String userId, double rating) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    final databaseRef = FirebaseDatabase.instance.ref();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Add rating with timestamp only
    await databaseRef.child('ratings/$userId/${currentUser.id}').set({
      'rating': rating,
      'timestamp': timestamp,
    });

    // Update average rating
    final ratingsSnapshot = await databaseRef.child('ratings/$userId').get();
    if (ratingsSnapshot.exists) {
      final ratingsMap = Map<String, dynamic>.from(ratingsSnapshot.value as Map);
      double totalRating = 0;
      int count = 0;

      ratingsMap.forEach((key, value) {
        if (value is Map && value['rating'] != null) {
          totalRating += (value['rating'] as num).toDouble();
          count++;
        }
      });

      final averageRating = totalRating / count;
      await databaseRef.child('users/$userId').update({
        'rating': averageRating,
        'ratingCount': count,
      });
    }
  }

  String _formatDate(int timestamp) {
    return TimeAgoUtils.getTimeAgo(timestamp);
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade400;
    if (rating >= 4.0) return Colors.lightGreen.shade400;
    if (rating >= 3.0) return Colors.orange.shade400;
    if (rating >= 2.0) return Colors.deepOrange.shade400;
    return Colors.red.shade400;
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

  Future<void> _showRatingDetailsDialog(UserModel user) async {
    final currentUser = ref.read(authProvider).value;
    final databaseRef = FirebaseDatabase.instance.ref();
    
    // Get all ratings
    final ratingsSnapshot = await databaseRef.child('ratings/${user.id}').get();
    final List<Map<String, dynamic>> ratingsList = [];
    
    if (ratingsSnapshot.exists) {
      final ratingsMap = Map<String, dynamic>.from(ratingsSnapshot.value as Map);
      ratingsMap.forEach((key, value) {
        if (value is Map) {
          final rating = Map<String, dynamic>.from(value);
          rating['userId'] = key;
          ratingsList.add(rating);
        }
      });
    }
    
    // Sort ratings by timestamp
    ratingsList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    // Check if current user can rate
    bool canRate = true;
    String? timeLeftMessage;
    
    if (currentUser != null) {
      final userRating = ratingsList.firstWhere(
        (r) => r['userId'] == currentUser.id,
        orElse: () => {},
      );
      
      if (userRating.isNotEmpty) {
        final lastRatingTime = DateTime.fromMillisecondsSinceEpoch(userRating['timestamp'] as int);
        final timeSinceLastRating = DateTime.now().difference(lastRatingTime);
        
        if (timeSinceLastRating.inHours < 24) {
          canRate = false;
          final hoursLeft = 24 - timeSinceLastRating.inHours;
          timeLeftMessage = 'You can rate again in $hoursLeft hours';
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Rating Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: CircularProgressIndicator(
                              value: user.rating / 5,
                              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getRatingColor(user.rating),
                              ),
                              strokeWidth: 6,
                            ),
                          ),
                          Text(
                            user.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getRatingColor(user.rating),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Rating',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showRatingsList(ratingsList);
                          },
                          child: Text(
                            '${user.ratingCount} ${user.ratingCount == 1 ? 'rating' : 'ratings'}',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (currentUser != null && currentUser.id != user.id) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return IconButton(
                      icon: Icon(
                        rating <= user.rating ? Icons.star : Icons.star_border,
                        color: _getRatingColor(user.rating),
                        size: 32,
                      ),
                      onPressed: () {
                        if (!canRate && timeLeftMessage != null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                timeLeftMessage,
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                          return;
                        }
                        _submitRating(user.id, rating.toDouble());
                        Navigator.pop(context);
                      },
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingsList(List<Map<String, dynamic>> ratings) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    
    // Fetch user details for each rating
    for (var rating in ratings) {
      final userId = rating['userId'] as String;
      final userSnapshot = await databaseRef.child('users/$userId').get();
      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        rating['raterUsername'] = userData['username'] as String?;
        rating['raterPhotoUrl'] = userData['photoUrl'] as String?;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'All Ratings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
              final timestampInt = rating['timestamp'] as int;
              final ratingValue = (rating['rating'] as num).toDouble();
              final username = rating['raterUsername'] as String?;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: rating['raterPhotoUrl'] != null
                      ? NetworkImage(rating['raterPhotoUrl'] as String)
                      : null,
                  child: rating['raterPhotoUrl'] == null
                      ? Text(
                          username?[0].toUpperCase() ?? 'A',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  username ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  TimeAgoUtils.getTimeAgo(timestampInt),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: _getRatingColor(ratingValue),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ratingValue.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: _getRatingColor(ratingValue),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
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
          body: AnimatedBackground(
            color: theme.primaryColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar with Profile Header
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: UserProfileHeader(
                      user: user,
                      theme: theme,
                      width: size.width,
                    ),
                  ),
                ),

                // Stats and Actions Section
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: UserProfileStats(
                            user: user,
                            theme: theme,
                            onRatingTap: () => _showRatingDetailsDialog(user),
                          ),
                        ),
                        UserProfileActions(userId: widget.userId, theme: theme),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: UserProfileRating(
                            user: user,
                            theme: theme,
                            onRatePressed: () => _showRatingDialog(user),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Posts Section
                SliverToBoxAdapter(
                  child: UserProfilePosts(
                    userId: widget.userId,
                    theme: theme,
                    showPosts: _showPosts,
                    onTogglePosts: _togglePosts,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              shadows: [
                Shadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 14,
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
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
