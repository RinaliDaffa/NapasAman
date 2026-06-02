import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../../data/models/alert_threshold.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/threshold_card.dart';
import '../widgets/alert_history_card.dart';
import '../widgets/aqi_legend.dart';
import '../widgets/add_edit_threshold_dialog.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });

    // Load data ketika screen dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final alertProvider = context.read<AlertProvider>();

      if (authProvider.isLoggedIn && authProvider.user != null) {
        await alertProvider.loadAlertHistory(authProvider.user!.uid);
        await alertProvider.loadThresholds(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistem Peringatan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Cek AQI Sekarang',
            onPressed: () async {
              final alertProvider = context.read<AlertProvider>();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Memeriksa AQI untuk semua threshold...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await alertProvider.manualCheck();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pemeriksaan selesai')),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Threshold'),
            Tab(text: 'Riwayat Alert'),
          ],
        ),
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildThresholdTab(context, alertProvider),
              _buildHistoryTab(context, alertProvider),
            ],
          );
        },
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddThresholdDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildThresholdTab(BuildContext context, AlertProvider alertProvider) {
    if (alertProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (alertProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${alertProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (auth.user != null) {
                  alertProvider.loadThresholds(auth.user!.uid);
                }
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const AqiLegend(),
          if (alertProvider.thresholds.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.warning_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada threshold',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan threshold untuk mulai menerima notifikasi',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alertProvider.thresholds.length,
              itemBuilder: (context, index) {
                final threshold = alertProvider.thresholds[index];
                return ThresholdCard(
                  threshold: threshold,
                  onEdit: () => _showEditThresholdDialog(context, threshold),
                  onDelete: () => _deleteThreshold(context, alertProvider, threshold.id),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, AlertProvider alertProvider) {
    if (alertProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (alertProvider.alertHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada alert',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Riwayat alert akan muncul di sini saat AQI melampaui threshold',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Alert: ${alertProvider.alertHistory.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _clearHistory(context, alertProvider),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Bersihkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alertProvider.alertHistory.length,
            itemBuilder: (context, index) {
              final history = alertProvider.alertHistory[index];
              return AlertHistoryCard(
                history: history,
                onDelete: () => _deleteAlertHistory(context, alertProvider, history.id),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAddThresholdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddEditThresholdDialog(
        onSubmit: (city, aqi, label) {
          final auth = context.read<AuthProvider>();
          final alertProvider = context.read<AlertProvider>();

          if (auth.user != null) {
            alertProvider.createThreshold(
              auth.user!.uid,
              city,
              aqi,
              label: label,
            );
          }
        },
      ),
    );
  }

  void _showEditThresholdDialog(BuildContext context, AlertThreshold threshold) {
    showDialog(
      context: context,
      builder: (context) => AddEditThresholdDialog(
        city: threshold.city,
        initialAqi: threshold.aqi,
        initialLabel: threshold.label,
        onSubmit: (city, aqi, label) {
          final alertProvider = context.read<AlertProvider>();
          alertProvider.updateThreshold(threshold.id, aqi, newLabel: label);
        },
      ),
    );
  }

  void _deleteThreshold(BuildContext context, AlertProvider alertProvider, String thresholdId) {
    alertProvider.deleteThreshold(thresholdId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Threshold dihapus')),
    );
  }

  void _deleteAlertHistory(BuildContext context, AlertProvider alertProvider, String historyId) {
    alertProvider.deleteAlertHistory(historyId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert dihapus')),
    );
  }

  void _clearHistory(BuildContext context, AlertProvider alertProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bersihkan Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final auth = context.read<AuthProvider>();
              if (auth.user != null) {
                alertProvider.clearAlertHistory(auth.user!.uid);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Riwayat alert dibersihkan')),
              );
            },
            child: const Text('Bersihkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
