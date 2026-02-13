import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class RecentTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> withdrawalRequests;
  final bool isLoading;

  const RecentTransactions({
    super.key,
    required this.withdrawalRequests,
    this.isLoading = false,
  });

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today, ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE, h:mm a').format(date);
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return AppColors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (withdrawalRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No withdrawal requests yet',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...withdrawalRequests.take(5).map((request) {
            final amount = request['amount'] ?? 0;
            final status = request['status'] ?? 'Pending';
            final createdAt = request['createdAt'] ?? '';
            final paymentMethod = request['paymentMethod'] ?? '';

            return TransactionItem(
              title: 'Withdrawal - $paymentMethod',
              time: _formatDate(createdAt),
              amount: '- ₹$amount',
              isCredit: false,
              status: status,
              statusColor: _getStatusColor(status),
            );
          }).toList(),
      ],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String title;
  final String time;
  final String amount;
  final bool isCredit;
  final String? status;
  final Color? statusColor;

  const TransactionItem({
    super.key,
    required this.title,
    required this.time,
    required this.amount,
    required this.isCredit,
    this.status,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.secondary : Colors.red).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.check_circle : Icons.remove_circle,
              color: isCredit ? AppColors.secondary : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (statusColor ?? Colors.grey).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status!,
                          style: TextStyle(
                            color: statusColor ?? Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isCredit ? AppColors.secondary : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
