import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/post_model.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String? _selectedMood;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File? croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          setState(() {
            _image = croppedFile;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,

    );
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<void> _uploadPost() async {
    if (_captionController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedMood == null ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String imageUrl = await _uploadImage(user.uid);
      String postId = FirebaseFirestore.instance.collection('posts').doc().id;
      List<String> tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();

      Post post = Post(
        id: postId,
        userId: user.uid,
        caption: _captionController.text,
        imageUrl: imageUrl,
        description: _descriptionController.text,
        mood: _selectedMood!,
        tags: tags,
        createdAt: Timestamp.now(), username: '', userImageUrl: '',
      );

      // Save post to global posts collection
      await FirebaseFirestore.instance.collection('posts').doc(postId).set(post.toMap());

      // Save post to user's sub-collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_posts')
          .doc(postId)
          .set(post.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post uploaded successfully')),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadImage(String userId) async {
    String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    Reference storageRef = FirebaseStorage.instance.ref().child('post_images/$fileName');
    UploadTask uploadTask = storageRef.putFile(_image!);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  void _clearForm() {
    _captionController.clear();
    _descriptionController.clear();
    _tagsController.clear();
    setState(() {
      _selectedMood = null;
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Tags (comma-separated)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              items: ['Advice', 'Meme', 'Others'].map((String mood) {
                return DropdownMenuItem<String>(
                  value: mood,
                  child: Text(mood),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMood = newValue;
                });
              },
              decoration: const InputDecoration(labelText: 'Mood'),
            ),
            const SizedBox(height: 10),
            _image == null
                ? TextButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            )
                : Image.file(_image!, height: 150),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadPost,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
