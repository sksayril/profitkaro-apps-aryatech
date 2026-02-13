import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CurrencyToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const CurrencyToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(context, 0, 'Rupees (₹)', '₹'),
          _buildTab(context, 1, 'Coins', '\$', isCoins: true),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label, String symbol, {bool isCoins = false}) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardBackgroundLight(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            if (isCoins)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(symbol, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
