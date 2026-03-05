import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'wallet/wallet_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      WalletScreen(onBack: _goToHome),
      HistoryScreen(onBack: _goToHome),
      ProfileScreen(onBack: _goToHome),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
