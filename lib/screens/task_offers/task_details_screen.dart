import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> app;

  const TaskDetailsScreen({
    super.key,
    required this.app,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  bool _step1Completed = false; // Download
  bool _step2Completed = false; // Verify/Register
  File? _screenshot;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = widget.app['appId'] ?? '';
    final step1 = prefs.getBool('step1_$appId') ?? false;
    final step2 = prefs.getBool('step2_$appId') ?? false;

    setState(() {
      _step1Completed = step1;
      _step2Completed = step2;
    });
  }

  Future<void> _saveDownloadUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final appId = widget.app['appId'] ?? '';
    await prefs.setString('download_url_$appId', url);
  }

  Future<void> _markStepComplete(int step) async {
    final prefs = await SharedPreferences.getInstance();
    final appId = widget.app['appId'] ?? '';
    if (step == 1) {
      await prefs.setBool('step1_$appId', true);
      setState(() {
        _step1Completed = true;
      });
    } else if (step == 2) {
      await prefs.setBool('step2_$appId', true);
      setState(() {
        _step2Completed = true;
      });
    }
  }

  Future<void> _handleDownload() async {
    final downloadUrl = widget.app['appDownloadUrl'] ?? '';
    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(downloadUrl);
      
      // Launch URL in browser/external app
      try {
        // Use platformDefault to open in browser, or externalApplication as fallback
        final launched = await launcher.launchUrl(
          uri,
          mode: launcher.LaunchMode.externalApplication,
        );

        if (launched) {
          // Save URL locally
          await _saveDownloadUrl(downloadUrl);
          // Mark step 1 as complete
          await _markStepComplete(1);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening download link in browser...'),
                backgroundColor: AppColors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // If launch returns false, try alternative method
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open URL. Please try again.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (launchError) {
        // If launch fails, show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening URL: ${launchError.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid URL format: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleVerify() async {
    // Mark step 2 as complete
    await _markStepComplete(2);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification step completed!'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _captureScreenshot() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground(context),
        title: Text(
          'Capture Screenshot',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take Photo', style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (image != null) {
        setState(() {
          _screenshot = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing screenshot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitTask() async {
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a screenshot first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final appId = widget.app['appId'] ?? '';
      final result = await ApiService.submitAppInstallation(
        token: token,
        appId: appId,
        screenshotFile: _screenshot,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Task submitted successfully'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Navigate back after successful submission
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit task'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = widget.app['appName'] ?? 'Unknown App';
    final appImage = widget.app['appImage'] ?? '';
    final rewardCoins = widget.app['rewardCoins'] ?? 0;
    final description = widget.app['description'] ?? '';

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
          'Task Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Image Card
            Container(
              width: double.infinity,
              height: 250,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.cardBackground(context),
              ),
              clipBehavior: Clip.antiAlias,
              child: appImage.isNotEmpty
                  ? Image.network(
                      appImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.cardBackgroundLight(context),
                        child: const Icon(
                          Icons.apps,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.cardBackgroundLight(context),
                      child: const Icon(
                        Icons.apps,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
            ),

            // Task Title and Reward
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Install & Register - $appName',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary, // Primary blue
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹ $rewardCoins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                description.isNotEmpty
                    ? description
                    : 'Complete the steps below to earn real cash. Ensure you are a new user to the app to qualify for the reward.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Steps to Earn Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Steps to Earn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Step 1: Download the App
            _buildDownloadStep(),

            const SizedBox(height: 24),

            // Step 2: Register Account
            _buildStep(
              stepNumber: 2,
              title: 'Register Account',
              description: 'Sign up using your mobile number and verify OTP.',
              isCompleted: _step2Completed,
              buttonText: 'Verify',
              buttonIcon: Icons.verified,
              onButtonTap: _handleVerify,
            ),

            const SizedBox(height: 24),

            // Step 3: Capture Screenshot
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _screenshot != null
                          ? AppColors.primary
                          : AppColors.cardBackgroundLight(context),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: _screenshot != null ? Colors.white : AppColors.textSecondary(context),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capture Screenshot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _screenshot != null ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Take a screenshot of the installed app',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        if (_screenshot != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _screenshot!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Capture Screenshot Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _captureScreenshot,
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: Text(_screenshot != null ? 'Change Screenshot' : 'Capture Screenshot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground(context),
                    foregroundColor: AppColors.textPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Task Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_screenshot != null && !_isSubmitting) ? _submitTask : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check, size: 24),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Task',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _step1Completed
                  ? AppColors.primary
                  : AppColors.cardBackgroundLight(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _step1Completed
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text(
                      '1',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download the App',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _step1Completed ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Click the link below to download the app from the Play Store.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleDownload,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Download Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required String description,
    required bool isCompleted,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onButtonTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary
                  : AppColors.cardBackgroundLight(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isCompleted ? null : onButtonTap,
                    icon: Icon(buttonIcon, size: 18),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? AppColors.cardBackgroundLight(context)
                          : AppColors.primary,
                      foregroundColor: isCompleted
                          ? AppColors.textSecondary(context)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
