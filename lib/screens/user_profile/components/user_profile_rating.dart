import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';

class UserProfileRating extends StatelessWidget {
  final UserModel user;
  final ThemeData theme;
  final VoidCallback? onRatePressed;

  const UserProfileRating({
    super.key,
    required this.user,
    required this.theme,
    this.onRatePressed,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Rating',
            style: GoogleFonts.poppins(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(user.rating),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < user.rating.floor()
                                ? Icons.star
                                : index < user.rating
                                    ? Icons.star_half
                                    : Icons.star_outline,
                            color: _getRatingColor(user.rating),
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                  Text(
                    '${user.ratingCount} ratings',
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (onRatePressed != null)
                TextButton.icon(
                  onPressed: onRatePressed,
                  icon: Icon(
                    Icons.star_outline,
                    color: theme.primaryColor,
                  ),
                  label: Text(
                    'Rate',
                    style: GoogleFonts.poppins(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
