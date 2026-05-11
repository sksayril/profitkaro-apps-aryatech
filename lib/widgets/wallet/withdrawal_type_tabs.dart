import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Top-level segmented selector that lets the user pick how they want to
/// withdraw: Gift Voucher, UPI, or Bank Transfer. Each tab is rendered as
/// a stacked icon + label pill, and the selected tab gets the brand
/// gradient.
class WithdrawalTypeTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const WithdrawalTypeTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Withdrawal Type',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TypeChip(
                index: 0,
                icon: Icons.card_giftcard,
                label: 'Gift Voucher\nWithdraw',
                isSelected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeChip(
                index: 1,
                icon: Icons.payments_outlined,
                label: 'UPI\nWithdraw',
                isSelected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeChip(
                index: 2,
                icon: Icons.account_balance,
                label: 'Bank\nWithdraw',
                isSelected: selectedIndex == 2,
                onTap: () => onChanged(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.buttonGradient : null,
          color: isSelected ? null : AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.white : AppColors.primaryLight,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
