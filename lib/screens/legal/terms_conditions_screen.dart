import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Acceptance of Terms',
              content:
                  'By downloading, installing, accessing, or using the ProfitKaro mobile application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, please do not use our App.',
            ),
            _buildSection(
              title: '2. Description of Service',
              content:
                  'ProfitKaro is a rewards-based mobile application that allows users to earn coins and rewards by:\n\n'
                  '• Completing tasks, quizzes, and captcha challenges\n'
                  '• Watching advertisements\n'
                  '• Participating in games, spin wheels, and other activities\n'
                  '• Referring friends and family\n'
                  '• Completing surveys and offers\n\n'
                  'Coins can be converted to cash and withdrawn to your registered payment method.',
            ),
            _buildSection(
              title: '3. User Accounts',
              content:
                  'To use our services, you must:\n\n'
                  '• Be at least 18 years old\n'
                  '• Provide accurate and complete registration information\n'
                  '• Maintain the security of your account credentials\n'
                  '• Be responsible for all activities under your account\n'
                  '• Notify us immediately of any unauthorized access\n\n'
                  'You are responsible for maintaining the confidentiality of your account and password.',
            ),
            _buildSection(
              title: '4. Earning and Redeeming Coins',
              content:
                  '• Coins are earned through completing eligible activities as specified in the App\n'
                  '• Coin values and earning rates are determined by us and may change at any time\n'
                  '• Coins have no cash value until redeemed\n'
                  '• Minimum withdrawal thresholds apply and are subject to change\n'
                  '• Withdrawal requests are processed within 3-7 business days\n'
                  '• We reserve the right to verify transactions and may require additional documentation\n'
                  '• Fraudulent activities, including using multiple accounts or automated systems, will result in account suspension and forfeiture of coins',
            ),
            _buildSection(
              title: '5. Prohibited Activities',
              content:
                  'You agree NOT to:\n\n'
                  '• Create multiple accounts to earn additional rewards\n'
                  '• Use automated scripts, bots, or any unauthorized means to interact with the App\n'
                  '• Attempt to hack, reverse engineer, or compromise the App\'s security\n'
                  '• Share your account with others or transfer your account\n'
                  '• Engage in any fraudulent, illegal, or harmful activities\n'
                  '• Violate any applicable laws or regulations\n'
                  '• Interfere with or disrupt the App\'s functionality\n'
                  '• Collect or harvest information about other users\n\n'
                  'Violation of these prohibitions may result in immediate account termination and legal action.',
            ),
            _buildSection(
              title: '6. Advertisements',
              content:
                  '• The App displays third-party advertisements (for example through Google Mobile Ads)\n'
                  '• You may be required to watch ads to earn coins or unlock features\n'
                  '• We are not responsible for the content of third-party advertisements\n'
                  '• Ad availability may vary based on your location and device\n'
                  '• We do not guarantee ad availability or rewards for watching ads',
            ),
            _buildSection(
              title: '7. Payment and Withdrawals',
              content:
                  '• Withdrawals are processed to registered payment methods (UPI, Bank Account, etc.)\n'
                  '• You must provide accurate payment information\n'
                  '• We reserve the right to verify your identity before processing withdrawals\n'
                  '• Processing fees may apply to withdrawals\n'
                  '• We are not responsible for delays caused by payment processors or banks\n'
                  '• Refunds are not available for completed withdrawals',
            ),
            _buildSection(
              title: '8. Intellectual Property',
              content:
                  '• All content, features, and functionality of the App are owned by ProfitKaro\n'
                  '• You may not copy, modify, distribute, or create derivative works\n'
                  '• The App name, logo, and branding are trademarks of ProfitKaro\n'
                  '• User-generated content remains your property, but you grant us a license to use it within the App',
            ),
            _buildSection(
              title: '9. Service Modifications',
              content:
                  'We reserve the right to:\n\n'
                  '• Modify, suspend, or discontinue any part of the service at any time\n'
                  '• Change coin values, earning rates, or withdrawal thresholds\n'
                  '• Update features, add new features, or remove existing features\n'
                  '• Implement maintenance that may temporarily affect service availability\n\n'
                  'We will provide reasonable notice of significant changes when possible.',
            ),
            _buildSection(
              title: '10. Limitation of Liability',
              content:
                  '• The App is provided "as is" without warranties of any kind\n'
                  '• We do not guarantee uninterrupted or error-free service\n'
                  '• We are not liable for any indirect, incidental, or consequential damages\n'
                  '• Our total liability shall not exceed the amount you have earned in the App\n'
                  '• We are not responsible for losses due to technical issues, server downtime, or third-party services',
            ),
            _buildSection(
              title: '11. Account Termination',
              content:
                  'We may suspend or terminate your account if:\n\n'
                  '• You violate these Terms and Conditions\n'
                  '• You engage in fraudulent or illegal activities\n'
                  '• You provide false or misleading information\n'
                  '• Your account remains inactive for an extended period\n\n'
                  'Upon termination, you will lose access to your account and any unwithdrawn coins may be forfeited.',
            ),
            _buildSection(
              title: '12. Dispute Resolution',
              content:
                  '• Any disputes arising from these Terms will be resolved through good faith negotiation\n'
                  '• If negotiation fails, disputes will be subject to the exclusive jurisdiction of the courts in India\n'
                  '• You agree to resolve disputes individually and waive any right to participate in class actions',
            ),
            _buildSection(
              title: '13. Changes to Terms',
              content:
                  'We may modify these Terms at any time. Material changes will be notified through the App or via email. Continued use of the App after changes constitutes acceptance of the modified Terms. If you do not agree to the changes, you must stop using the App and may request account deletion.',
            ),
            _buildSection(
              title: '14. Contact Information',
              content:
                  'For questions, concerns, or support regarding these Terms and Conditions:\n\n'
                  '• In-app Support: Go to Profile > Help & Support\n'
                  '• Email: support@profitkaro.com\n\n'
                  'We will respond to your inquiries within a reasonable timeframe.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
