import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
              title: '1. Introduction',
              content:
                  'Welcome to ProfitKaro. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            _buildSection(
              title: '2. Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n'
                  '• Account Information: Name, mobile number, email address, and profile information\n'
                  '• Financial Information: Wallet balance, transaction history, payment methods, and withdrawal details\n'
                  '• Activity Data: Coins earned, tasks completed, quiz scores, captcha solves, and other engagement metrics\n'
                  '• Device Information: Device type, operating system, unique device identifiers, and mobile network information\n'
                  '• Usage Data: App features accessed, time spent on app, and interaction patterns',
            ),
            _buildSection(
              title: '3. How We Use Your Information',
              content:
                  'We use the collected information for the following purposes:\n\n'
                  '• To provide and maintain our services, including wallet management and reward distribution\n'
                  '• To process transactions, withdrawals, and payments\n'
                  '• To personalize your experience and show relevant offers and tasks\n'
                  '• To send notifications about earnings, bonuses, and app updates\n'
                  '• To improve our services, analyze usage patterns, and enhance user experience\n'
                  '• To detect, prevent, and address technical issues and fraudulent activities\n'
                  '• To comply with legal obligations and enforce our terms of service',
            ),
            _buildSection(
              title: '4. Information Sharing and Disclosure',
              content:
                  'We do not sell your personal information. We may share your information only in the following circumstances:\n\n'
                  '• With service providers who assist us in operating our app (payment processors, analytics providers, cloud hosting services)\n'
                  '• When required by law or to respond to legal processes\n'
                  '• To protect our rights, privacy, safety, or property\n'
                  '• In connection with a business transfer, merger, or acquisition\n'
                  '• With your explicit consent',
            ),
            _buildSection(
              title: '5. Data Security',
              content:
                  'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              title: '6. Third-Party Services',
              content:
                  'Our app may contain links to third-party services, including:\n\n'
                  '• Advertising networks (Google AdMob) for displaying ads\n'
                  '• Payment gateways for processing withdrawals\n'
                  '• Analytics services for understanding app usage\n\n'
                  'These third parties have their own privacy policies, and we encourage you to review them. We are not responsible for the privacy practices of third-party services.',
            ),
            _buildSection(
              title: '7. Your Rights and Choices',
              content:
                  'You have the following rights regarding your personal information:\n\n'
                  '• Access: Request access to your personal data\n'
                  '• Correction: Update or correct inaccurate information\n'
                  '• Deletion: Request deletion of your account and data\n'
                  '• Opt-out: Unsubscribe from marketing communications\n'
                  '• Data Portability: Request a copy of your data in a portable format\n\n'
                  'To exercise these rights, please contact us through the app\'s support section.',
            ),
            _buildSection(
              title: '8. Children\'s Privacy',
              content:
                  'Our services are not intended for users under the age of 18. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately, and we will take steps to delete such information.',
            ),
            _buildSection(
              title: '9. Data Retention',
              content:
                  'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. When you delete your account, we will delete or anonymize your personal information, except where we are required to retain it for legal purposes.',
            ),
            _buildSection(
              title: '10. Changes to This Privacy Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            _buildSection(
              title: '11. Contact Us',
              content:
                  'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us through:\n\n'
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
