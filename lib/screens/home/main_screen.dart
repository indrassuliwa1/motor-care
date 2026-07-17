import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino untuk ikon iOS
import 'package:motor_care/screens/home/dashboard_screen.dart';
import 'package:motor_care/screens/motor/motor_list_screen.dart';
import 'package:motor_care/screens/service/service_list_screen.dart';
import 'package:motor_care/screens/notification/notification_screen.dart';
import 'package:motor_care/screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Pastikan ada <MainScreen>
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MotorListScreen(),
    const ServiceListScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: CupertinoColors.activeBlue,
          unselectedItemColor: CupertinoColors.inactiveGray,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.car_detailed), label: 'Motor'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.wrench_fill), label: 'Service'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.bell_fill), label: 'Notif'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}