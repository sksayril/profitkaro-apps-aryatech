import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Allowed gift voucher brands. The string values match the API contract
/// exactly (the backend rejects anything else).
class GiftVoucherBrand {
  final String apiValue;
  final String label;
  final IconData icon;
  final Color color;

  const GiftVoucherBrand({
    required this.apiValue,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<GiftVoucherBrand> kGiftVoucherBrands = [
  GiftVoucherBrand(
    apiValue: 'Amazon',
    label: 'Amazon',
    icon: Icons.shopping_bag,
    color: Color(0xFFFF9900),
  ),
  GiftVoucherBrand(
    apiValue: 'Flipkart',
    label: 'Flipkart',
    icon: Icons.shopping_cart,
    color: Color(0xFF2874F0),
  ),
  GiftVoucherBrand(
    apiValue: 'GooglePlay',
    label: 'Google Play',
    icon: Icons.play_arrow_rounded,
    color: Color(0xFF34A853),
  ),
];

/// Server-allowed gift voucher denominations.
const List<int> kGiftVoucherDenominations = [10, 20, 30, 50];

class GiftVoucherForm extends StatelessWidget {
  final String? selectedBrand;
  final int? selectedAmount;
  final ValueChanged<String> onBrandSelected;
  final ValueChanged<int> onAmountSelected;
  final double walletBalance;

  const GiftVoucherForm({
    super.key,
    required this.selectedBrand,
    required this.selectedAmount,
    required this.onBrandSelected,
    required this.onAmountSelected,
    required this.walletBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Choose a Brand',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.card_giftcard, color: Colors.amber.shade600, size: 18),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kGiftVoucherBrands.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, index) {
            final brand = kGiftVoucherBrands[index];
            final isSelected = selectedBrand == brand.apiValue;
            return _BrandCard(
              brand: brand,
              isSelected: isSelected,
              onTap: () => onBrandSelected(brand.apiValue),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Choose Amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kGiftVoucherDenominations.map((amount) {
            final isSelected = selectedAmount == amount;
            final disabled = amount > walletBalance;
            return _AmountChip(
              amount: amount,
              isSelected: isSelected,
              disabled: disabled,
              onTap: disabled ? null : () => onAmountSelected(amount),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline,
                size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Voucher code will be delivered after admin approval.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandCard extends StatelessWidget {
  final GiftVoucherBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandCard({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? brand.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brand.color.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: brand.color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(brand.icon, color: brand.color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                brand.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: brand.color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final int amount;
  final bool isSelected;
  final bool disabled;
  final VoidCallback? onTap;

  const _AmountChip({
    required this.amount,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.buttonGradient : null,
          color: isSelected ? null : AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (disabled ? Colors.grey.shade800 : Colors.grey.shade700),
            width: 1.2,
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.45 : 1.0,
          child: Text(
            '₹$amount',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
