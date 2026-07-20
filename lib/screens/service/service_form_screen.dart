import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:motor_care/models/motor.dart';
import 'package:motor_care/models/service.dart';
import 'package:motor_care/repositories/motor_repository.dart';
import 'package:motor_care/repositories/service_repository.dart';
import 'package:motor_care/screens/service/notification_service.dart';

class ServiceFormScreen extends StatefulWidget {
  final ServiceModel? service;
  final int? prefilledMotorId;
  final String? prefilledJenisService;

  const ServiceFormScreen({
    super.key, 
    this.service,
    this.prefilledMotorId,
    this.prefilledJenisService,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceRepo = ServiceRepository();
  final _motorRepo = MotorRepository();

  List<Motor> _motors = [];
  int? _selectedMotorId;
  String _selectedStatus = 'Upcoming';
  bool _isLoading = false;

  final _jenisController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _kilometerController = TextEditingController();
  final _catatanController = TextEditingController();

  final List<String> _statusOptions = ['Upcoming', 'Done', 'Overdue'];
  
  // Warna tombol biru gelap dari referensi desain
  final Color _darkBlue = const Color(0xFF305B85); 

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadMotors();
  }

  void _updateKilometerOtomatis(int? motorId) {
    if (motorId == null) return;
    final selectedMotor = _motors.firstWhere((m) => m.id == motorId);
    if (widget.service == null) { 
      _kilometerController.text = selectedMotor.kilometerSaatIni.toString();
    }
  }

  Future<void> _loadMotors() async {
    final motors = await _motorRepo.getMotors();
    setState(() {
      _motors = motors;
      
      if (widget.service != null) {
        _selectedMotorId = widget.service!.motorId;
        _jenisController.text = widget.service!.jenisService;
        _tanggalController.text = widget.service!.tanggalService;
        _kilometerController.text = widget.service!.kilometerService.toString();
        _catatanController.text = widget.service!.catatan;
        _selectedStatus = widget.service!.status;
      } 
      else {
        if (widget.prefilledMotorId != null) {
          _selectedMotorId = widget.prefilledMotorId;
        } else if (_motors.isNotEmpty) {
          _selectedMotorId = _motors.first.id;
        }

        if (widget.prefilledJenisService != null) {
          _jenisController.text = widget.prefilledJenisService!;
        }
        
        _updateKilometerOtomatis(_selectedMotorId);
      }
    });
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMotorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan tambah data motor dulu!')));
        return;
      }
      setState(() => _isLoading = true);

      try {
        final serviceData = ServiceModel(
          id: widget.service?.id,
          motorId: _selectedMotorId!,
          jenisService: _jenisController.text,
          tanggalService: _tanggalController.text,
          kilometerService: int.parse(_kilometerController.text),
          catatan: _catatanController.text,
          status: _selectedStatus,
        );

        int savedId;
        if (widget.service == null) {
          savedId = await _serviceRepo.insertService(serviceData);
        } else {
          await _serviceRepo.updateService(serviceData);
          savedId = widget.service!.id!;
        }

        // LOGIKA NOTIFIKASI
        if (_selectedStatus == 'Upcoming') {
          DateTime? targetDate = DateTime.tryParse(_tanggalController.text);
          if (targetDate != null) {
            final serviceDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 8, 0);
            final now = DateTime.now();
            final notifService = NotificationService();
            
            final h7 = serviceDate.subtract(const Duration(days: 7));
            if (h7.isAfter(now)) {
              await notifService.scheduleNotification(id: savedId * 10 + 7, title: 'Reminder H-7 Service', body: 'Motor butuh service ${_jenisController.text} minggu depan!', scheduledDate: h7);
            }
            
            final h3 = serviceDate.subtract(const Duration(days: 3));
            if (h3.isAfter(now)) {
              await notifService.scheduleNotification(id: savedId * 10 + 3, title: 'Reminder H-3 Service', body: 'Jadwal service ${_jenisController.text} tinggal 3 hari lagi!', scheduledDate: h3);
            }

            if (serviceDate.isAfter(now)) {
              await notifService.scheduleNotification(id: savedId * 10 + 0, title: 'Hari Ini Jadwal Service!', body: 'Jangan lupa service ${_jenisController.text} hari ini.', scheduledDate: serviceDate);
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data Service disimpan!'), backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: CupertinoColors.destructiveRed));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // WIDGET BANTUAN: Dekorasi Input sesuai dengan Referensi Desain
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[700], size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _darkBlue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_motors.isEmpty && widget.service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tambah Jadwal Service')),
        body: const Center(child: Text('Data Motor kosong. Tambah motor dulu.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.service == null ? 'Tambah Jadwal Service' : 'Edit Service',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Pilih Motor
                DropdownButtonFormField<int>(
                  value: _selectedMotorId,
                  decoration: _inputDecoration('Pilih Motor', Icons.two_wheeler),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: _motors.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.merk} ${m.namaMotor}'))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedMotorId = val);
                    _updateKilometerOtomatis(val);
                  },
                  validator: (val) => val == null ? 'Wajib dipilih' : null,
                ),
                const SizedBox(height: 16),

                // 2. Jenis Service
                TextFormField(
                  controller: _jenisController,
                  decoration: _inputDecoration('Jenis Service', CupertinoIcons.wrench),
                  validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // 3. Tanggal Service
                TextFormField(
                  controller: _tanggalController,
                  readOnly: true,
                  onTap: () => _pilihTanggal(context),
                  decoration: _inputDecoration('Tanggal Service', Icons.calendar_today_outlined),
                ),
                const SizedBox(height: 16),

                // 4. Kilometer Service
                TextFormField(
                  controller: _kilometerController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Kilometer Service', CupertinoIcons.speedometer),
                  validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // 5. Status Service
                // Tetap dipertahankan agar pengguna bisa mengubah ke "Done" saat riwayat selesai
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: _inputDecoration('Status Service', Icons.info_outline),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
                const SizedBox(height: 16),

                // 6. Catatan
                TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 48), // Mendorong ikon ke atas agar sejajar dengan baris pertama teks
                      child: Icon(Icons.notes, color: Colors.grey[700], size: 22),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black26)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black26)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _darkBlue, width: 2)),
                  ),
                ),
                const SizedBox(height: 32),

                // 7. Tombol Simpan
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _simpanData,
                    icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save_outlined, size: 20),
                    label: _isLoading 
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text('Simpan Jadwal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}