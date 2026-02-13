import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  final VoidCallback? onBack;
  
  const HistoryScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'History Screen',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
