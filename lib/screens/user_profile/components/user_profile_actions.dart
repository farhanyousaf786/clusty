import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/posts_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/logger.dart';

class UserProfileActions extends ConsumerStatefulWidget {
  final String userId;
  final ThemeData theme;

  const UserProfileActions({
    super.key,
    required this.userId,
    required this.theme,
  });

  @override
  ConsumerState<UserProfileActions> createState() => _UserProfileActionsState();
}

class _UserProfileActionsState extends ConsumerState<UserProfileActions> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    try {
      final isFollowing = await ref.read(postsProvider.notifier).isFollowing(widget.userId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      Logger.e('Error checking follow status', e);
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await ref.read(postsProvider.notifier).unfollowUser(widget.userId);
      } else {
        await ref.read(postsProvider.notifier).followUser(widget.userId);
      }
      // Update local state
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
      // Invalidate the followers count
      ref.invalidate(postsProvider);
    } catch (e) {
      Logger.e('Error toggling follow', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).value;
    
    // Don't show actions if viewing own profile
    if (currentUser?.id == widget.userId) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _toggleFollow,
            icon: Icon(_isFollowing ? Icons.person : Icons.person_add),
            label: Text(
              _isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? widget.theme.cardColor : widget.theme.primaryColor,
              foregroundColor: _isFollowing ? widget.theme.primaryColor : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: _isFollowing 
                  ? BorderSide(color: widget.theme.primaryColor)
                  : BorderSide.none,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement message functionality
            },
            icon: const Icon(Icons.message),
            label: Text(
              'Message',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.cardColor,
              foregroundColor: widget.theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
