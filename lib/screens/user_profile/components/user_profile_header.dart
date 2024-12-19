import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';
import '../../../utils/time_ago_utils.dart';
import 'user_profile_stats.dart';

class UserProfileHeader extends StatelessWidget {
  final UserModel user;
  final ThemeData theme;
  final double width;

  const UserProfileHeader({
    super.key,
    required this.user,
    required this.theme,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: theme.primaryColor,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.username?.isNotEmpty == true
                          ? user.username![0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            user.name ?? 'Anonymous',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@${user.username ?? 'anonymous'}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white70,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
 
        ],
      ),
    );
  }
}
