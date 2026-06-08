import 'package:flutter/material.dart';
import 'package:hook_point/screens/home_screen.dart';
import 'package:hook_point/screens/post_screen.dart';
import 'package:hook_point/screens/favorit_screen.dart';
import 'package:hook_point/screens/profil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PostScreen(),
    const FavoritScreen(),
    const ProfilScreen(),
  ];

  final List<String> _titles = [
    'HookPoint ',
    'Tambah Spot',
    'Favorit',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'HookPoint',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.phishing, size: 48),
                      children: const [
                        Text(
                          'Aplikasi komunitas berbagi spot mancing terbaik di Indonesia. ',
                        ),
                      ],
                    );
                  },
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
