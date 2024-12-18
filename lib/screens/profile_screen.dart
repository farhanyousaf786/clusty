import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/posts_provider.dart';
import '../utils/logger.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileScreen({this.userId, super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _showPosts = true;
  late TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _togglePosts() {
    setState(() {
      _showPosts = !_showPosts;
    });
  }

  void _startEditing(user) {
    setState(() {
      _isEditing = true;
      _nameController.text = user.username ?? '';
      _aboutController.text = user.about ?? '';
    });
  }

  Future<void> _saveProfile(user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).updateProfile(
        username: _nameController.text.trim(),
        photoUrl: user.photoUrl,
      );
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // TODO: Upload image to Firebase Storage and update user photoUrl
      Logger.i('Image picked: ${image.path}');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final initialDate = DateTime.now().subtract(const Duration(days: 365 * 18)); // 18 years ago
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now().subtract(const Duration(days: 365 * 13)); // Must be at least 13

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select your date of birth',
      confirmText: 'Set Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      await _updateField('dob', picked.millisecondsSinceEpoch.toString());
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMMM d, y').format(date); // Example: December 18, 2024
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final userStream = widget.userId != null
        ? ref.watch(userProvider(widget.userId!))
        : ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    // Hide edit button for other users' profiles
    final isCurrentUser = widget.userId == null || widget.userId == ref.read(authProvider).value?.id;

    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.userId ?? ref.read(authProvider).value?.id ?? '')
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        userData['id'] = widget.userId ?? ref.read(authProvider).value?.id;
        final user = UserModel.fromJson(userData);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: theme.primaryColor,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    itemBuilder: (context) => [
                      _buildPopupMenuItem(
                        'Edit Profile Picture',
                        Icons.image_rounded,
                        'photo',
                      ),
                      _buildPopupMenuItem(
                        'Edit Username',
                        Icons.person_rounded,
                        'username',
                      ),
                      _buildPopupMenuItem(
                        'Edit Name',
                        Icons.badge_rounded,
                        'name',
                      ),
                      _buildPopupMenuItem(
                        'Edit About',
                        Icons.info_rounded,
                        'about',
                      ),
                      _buildPopupMenuItem(
                        'Edit Date of Birth',
                        Icons.cake_rounded,
                        'dob',
                      ),
                    ],
                    onSelected: _showEditDialog,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      ref.read(themeProvider.notifier).isDark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.scaffoldBackgroundColor,
                              Colors.transparent
                            ],
                          ).createShader(
                            Rect.fromLTRB(0, 0, rect.width, rect.height),
                          );
                        },
                        blendMode: BlendMode.dstIn,
                        child: user.photoUrl != null
                            ? Image.network(
                                user.photoUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.primaryColor,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      // Profile Picture
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Hero(
                          tag: 'profile_${user.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor,
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: theme.primaryColor,
                              backgroundImage: user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? Text(
                                      user.username?.isNotEmpty == true
                                          ? user.username![0].toUpperCase()
                                          : user.username?[0].toUpperCase() ?? 'U',
                                      style: GoogleFonts.poppins(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      // Username and Profile Info
                      Positioned(
                        bottom: 35,
                        left: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${user.username}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              user.name ?? user.username ?? 'User',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (user.dob != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Born ${_formatDate(user.dob!)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Joined ${_formatDate(user.createdAt)}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (!_isEditing) ...[
                    _buildStats(user, theme),
                    const SizedBox(height: 30),
                    _buildRatingSection(user, theme),
                    const SizedBox(height: 30),
                    _buildAboutSection(user, theme),
                    const SizedBox(height: 30),
                    _buildDetailsSection(user, theme),
                    const SizedBox(height: 30),
                    // Posts Section Header with Toggle
                    InkWell(
                      onTap: _togglePosts,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(
                              'My Posts',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showPosts ? Icons.expand_less : Icons.expand_more,
                              color: theme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Posts Section Content
                    if (_showPosts)
                      Consumer(
                        builder: (context, ref, child) {
                          final userPosts = ref.watch(postsProvider).when(
                            data: (posts) => posts.where((post) => post.userId == user.id).toList()
                              ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
                            loading: () => [],
                            error: (_, __) => [],
                          );
                          
                          if (userPosts.isEmpty) {
                            return Center(
                              child: Text(
                                'No posts yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: userPosts.length,
                            itemBuilder: (context, index) {
                              final post = userPosts[index];
                              return _buildPostCard(post, theme);
                            },
                          );
                        },
                      ),
                  ] else
                    _buildEditForm(user, theme),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditForm(user, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textTheme.bodyLarge?.color,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(),
                ),
              ),
              FilledButton(
                onPressed: () => _saveProfile(user),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatsCard(
            'Posts',
            user.postsCount.toString(),
            theme,
          ),
          _buildStatsCard(
            'Followers',
            user.followersCount.toString(),
            theme,
          ),
          _buildStatsCard(
            'Following',
            user.followingCount.toString(),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(UserModel user, ThemeData theme) {
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
                      Text(
                        'out of 5',
                        style: GoogleFonts.poppins(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${user.ratingCount} ${user.ratingCount == 1 ? 'rating' : 'ratings'}',
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: user.rating / 5,
                          backgroundColor: theme.dividerColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getRatingColor(user.rating),
                          ),
                          strokeWidth: 8,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: _getRatingColor(user.rating),
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade400;
    if (rating >= 4.0) return Colors.lightGreen.shade400;
    if (rating >= 3.0) return Colors.orange.shade400;
    if (rating >= 2.0) return Colors.deepOrange.shade400;
    return Colors.red.shade400;
  }

  Widget _buildAboutSection(user, ThemeData theme) {
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
            'About',
            style: GoogleFonts.poppins(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.about?.isEmpty ?? true ? 'No description added yet' : user.about!,
            style: GoogleFonts.poppins(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(user, ThemeData theme) {
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
            'Details',
            style: GoogleFonts.poppins(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildDetailRow(
            Icons.email,
            'Email',
            user.email,
            theme,
          ),
          _buildDetailRow(
            Icons.cake,
            'Date of Birth',
            user.dob != null ? _formatDate(user.dob!) : 'Not set yet',
            theme,
          ),
          _buildDetailRow(
            Icons.calendar_today,
            'Joined',
            _formatDate(user.createdAt),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, y').format(
                    DateTime.fromMillisecondsSinceEpoch(post.timestamp),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String text, IconData icon, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String field) {
    final theme = Theme.of(context);
    final user = ref.read(authProvider);
    
    final controller = TextEditingController(
      text: field == 'username' 
          ? user.when(
              data: (user) => user?.username,
              loading: () => null,
              error: (_, __) => null,
            )
          : field == 'name'
              ? user.when(
                  data: (user) => user?.name,
                  loading: () => null,
                  error: (_, __) => null,
                )
              : field == 'about'
                  ? user.when(
                      data: (user) => user?.about ?? '',
                      loading: () => null,
                      error: (_, __) => null,
                    )
                  : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Edit ${field.substring(0, 1).toUpperCase()}${field.substring(1)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (field == 'photo') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOptionButton(
                    'Camera',
                    Icons.camera_alt_rounded,
                    () async {
                      final image = await ImagePicker().pickImage(source: ImageSource.camera);
                      if (image != null) {
                        await _uploadImage(image.path);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildImageOptionButton(
                    'Gallery',
                    Icons.photo_library_rounded,
                    () async {
                      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        await _uploadImage(image.path);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ] else if (field == 'dob')
              TextButton(
                onPressed: () {
                  _pickDate(context);
                  Navigator.pop(context);
                },
                child: Text(
                  user.when(
                    data: (user) => user?.dob != null 
                        ? 'Current: ${_formatDate(user?.dob ?? 0)}\nTap to change'
                        : 'Select Date',
                    loading: () => 'Select Date',
                    error: (_, __) => 'Select Date',
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.primaryColor,
                  ),
                ),
              )
            else
              TextField(
                controller: controller,
                maxLines: field == 'about' ? 4 : 1,
                decoration: InputDecoration(
                  hintText: 'Enter your ${field}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (field != 'photo' && field != 'dob' && controller.text.isNotEmpty) {
                _updateField(field, controller.text);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOptionButton(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(String imagePath) async {
    try {
      final userData = ref.read(authProvider);
      final userId = userData.when(
        data: (user) => user?.id,
        loading: () => null,
        error: (_, __) => null,
      );
      
      if (userId == null) return;

      final storage = FirebaseStorage.instance;
      final storageRef = storage.ref().child('user_photos/$userId.jpg');
      await storageRef.putFile(File(imagePath));
      final url = await storageRef.getDownloadURL();
      
      await _updateField('photoUrl', url);
    } catch (e) {
      Logger.e('Error uploading image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _updateField(String field, String value) async {
    try {
      final userData = ref.read(authProvider);
      final userId = userData.when(
        data: (user) => user?.id,
        loading: () => null,
        error: (_, __) => null,
      );
      
      if (userId == null) return;

      final database = FirebaseDatabase.instance;
      await database.ref().child('users').child(userId).update({
        field: value,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully updated $field')),
        );
      }
    } catch (e) {
      Logger.e('Error updating $field', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating $field: $e')),
        );
      }
    }
  }
}
