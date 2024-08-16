import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clusty_stf/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

class FollowProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isFollowing = false;
  bool _isLoading = false;
  UserModel? _user;
  List<String> _followingUserIds = [];
  List<Post> _posts = [];

  bool get isFollowing => _isFollowing;
  bool get isLoading => _isLoading;
  UserModel? get user => _user;
  List<String> get followingUserIds => _followingUserIds;
  List<Post> get posts => _posts;

  Future<void> fetchUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    _user = UserModel.fromDocumentSnapshot(userDoc);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkIfFollowing(String userId) async {
    _isLoading = true;
    notifyListeners();

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(userId)
        .get();

    _isFollowing = doc.exists;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> followUser(String userIdToFollow) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    WriteBatch batch = _firestore.batch();

    DocumentReference currentUserDoc =
    _firestore.collection('users').doc(currentUser.uid);
    DocumentReference userToFollowDoc =
    _firestore.collection('users').doc(userIdToFollow);

    batch.set(
      currentUserDoc.collection('following').doc(userIdToFollow),
      {'userId': userIdToFollow, 'timestamp': FieldValue.serverTimestamp()},
    );
    batch.set(
      userToFollowDoc.collection('followers').doc(currentUser.uid),
      {'userId': currentUser.uid, 'timestamp': FieldValue.serverTimestamp()},
    );

    await batch.commit();
    _isFollowing = true;
    notifyListeners();
  }

  Future<void> unfollowUser(String userIdToUnfollow) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    WriteBatch batch = _firestore.batch();

    DocumentReference currentUserDoc =
    _firestore.collection('users').doc(currentUser.uid);
    DocumentReference userToUnfollowDoc =
    _firestore.collection('users').doc(userIdToUnfollow);

    batch.delete(currentUserDoc.collection('following').doc(userIdToUnfollow));
    batch.delete(userToUnfollowDoc.collection('followers').doc(currentUser.uid));

    await batch.commit();
    _isFollowing = false;
    notifyListeners();
  }

  Future<void> toggleFollow(String userId) async {
    if (_isFollowing) {
      await unfollowUser(userId);
    } else {
      await followUser(userId);
    }
    notifyListeners();
  }

  Future<void> fetchFollowingUserIds() async {
    _isLoading = true;
    notifyListeners();

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .get();

    _followingUserIds = snapshot.docs.map((doc) => doc['userId'].toString()).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFollowingPosts() async {
    _isLoading = true;
    notifyListeners();

    await fetchFollowingUserIds();

    List<Post> tempPosts = [];

    for (String userId in _followingUserIds) {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_posts')
          .orderBy('createdAt', descending: true)
          .limit(4)
          .get();

      for (var doc in snapshot.docs) {
        Post post = Post.fromDocument(doc);
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(post.userId).get();
        UserModel user = UserModel.fromDocumentSnapshot(userDoc);
        post.username = user.firstName + ' ' + user.lastName;
        post.userImageUrl = user.imageUrl;
        tempPosts.add(post);
      }
    }

    tempPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _posts = tempPosts;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> likePost(Post post) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool isLiked = post.likes.contains(currentUser.uid);
    if (isLiked) {
      post.likes.remove(currentUser.uid);
    } else {
      post.likes.add(currentUser.uid);
    }

    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef = _firestore.collection('posts').doc(post.id);
      DocumentReference userPostRef = _firestore
          .collection('users')
          .doc(post.userId)
          .collection('user_posts')
          .doc(post.id);

      transaction.update(postRef, {'likes': post.likes});
      transaction.update(userPostRef, {'likes': post.likes});
    });

    notifyListeners();
  }

  Future<void> addComment(Post post, String commentText) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || commentText.isEmpty) return;

    Map<String, dynamic> comment = {
      'userId': currentUser.uid,
      'username': _user?.firstName ?? 'Anonymous',
      'comment': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef = _firestore.collection('posts').doc(post.id);
      DocumentReference userPostRef = _firestore
          .collection('users')
          .doc(post.userId)
          .collection('user_posts')
          .doc(post.id);

      DocumentSnapshot postSnapshot = await transaction.get(postRef);
      List<dynamic> comments = postSnapshot.get('comments') ?? [];
      comments.add(comment);

      transaction.update(postRef, {'comments': comments});
      transaction.update(userPostRef, {'comments': comments});
    });

    notifyListeners();
  }
}
