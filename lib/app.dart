import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/auth_provider.dart';
import 'features/alerts/presentation/providers/alert_provider.dart';
import 'features/locations/presentation/providers/location_provider.dart';
import 'shared/widgets/app_bottom_nav.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/locations/presentation/screens/locations_screen.dart';
import 'features/alerts/presentation/screens/alerts_screen.dart';

class NapasAmanApp extends StatelessWidget {
  const NapasAmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'NapasAman',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isLoggedIn ? const MainShell() : const LoginScreen();
          },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LocationsScreen(),
    const AlertsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  auth.user?.email ?? 'User',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'NapasAman User',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 16),
                _buildProfileTile(
                  icon: Icons.notifications,
                  title: 'Pengaturan Notifikasi',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi dikelola dari tab Alerts'),
                      ),
                    );
                  },
                ),
                _buildProfileTile(
                  icon: Icons.info_outline,
                  title: 'Tentang NapasAman',
                  onTap: () => _showAboutDialog(context),
                ),
                _buildProfileTile(
                  icon: Icons.bug_report,
                  title: 'Test Crash (Debug)',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Test Crashlytics'),
                        content: const Text(
                          'Ini akan mengirim test crash ke Firebase Crashlytics. App mungkin akan berhenti sebentar.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              FirebaseCrashlytics.instance.crash();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Kirim Test Crash'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => auth.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  static void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang NapasAman'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NapasAman v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Aplikasi pemantau kualitas udara (AQI) real-time untuk kota-kota di Indonesia. '
              'Mendukung notifikasi otomatis jika AQI melampaui batas aman.',
            ),
            SizedBox(height: 16),
            Text(
              'SDG 3 — Good Health and Well-being',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('Tim Pengembang:'),
            Text('• Daffa Rinali (5025231209) — Modul Lokasi'),
            Text('• Royyan (5025231223) — Modul Alerts'),
            SizedBox(height: 12),
            Text(
              'Data kualitas udara dari Open-Meteo API',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}