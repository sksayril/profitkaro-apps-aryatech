import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../wallet/wallet_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_conditions_screen.dart';

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
  String? _avatarUrl;

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
      // Generate avatar URL based on username
      if (name != null && name.isNotEmpty) {
        _avatarUrl = _generateAvatarUrl(name);
      }
    });
  }

  String _generateAvatarUrl(String name) {
    // Use UI Avatars API to generate a random human avatar based on name
    // This creates a unique avatar for each user based on their name
    final encodedName = Uri.encodeComponent(name);
    // Using avataaars style from DiceBear for human-like avatars
    // You can also use: 'https://ui-avatars.com/api/?name=$encodedName&background=random&color=fff&size=200'
    return 'https://api.dicebear.com/7.x/avataaars/png?seed=$encodedName&size=200&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
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
        final data = result['data'];
        
        // Update username from API response if available (check both cases)
        final apiUserName = data['userName']?.toString() ?? 
                           data['UserName']?.toString();
        
        if (apiUserName != null && apiUserName.isNotEmpty) {
          // Save to storage if different from current
          if (_userName != apiUserName) {
            await StorageService.saveUserName(apiUserName);
          }
          setState(() {
            _userName = apiUserName;
            _nameController.text = apiUserName;
            // Update avatar URL when username changes
            _avatarUrl = _generateAvatarUrl(apiUserName);
          });
        }
        
        setState(() {
          _profileData = data;
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
          // Regenerate avatar URL with new name
          _avatarUrl = _generateAvatarUrl(result);
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
          await _loadUserName();
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
              FutureBuilder<String?>(
                future: StorageService.getMobileNumber(),
                builder: (context, snapshot) {
                  final mobileFromStorage = snapshot.data;
                  // Check both lowercase and uppercase field names from API
                  final mobileFromApi = _profileData?['mobileNumber']?.toString() ?? 
                                       _profileData?['MobileNumber']?.toString();
                  final displayMobile = mobileFromApi ?? mobileFromStorage ?? 'Loading...';
                  
                  return Text(
                    displayMobile,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  );
                },
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
              
              // Become a Sponsor Section
              _buildBecomeSponsorSection(),
              const SizedBox(height: 24),
              
              // Support Section
              _buildSupportSection(),
              const SizedBox(height: 24),
              
              // Legal Section
              _buildLegalSection(),
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
            child: _avatarUrl != null && _userName != null && _userName!.isNotEmpty
                ? Image.network(
                    _avatarUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image fails to load
                      return Container(
                        color: const Color(0xFFE8C4A8),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFFE8C4A8),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFFE8C4A8),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey.shade600,
                    ),
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

  Widget _buildBecomeSponsorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          _showSponsorFormDialog();
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF8B7AE8),
                Color(0xFF9C88E9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Become a Sponsor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Promote your app with us',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSponsorFormDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    final appController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(context),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Become a Sponsor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in the details to promote your app',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Name Field
                        Text(
                          'Name',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          enabled: !isSubmitting,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: AppColors.cardBackgroundLight(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email Field
                        Text(
                          'Email',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: AppColors.cardBackgroundLight(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Mobile Number Field
                        Text(
                          'Mobile Number',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: mobileController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter mobile number',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: AppColors.cardBackgroundLight(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // App Promotion Field
                        Text(
                          'App Promotion Link',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: appController,
                          enabled: !isSubmitting,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter app link',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: AppColors.cardBackgroundLight(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    // Validate form
                                    if (nameController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter your name'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    if (emailController.text.trim().isEmpty ||
                                        !emailController.text.contains('@')) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter a valid email'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    if (mobileController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter mobile number'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    if (appController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter app name'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isSubmitting = true;
                                    });

                                    try {
                                      final token =
                                          await StorageService.getToken();
                                      if (token == null || token.isEmpty) {
                                        setState(() {
                                          isSubmitting = false;
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Authentication required'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      final result =
                                          await ApiService.submitSponsorPromotion(
                                        token: token,
                                        sponsorName: nameController.text.trim(),
                                        mobileNumber:
                                            mobileController.text.trim(),
                                        email: emailController.text.trim(),
                                        appPromotion: appController.text.trim(),
                                      );

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        if (result['success'] == true) {
                                          _showSuccessDialog(context);
                                        } else {
                                          _showErrorDialog(
                                              context, result['message']);
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        _showErrorDialog(
                                            context, 'Error: ${e.toString()}');
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C5CE7),
                  Color(0xFF8B7AE8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6C5CE7),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Success!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your sponsor promotion request has been submitted successfully. Our team will review it shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            child: GestureDetector(
              onTap: () => _handleHelpSupport(),
              child: _buildSettingsItem(
                icon: Icons.headset_mic_outlined,
                title: 'Help & Support',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGAL',
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                  child: _buildSettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                ),
                _buildDivider(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                  child: _buildSettingsItem(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
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

  Future<void> _handleHelpSupport() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to access support'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await ApiService.getSupportLink(token: token);

      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final isActive = data['isActive'] ?? false;
        final supportLink = data['supportLink'];

        if (isActive && supportLink != null && supportLink.toString().isNotEmpty) {
          // Open support link in browser
          final uri = Uri.parse(supportLink.toString());
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to open support link'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Support is inactive or link not available
          final note = data['note'] ?? 'Support is currently unavailable';
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.cardBackground(context),
                title: const Text(
                  'Support Unavailable',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  note,
                  style: const TextStyle(color: Colors.grey),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to fetch support link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
