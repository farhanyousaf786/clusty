import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PromotionSlides extends StatefulWidget {
  @override
  _PromotionSlidesState createState() => _PromotionSlidesState();
}

class _PromotionSlidesState extends State<PromotionSlides> {
  List<String> _imageUrls = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchPromotionSlides();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchPromotionSlides() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('promotion-slides')
          .doc('WrrGdpfWs7NgDr6pSZef')
          .get();

      final data = snapshot.data() as Map<String, dynamic>?; // Properly cast the data
      if (data != null) {
        setState(() {
          _imageUrls = data.values.map((value) => value.toString()).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching promotion slides: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentPage < _imageUrls.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return _imageUrls.isEmpty
        ? Center(child: Text('No promotion slides available'))
        : SizedBox(
      height: 200.0, // Height of the carousel
      child: PageView.builder(
        controller: _pageController,
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              image: DecorationImage(
                image: NetworkImage(_imageUrls[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
