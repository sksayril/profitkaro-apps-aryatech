import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../wallet/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _userName;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final name = await StorageService.getUserName();
    setState(() {
      _userName = name;
      _nameController.text = name ?? '';
    });
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getUserProfile(token: token);

      if (result['success'] && result['data'] != null) {
        setState(() {
          _profileData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editName() async {
    _nameController.text = _userName ?? '';
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground(context),
          title: const Text(
            'Edit Name',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: AppColors.background(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.green),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_nameController.text.trim()),
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.green),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final saved = await StorageService.saveUserName(result);
      if (saved) {
        setState(() {
          _userName = result;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name saved successfully'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile & Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchProfile();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Picture
              _buildProfilePicture(),
              const SizedBox(height: 16),
              
              // Name & Mobile Number
              GestureDetector(
                onTap: _editName,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _userName?.isNotEmpty == true ? _userName! : 'Tap to add name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profileData?['mobileNumber']?.toString() ?? 'Loading...',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              
              // KYC Verified Badge
              _buildKYCBadge(),
              const SizedBox(height: 24),
              
              // Stats Cards
              _isLoading ? _buildStatsCardsSkeleton() : _buildStatsCards(),
              const SizedBox(height: 24),
              
              // Profile Info Section
              _buildProfileInfoSection(),
              const SizedBox(height: 24),
              
              // Theme Toggle Section
              // _buildThemeToggleSection(),
              // const SizedBox(height: 24),
              
              // General Section
              _buildGeneralSection(),
              const SizedBox(height: 24),
              
              // Support Section
              _buildSupportSection(),
              const SizedBox(height: 32),
              
              // Log Out Button
              _buildLogOutButton(context),
              const SizedBox(height: 16),
              
              // Version
              Text(
                'Version 1.0.4 • Build 240',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 30),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8C4A8),
            border: Border.all(color: AppColors.cardBackground(context), width: 3),
          ),
          child: ClipOval(
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _editName,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKYCBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified, color: AppColors.green, size: 18),
          SizedBox(width: 6),
          Text(
            'KYC VERIFIED',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final walletBalance = _profileData?['walletBalance'];
    final coins = _profileData?['coins'] ?? 0;
    
    double balance = 0.0;
    if (walletBalance != null) {
      if (walletBalance is double) {
        balance = walletBalance;
      } else if (walletBalance is int) {
        balance = walletBalance.toDouble();
      } else if (walletBalance is String) {
        balance = double.tryParse(walletBalance) ?? 0.0;
      }
    }

    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    coins.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'COINS',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    formatter.format(balance),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'WALLET BALANCE',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    if (_isLoading || _profileData == null) {
      return const SizedBox.shrink();
    }

    final referCode = _profileData?['referCode']?.toString() ?? 'N/A';
    final referredBy = _profileData?['referredBy']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE INFORMATION',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoItem(
                  icon: Icons.qr_code,
                  label: 'Refer Code',
                  value: referCode,
                ),
                if (referredBy != null) ...[
                  _buildDivider(),
                  _buildInfoItem(
                    icon: Icons.person_add,
                    label: 'Referred By',
                    value: referredBy,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildThemeToggleSection() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'APPEARANCE',
  //           style: TextStyle(
  //             color: Colors.grey.shade500,
  //             fontSize: 12,
  //             fontWeight: FontWeight.w600,
  //             letterSpacing: 1,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Container(
  //           decoration: BoxDecoration(
  //             color: AppColors.cardBackground(context),
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           child: Consumer<ThemeProvider>(
  //             builder: (context, themeProvider, _) {
  //               return _buildSettingsItem(
  //                 icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
  //                 title: 'Theme',
  //                 trailing: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Text(
  //                       themeProvider.isDarkMode ? 'Dark' : 'Light',
  //                       style: TextStyle(
  //                         color: Colors.grey.shade400,
  //                         fontSize: 14,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 4),
  //                     Switch(
  //                       value: themeProvider.isDarkMode,
  //                       onChanged: (value) {
  //                         themeProvider.setThemeMode(
  //                           value ? ThemeMode.dark : ThemeMode.light,
  //                         );
  //                       },
  //                       activeColor: AppColors.primary,
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildGeneralSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GENERAL',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'English',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
                _buildDivider(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WalletScreen()),
                    );
                  },
                  child: _buildSettingsItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payment Methods',
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUPPORT',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildSettingsItem(
              icon: Icons.headset_mic_outlined,
              title: 'Help & Support',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: Colors.grey.shade800,
        height: 1,
      ),
    );
  }

  Widget _buildLogOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _handleLogout(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000), // Dark red background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground(context),
          title: const Text(
            'Log Out',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Log Out',
                style: TextStyle(color: Color(0xFF8B0000)),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Clear token and all stored data
      await StorageService.clearAll();

      // Navigate to login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
