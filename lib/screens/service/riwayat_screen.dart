import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:motor_care/models/service.dart';
import 'package:motor_care/repositories/service_repository.dart';
import 'package:motor_care/screens/service/service_form_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _serviceRepo = ServiceRepository();
  List<ServiceModel> _allRiwayat = [];
  List<ServiceModel> _filteredRiwayat = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    final allServices = await _serviceRepo.getServices();
    setState(() {
      // FITUR: Hanya mengambil data riwayat yang sudah Selesai (Done) atau Terlewat (Overdue)
      _allRiwayat = allServices.where((s) => s.status != 'Upcoming').toList();
      
      // Mengurutkan dari yang terbaru ke terlama
      _allRiwayat.sort((a, b) => b.tanggalService.compareTo(a.tanggalService));
      
      _filteredRiwayat = _allRiwayat;
      _isLoading = false;
    });
  }

  // FITUR PENDUKUNG: Fungsi Pencarian (Search)
  void _filterRiwayat(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRiwayat = _allRiwayat;
      } else {
        _filteredRiwayat = _allRiwayat.where((s) => 
          s.jenisService.toLowerCase().contains(query.toLowerCase()) ||
          s.catatan.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _hapusService(int id) async {
    await _serviceRepo.deleteService(id);
    _loadRiwayat();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat dihapus'), backgroundColor: CupertinoColors.destructiveRed),
      );
    }
  }

  // WIDGET KHUSUS: Desain persis seperti referensi SC temanmu
  Widget _buildEmptyState() {
    // Jika tidak ada data sama sekali (bukan karena pencarian tidak ketemu)
    if (_allRiwayat.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'Belum ada riwayat service',
              style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    } 
    // Jika data ada, tapi hasil pencarian (search) tidak ditemukan
    else {
      return const Center(
        child: Text('Pencarian tidak ditemukan', style: TextStyle(color: Colors.grey)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Riwayat Service', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                // FITUR PENDUKUNG: Search Bar Elegan
             // FITUR PENDUKUNG: Search Bar Elegan
                if (_allRiwayat.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    // KITA BUNGKUS DENGAN CONTAINER UNTUK MEMBERIKAN SHADOW
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03), 
                            blurRadius: 10, 
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterRiwayat,
                        decoration: InputDecoration(
                          hintText: 'Cari riwayat (misal: Ganti Oli)...',
                          prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(CupertinoIcons.clear_thick_circled, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterRiwayat('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          // BOX SHADOW SUDAH DIHAPUS DARI SINI
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                // List Data atau Empty State
                Expanded(
                  child: _filteredRiwayat.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredRiwayat.length,
                          itemBuilder: (context, index) {
                            final service = _filteredRiwayat[index];
                            final isDone = service.status == 'Done';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDone ? Colors.green.shade50 : Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDone ? Icons.check_circle : Icons.cancel, 
                                    color: isDone ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  service.jenisService, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(CupertinoIcons.calendar, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(service.tanggalService, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          const SizedBox(width: 12),
                                          const Icon(CupertinoIcons.speedometer, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text('${service.kilometerService} KM', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(CupertinoIcons.trash, size: 20, color: Colors.grey),
                                  onPressed: () => _hapusService(service.id!),
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceFormScreen(service: service)));
                                  if (result == true) _loadRiwayat();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}