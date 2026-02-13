import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class UPIInput extends StatefulWidget {
  final int selectedPaymentMethod;
  final TextEditingController? upiIdController;
  final TextEditingController? virtualIdController;
  final TextEditingController? bankAccountController;
  final TextEditingController? bankIFSCController;
  final TextEditingController? bankNameController;
  final TextEditingController? accountHolderController;

  const UPIInput({
    super.key,
    required this.selectedPaymentMethod,
    this.upiIdController,
    this.virtualIdController,
    this.bankAccountController,
    this.bankIFSCController,
    this.bankNameController,
    this.accountHolderController,
  });

  @override
  State<UPIInput> createState() => _UPIInputState();
}

class _UPIInputState extends State<UPIInput> {
  @override
  Widget build(BuildContext context) {
    // UPI / Paytm / Google Pay
    if (widget.selectedPaymentMethod == 0 || widget.selectedPaymentMethod == 1 || widget.selectedPaymentMethod == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter UPI ID',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.upiIdController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'example@upi',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: AppColors.cardBackground(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Or Enter Virtual ID (Optional)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.virtualIdController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'VIRTUAL123',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: AppColors.cardBackground(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      );
    }
    
    // Bank Transfer
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Account Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.accountHolderController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Account Holder Name',
            labelStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: AppColors.cardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.bankAccountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Account Number',
            labelStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: AppColors.cardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.bankIFSCController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'IFSC Code',
            labelStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: AppColors.cardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.bankNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Bank Name',
            labelStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: AppColors.cardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
