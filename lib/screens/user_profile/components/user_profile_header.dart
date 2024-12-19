import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';
import '../../../utils/time_ago_utils.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Profile Picture with Glow
        Positioned(
          bottom: 60,
          left: width * 0.5 - 60,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: theme.cardColor,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.username?.isNotEmpty == true
                  ? Text(
                      user.username![0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        // Username with Glow
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Text(
                  user.username ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: theme.primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                if (user.createdAt != null)
                  Text(
                    'Joined ${TimeAgoUtils.getTimeAgo(user.createdAt)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
