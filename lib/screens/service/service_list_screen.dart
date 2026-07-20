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
  List<ServiceModel> _jadwalServices = [];
  bool _isLoading = true;

  // Warna-warna kustom dari desain referensi
  final Color _darkBlue = const Color(0xFF305B85); // Warna tombol biru gelap
  final Color _lightBlue = const Color(0xFFD6E4FF); // Warna FAB biru muda

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final allServices = await _serviceRepo.getServices();
    setState(() {
      // FILTER KHUSUS: Hanya mengambil data yang statusnya 'Upcoming' (Jadwal)
      _jadwalServices = allServices.where((s) => s.status == 'Upcoming').toList();
      
      // Urutkan jadwal dari yang paling dekat harinya
      _jadwalServices.sort((a, b) => a.tanggalService.compareTo(b.tanggalService));
      
      _isLoading = false;
    });
  }

  Future<void> _hapusService(int id) async {
    await _serviceRepo.deleteService(id);
    _loadServices();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal service dihapus'), backgroundColor: CupertinoColors.destructiveRed),
      );
    }
  }

  // Fungsi navigasi ke halaman form
  Future<void> _goToForm([ServiceModel? service]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServiceFormScreen(service: service)),
    );
    if (result == true) _loadServices();
  }

  // WIDGET KHUSUS: Tampilan saat Jadwal Kosong (Empty State)
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 100, color: _darkBlue),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Jadwal Service',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tambahkan jadwal service agar aplikasi dapat membantu mengingatkan waktu perawatan motor secara berkala.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Tombol Tambah Jadwal di tengah layar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => _goToForm(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tambah Jadwal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Background abu-abu muda bersih
      appBar: AppBar(
        title: const Text('Jadwal Service', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      
      // Floating Action Button (FAB) Kanan Bawah
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _lightBlue,
        elevation: 2,
        onPressed: () => _goToForm(),
        icon: Icon(Icons.add, color: _darkBlue),
        label: Text('Tambah Jadwal', style: TextStyle(color: _darkBlue, fontWeight: FontWeight.bold)),
      ),
      
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _jadwalServices.isEmpty
              // Jika kosong, panggil Widget Empty State
              ? _buildEmptyState()
              
              // Jika ada data, tampilkan dalam bentuk List Card
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Bottom padding agar tidak tertutup FAB
                  itemCount: _jadwalServices.length,
                  itemBuilder: (context, index) {
                    final service = _jadwalServices[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.calendar_today, color: _darkBlue),
                        ),
                        title: Text(service.jenisService, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.date_range, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(service.tanggalService, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.speed, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${service.kilometerService} KM', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                          onPressed: () => _hapusService(service.id!),
                        ),
                        onTap: () => _goToForm(service),
                      ),
                    );
                  },
                ),
    );
  }
}