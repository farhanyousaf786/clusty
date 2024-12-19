import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/posts_provider.dart';
import '../../utils/logger.dart';
import '../../utils/time_ago_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/post_card.dart';
import 'edit_profile_screen.dart';

class MainProfile extends ConsumerStatefulWidget {
  final String? userId;
  const MainProfile({this.userId, super.key});

  @override
  ConsumerState<MainProfile> createState() => _MainProfileState();
}

class _MainProfileState extends ConsumerState<MainProfile> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _showPosts = true;
  late TextEditingController _aboutController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutBack,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _animationController.dispose();
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

  Future<void> _pickAndUpdateImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        setState(() => _isLoading = true);
        
        // Get current user ID from Firebase Auth
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }
        
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child(currentUser.uid)
            .child('profile.jpg');

        // Upload file with metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        );
        
        await storageRef.putFile(File(image.path), metadata);
        final photoUrl = await storageRef.getDownloadURL();

        // Update user profile in database
        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .update({
              'photoUrl': photoUrl,
              'updatedAt': ServerValue.timestamp,
            });

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      Logger.e('Error updating profile picture', e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.yellow;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  void _showImagePickerOptions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: theme.primaryColor,
                ),
              ),
              title: Text(
                'Take Photo',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpdateImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library,
                  color: theme.primaryColor,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpdateImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final userStream = widget.userId != null
        ? ref.watch(userProvider(widget.userId!))
        : ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

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
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Animated Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor.withOpacity(0.8),
                      theme.colorScheme.secondary.withOpacity(0.6),
                      theme.primaryColor.withOpacity(0.4),
                    ],
                    stops: const [0.2, 0.5, 0.8],
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstOut,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ),

              // Main Content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 300,
                    floating: false,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Profile Image Background
                          if (user.photoUrl != null)
                            ShaderMask(
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    theme.scaffoldBackgroundColor,
                                  ],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstOut,
                              child: Image.network(
                                user.photoUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Profile Info
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                // Profile Picture with Edit Button
                                Stack(
                                  children: [
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
                                    if (widget.userId == null || widget.userId == ref.read(authProvider).value?.id)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap: () => _showImagePickerOptions(context, theme),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.camera,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Name and Username
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
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      if (widget.userId == null || widget.userId == ref.read(authProvider).value?.id)
                        Container(  margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                          child: IconButton(
                           icon: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                            ),                          onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(user: user),
                                ),
                              );
                            },
                          ),
                        ),
                
                      // Theme Toggle Button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          icon: Icon(
                            ref.read(themeProvider.notifier).isDark
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              ref.read(themeProvider.notifier).toggleTheme(),
                        ),
                      ),

                      // Logout Button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => ref.read(authProvider.notifier).signOut(),
                        ),
                      ),
                    ],
                  ),

                  // Profile Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Stats Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Rating',
                                      user.rating.toStringAsFixed(1),
                                      Icons.star,
                                      _getRatingColor(user.rating),
                                      theme,
                                    ),
                                    _buildStatItem(
                                      'Following',
                                      '${user.followingCount ?? 0}',
                                      Icons.people,
                                      theme.primaryColor,
                                      theme,
                                    ),
                                    _buildStatItem(
                                      'Followers',
                                      '${user.followersCount ?? 0}',
                                      Icons.favorite,
                                      Colors.red,
                                      theme,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // About Section with all user info
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: theme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'About',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.userId == null || widget.userId == ref.read(authProvider).value?.id)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 20,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditProfileScreen(user: user),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // About Text
                                _buildInfoRow(
                                  Icons.description_outlined,
                                  'About',
                                  user.about ?? 'No description added yet.',
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                // Name
                                _buildInfoRow(
                                  Icons.person,
                                  'Name',
                                  user.name ?? 'Not set',
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                // Username
                                _buildInfoRow(
                                  Icons.alternate_email,
                                  'Username',
                                  '@${user.username ?? 'anonymous'}',
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                // Date of Birth
                                if (user.dob != null)
                                  _buildInfoRow(
                                    Icons.cake_outlined,
                                    'Birthday',
                                    DateFormat('MMMM d, y').format(
                                      DateTime.fromMillisecondsSinceEpoch(user.dob!),
                                    ),
                                    theme,
                                  ),
                                if (user.dob != null)
                                  const SizedBox(height: 12),
                                // Total Posts
                                _buildInfoRow(
                                  Icons.post_add_outlined,
                                  'Total Posts',
                                  '${user.postsCount} posts',
                                  theme,
                                ),
                                const SizedBox(height: 12),
                                // Joined Date
                                _buildInfoRow(
                                  Icons.calendar_today_outlined,
                                  'Joined',
                                  TimeAgoUtils.getTimeAgo(user.createdAt),
                                  theme,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Posts Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.grid_view_rounded,
                                          color: theme.primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Posts',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textTheme.titleLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _showPosts
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: theme.primaryColor,
                                      ),
                                      onPressed: _togglePosts,
                                    ),
                                  ],
                                ),
                                if (_showPosts) ...[
                                  const SizedBox(height: 16),
                                  _buildPostsList(user.id!, theme),
                                ],
                              ],
                            ),
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
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildPostsList(String userId, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final userPosts = ref.watch(userPostsProvider(userId));
        
        return userPosts.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.post_add_rounded,
                      size: 48,
                      color: theme.primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No posts yet',
                      style: GoogleFonts.poppins(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(post: posts[index]),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
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
