import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar with border
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight(context), width: 2),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF87CEEB).withOpacity(0.3),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Welcome Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              const Row(
                children: [
                  Text(
                    'Namaste, User!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '👋',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Bell Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border(context), width: 1),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }
}
