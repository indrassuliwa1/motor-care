import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:motor_care/models/service.dart';
import 'package:motor_care/repositories/service_repository.dart';
import 'package:motor_care/screens/service/service_form_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _serviceRepo = ServiceRepository();
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final services = await _serviceRepo.getServices();
    setState(() {
      _services = services;
      _isLoading = false;
    });
  }

  Future<void> _hapusService(int id) async {
    await _serviceRepo.deleteService(id);
    _loadServices();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat service dihapus'), backgroundColor: CupertinoColors.destructiveRed),
      );
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'Upcoming') return CupertinoColors.activeBlue;
    if (status == 'Overdue') return CupertinoColors.destructiveRed;
    return CupertinoColors.activeGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Service'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled_solid, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServiceFormScreen()),
              );
              if (result == true) _loadServices();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _services.isEmpty
              ? const Center(
                  child: Text('Belum ada riwayat service.', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(service.status).withValues(alpha: 0.1),
                          child: Icon(CupertinoIcons.wrench_fill, color: _getStatusColor(service.status)),
                        ),
                        title: Text(service.jenisService, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Tanggal: ${service.tanggalService}'),
                            Text('KM: ${service.kilometerService}'),
                            const SizedBox(height: 4),
                            Text(
                              service.status,
                              style: TextStyle(color: _getStatusColor(service.status), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                          onPressed: () => _hapusService(service.id!),
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ServiceFormScreen(service: service)),
                          );
                          if (result == true) _loadServices();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}