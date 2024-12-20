import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/posts_provider.dart';
import '../providers/theme_provider.dart';
import '../models/post_model.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isMeme = false;
  bool _isPosting = false;
  PostCategory _selectedCategory = PostCategory.casual;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to your post')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await ref.read(postsProvider.notifier).addPost(
            _contentController.text,
            imageFile: _selectedImage,
            isMeme: _isMeme,
            category: _selectedCategory,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        title: Text('Create Post', style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onBackground,
        )),
        actions: [
          if (_isPosting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.onBackground),
              onPressed: _createPost,
            ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Selection
              Card(
                color: theme.colorScheme.surfaceVariant,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Category',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PostCategory.values.map((category) {
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  size: 18,
                                  color: _selectedCategory == category
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.displayName,
                                  style: TextStyle(
                                    color: _selectedCategory == category
                                        ? theme.colorScheme.onSecondaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            selected: _selectedCategory == category,
                            selectedColor: theme.colorScheme.secondaryContainer,
                            backgroundColor: theme.colorScheme.surface,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = category);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Content TextField
              Card(
                color: theme.colorScheme.surfaceVariant,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _contentController,
                    maxLines: 5,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    decoration: InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: InputBorder.none,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Image Selection
              if (_selectedImage != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Add Image Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Image'),
                onPressed: _showImageSourceDialog,
              ),
              
              const SizedBox(height: 16),
              
              // Is Meme Switch
              if (_selectedCategory == PostCategory.meme)
                SwitchListTile(
                  title: Text('Mark as Meme', style: TextStyle(
                    color: theme.colorScheme.onBackground,
                  )),
                  value: _isMeme,
                  onChanged: (value) => setState(() => _isMeme = value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
