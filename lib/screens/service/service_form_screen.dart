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
  
  // Tambahan: Variabel untuk menerima data otomatis dari Dashboard
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

  @override
  void initState() {
    super.initState();
    _loadMotors();
  }

  Future<void> _loadMotors() async {
    final motors = await _motorRepo.getMotors();
    setState(() {
      _motors = motors;
      
      // Jika ini adalah mode EDIT (Data Service sudah ada)
      if (widget.service != null) {
        _selectedMotorId = widget.service!.motorId;
        _jenisController.text = widget.service!.jenisService;
        _tanggalController.text = widget.service!.tanggalService;
        _kilometerController.text = widget.service!.kilometerService.toString();
        _catatanController.text = widget.service!.catatan;
        _selectedStatus = widget.service!.status;
      } 
      // Jika ini mode TAMBAH BARU (termasuk dari klik Dashboard)
      else {
        // Cek apakah ada data otomatis (prefilled) dari Dashboard
        if (widget.prefilledMotorId != null) {
          _selectedMotorId = widget.prefilledMotorId;
        } else if (_motors.isNotEmpty) {
          _selectedMotorId = _motors.first.id;
        }

        if (widget.prefilledJenisService != null) {
          _jenisController.text = widget.prefilledJenisService!;
        }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan tambah data motor terlebih dahulu!')),
        );
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
              await notifService.scheduleNotification(
                id: savedId * 10 + 7, 
                title: 'Reminder H-7 Service', 
                body: 'Motor butuh service ${_jenisController.text} minggu depan!', 
                scheduledDate: h7
              );
            }
            
            final h3 = serviceDate.subtract(const Duration(days: 3));
            if (h3.isAfter(now)) {
              await notifService.scheduleNotification(
                id: savedId * 10 + 3, 
                title: 'Reminder H-3 Service', 
                body: 'Jadwal service ${_jenisController.text} tinggal 3 hari lagi!', 
                scheduledDate: h3
              );
            }

            if (serviceDate.isAfter(now)) {
              await notifService.scheduleNotification(
                id: savedId * 10 + 0, 
                title: 'Hari Ini Jadwal Service!', 
                body: 'Jangan lupa service ${_jenisController.text} hari ini.', 
                scheduledDate: serviceDate
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jadwal Service berhasil disimpan!'),
              backgroundColor: CupertinoColors.activeGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan: $e'),
              backgroundColor: CupertinoColors.destructiveRed,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Widget Input gaya iOS
  Widget _buildIOSField({required String label, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_motors.isEmpty && widget.service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tambah Service')),
        body: const Center(child: Text('Data Motor kosong. Tambah motor dulu.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Tambah Jadwal/Riwayat' : 'Edit Service'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text('DETAIL SERVICE', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                _buildIOSField(
                  label: 'Motor',
                  child: DropdownButtonFormField<int>(
                    value: _selectedMotorId,
                    decoration: const InputDecoration(labelText: 'Pilih Motor', border: InputBorder.none),
                    items: _motors.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.merk} ${m.namaMotor} (${m.nomorPolisi})'))).toList(),
                    onChanged: (val) => setState(() => _selectedMotorId = val),
                    validator: (val) => val == null ? 'Wajib dipilih' : null,
                  ),
                ),
                _buildIOSField(
                  label: 'Jenis',
                  child: TextFormField(
                    controller: _jenisController,
                    decoration: const InputDecoration(labelText: 'Jenis Service (Misal: Ganti Oli)', border: InputBorder.none),
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                _buildIOSField(
                  label: 'Tanggal',
                  child: TextFormField(
                    controller: _tanggalController,
                    readOnly: true,
                    onTap: () => _pilihTanggal(context),
                    decoration: const InputDecoration(labelText: 'Tanggal Service', border: InputBorder.none, suffixIcon: Icon(CupertinoIcons.calendar)),
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                _buildIOSField(
                  label: 'Kilometer',
                  child: TextFormField(
                    controller: _kilometerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Estimasi/Aktual Kilometer', border: InputBorder.none),
                    validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                _buildIOSField(
                  label: 'Status',
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status', border: InputBorder.none),
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                ),
                _buildIOSField(
                  label: 'Catatan',
                  child: TextFormField(
                    controller: _catatanController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Catatan (Opsional)', border: InputBorder.none),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                CupertinoButton(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isLoading ? null : _simpanData,
                  child: _isLoading 
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text('Simpan Service', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}