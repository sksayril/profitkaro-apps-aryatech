import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PaymentMethodSection extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// When false, the Bank Transfer card is hidden and the third UPI option
  /// (Google Pay) takes the second slot of the second row alone. Useful when
  /// the parent screen has a separate top-level "Bank Withdraw" mode.
  final bool showBankCard;

  const PaymentMethodSection({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.showBankCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.lock,
              color: Colors.amber.shade600,
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PaymentMethodCard(
          index: 0,
          icon: Icons.qr_code_2,
          label: 'UPI / VPA',
          iconColor: AppColors.purple,
          isSelected: selectedIndex == 0,
          onTap: () => onChanged(0),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.index,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
