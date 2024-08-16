import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clusty_stf/pages/home_page/promotion_slides.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/follow_provder.dart';
import '../../utils/app_constants.dart';
import '../post_page/post_page.dart';
import '../my_profile_page/my_profile_page.dart';
import '../notification_page/notification_page.dart';
import '../../providers/user_provider.dart';
import 'stories.dart';
import 'posts/user_posts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFollowingPosts();
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  Future<void> _fetchFollowingPosts() async {
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    await followProvider.fetchFollowingPosts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color;
    final userProvider = Provider.of<UserProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userProvider.user != null ? 'Hello, ${userProvider.user!.firstName}' : '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _greeting,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              background: PromotionSlides(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: iconColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
                  );
                },
              ),
            ],
            leading: IconButton(
              icon: CircleAvatar(
                backgroundImage: NetworkImage(
                  userProvider.user?.imageUrl?.isNotEmpty == true
                      ? userProvider.user!.imageUrl
                      : AppConstants.defaultImageUrl,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyProfilePage()),
                );
              },
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Stories(),
              SizedBox(height: 30),
              followProvider.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : UserPosts(posts: followProvider.posts),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostPage()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
