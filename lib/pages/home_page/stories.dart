import 'package:clusty_stf/utils/app_constants.dart';
import 'package:flutter/material.dart';

class Stories extends StatelessWidget {
  final List<Map<String, String>> _stories = [
    {'imageUrl': AppConstants.defaultImageUrl, 'username': 'User 1'},
    {'imageUrl': AppConstants.defaultImageUrl, 'username': 'User 2'},
    {'imageUrl': AppConstants.defaultImageUrl, 'username': 'User 3'},
    {'imageUrl': AppConstants.defaultImageUrl, 'username': 'User 4'},
    {'imageUrl': AppConstants.defaultImageUrl, 'username': 'User 5'},
    {'imageUrl': AppConstants.defaultImageUrl, 'username': 'User 6'},
    {'imageUrl': AppConstants.defaultImageUrl, 'username': 'User 7'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 100.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _stories.length,
          itemBuilder: (context, index) {
            final story = _stories[index];
            return Container(
              width: 70.0,
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30.0,
                    backgroundImage: NetworkImage(story['imageUrl'] ?? ''),
                    backgroundColor: Colors.grey[200],
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    story['username'] ?? '',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
