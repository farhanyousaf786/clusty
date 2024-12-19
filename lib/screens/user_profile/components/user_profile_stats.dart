import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../utils/time_ago_utils.dart';

class UserProfileStats extends StatelessWidget {
  final UserModel user;
  final ThemeData theme;
  final VoidCallback onRatingTap;

  const UserProfileStats({
    super.key,
    required this.user,
    required this.theme,
    required this.onRatingTap,
  });

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade400;
    if (rating >= 4.0) return Colors.lightGreen.shade400;
    if (rating >= 3.0) return Colors.orange.shade400;
    if (rating >= 2.0) return Colors.deepOrange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats Row
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Rating Circle
              Column(
                children: [
                  GestureDetector(
                    onTap: onRatingTap,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getRatingColor(user.rating).withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
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
                                backgroundColor: theme.dividerColor.withOpacity(0.2),
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
                  ),
                ],
              ),
              _buildStatsItem('Following', '${user.followingCount ?? 0}'),
              _buildStatsItem('Followers', '${user.followersCount ?? 0}'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // About Section
        if (user.about?.isNotEmpty == true || user.dob != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.about?.isNotEmpty == true) ...[
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
                  if (user.dob != null) const SizedBox(height: 16),
                ],
                if (user.dob != null) ...[
                  Row(
                    children: [
                      Icon(Icons.cake, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Born ${DateFormat.yMMMMd().format(DateTime.fromMillisecondsSinceEpoch(user.dob!))}',
                        style: GoogleFonts.poppins(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Joined ${TimeAgoUtils.getTimeAgo(user.createdAt ?? 0)}',
                      style: GoogleFonts.poppins(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.photo_library, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '${user.postsCount ?? 0} posts',
                      style: GoogleFonts.poppins(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
