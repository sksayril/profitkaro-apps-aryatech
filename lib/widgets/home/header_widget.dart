import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // 3D Avatar Area
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9EA1D4), // Light purple background
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                image: const DecorationImage(
                  // Using a network image as a placeholder for the 3D avatar, 
                  // or fallback to an icon if offline. 
                  // In a real app, this would be a local asset.
                  image: NetworkImage('https://cdn-icons-png.flaticon.com/512/4140/4140048.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const SizedBox(), // Placeholder for the image
            ),
            const SizedBox(width: 12),
            
            // Fast Payouts Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6), // Very light purple
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFD1C4E9),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Color(0xFFFFD600), // Yellow lightning
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Fast Payouts',
                    style: TextStyle(
                      color: Color(0xFF673AB7), // Deep purple text
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_double_arrow_right,
                    color: Color(0xFF673AB7), // Deep purple arrows
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Fire/Streak Icon Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0B2), // Light orange bg
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFCC80),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.local_fire_department,
              color: Color(0xFFEF6C00), // Orange fire
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
