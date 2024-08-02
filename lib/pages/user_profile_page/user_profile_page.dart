import 'package:clusty/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/follow_provder.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final followProvider = Provider.of<FollowProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: followProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: followProvider.user!.imageUrl.isNotEmpty
                    ? NetworkImage(followProvider.user!.imageUrl)
                    : NetworkImage(AppConstants.defaultImageUrl),
                backgroundColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                '${followProvider.user!.firstName} ${followProvider.user!.lastName}',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge!.color),
              ),
              const SizedBox(height: 10),
              Text(
                '@${followProvider.user!.username}',
                style: TextStyle(
                    fontSize: 18,
                    color: theme.textTheme.bodyMedium!.color),
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('followers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text('Loading...');
                  }
                  return Text(
                    'Followers: ${snapshot.data!.docs.length}',
                    style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium!.color),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await followProvider.toggleFollow(userId);
                },
                child:
                Text(followProvider.isFollowing ? 'Unfollow' : 'Follow',
                style: TextStyle(
                  color: Colors.white
                ),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: followProvider.isFollowing
                      ? Colors.blue
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
