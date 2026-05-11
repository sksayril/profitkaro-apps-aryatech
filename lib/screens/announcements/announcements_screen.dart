import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AnnouncementsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const AnnouncementsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Announcements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5B4FCF).withOpacity(0.15),
              ),
              child: const ImageIcon(
                AssetImage('assets/images/bottom_nav_announcement.png'),
                color: Color(0xFF5B4FCF),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Announcements Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay tuned for updates and offers!',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
