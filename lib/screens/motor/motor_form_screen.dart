import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart'; // Import ini dibutuhkan untuk format tanggal
import 'package:motor_care/models/motor.dart';
import 'package:motor_care/repositories/motor_repository.dart';

class MotorFormScreen extends StatefulWidget {
  final Motor? motor;
  const MotorFormScreen({super.key, this.motor});

  @override
  State<MotorFormScreen> createState() => _MotorFormScreenState();
}

class _MotorFormScreenState extends State<MotorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motorRepo = MotorRepository();

  final _merkController = TextEditingController();
  final _namaController = TextEditingController();
  final _tipeController = TextEditingController(); // Disesuaikan dengan tipeMotor
  final _tahunController = TextEditingController(); // Disesuaikan dengan tahun
  final _nopolController = TextEditingController();
  final _kmController = TextEditingController();
  final _tanggalPembelianController = TextEditingController(); // Tambahan baru

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.motor != null) {
      _merkController.text = widget.motor!.merk;
      _namaController.text = widget.motor!.namaMotor;
      _tipeController.text = widget.motor!.tipeMotor;
      _tahunController.text = widget.motor!.tahun.toString();
      _nopolController.text = widget.motor!.nomorPolisi;
      _kmController.text = widget.motor!.kilometerSaatIni.toString();
      _tanggalPembelianController.text = widget.motor!.tanggalPembelian;
    }
  }

  // Fungsi untuk memunculkan kalender iOS/Android
  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Maksimal hari ini
    );
    if (picked != null) {
      setState(() {
        _tanggalPembelianController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _simpanMotor() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final motorData = Motor(
          id: widget.motor?.id,
          merk: _merkController.text,
          namaMotor: _namaController.text,
          tipeMotor: _tipeController.text, // Sesuai model
          tahun: int.parse(_tahunController.text), // Sesuai model
          nomorPolisi: _nopolController.text,
          kilometerSaatIni: int.parse(_kmController.text),
          tanggalPembelian: _tanggalPembelianController.text, // Sesuai model
          fotoMotor: null, // Opsional, dikosongkan dulu
        );

        if (widget.motor == null) {
          await _motorRepo.insertMotor(motorData);
        } else {
          await _motorRepo.updateMotor(motorData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data Motor berhasil disimpan!'),
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

  // Widget untuk membuat input field ala iOS
  Widget _buildIOSField({
    required String label, 
    required TextEditingController controller, 
    TextInputType type = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.motor == null ? 'Tambah Motor' : 'Edit Motor'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Tutup keyboard saat tap di luar
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text('INFORMASI KENDARAAN', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                _buildIOSField(label: 'Merek (Misal: Honda, Yamaha)', controller: _merkController),
                _buildIOSField(label: 'Nama Motor (Misal: Vario 150)', controller: _namaController),
                _buildIOSField(label: 'Tipe Motor (Misal: Matic, Sport)', controller: _tipeController),
                _buildIOSField(label: 'Tahun Keluaran', controller: _tahunController, type: TextInputType.number),
                _buildIOSField(label: 'Nomor Polisi (Misal: D 1234 ABC)', controller: _nopolController),
                _buildIOSField(label: 'Kilometer Saat Ini', controller: _kmController, type: TextInputType.number),
                
                // Field baru untuk Tanggal Pembelian
                _buildIOSField(
                  label: 'Tanggal Pembelian', 
                  controller: _tanggalPembelianController, 
                  readOnly: true,
                  onTap: () => _pilihTanggal(context),
                ),
                
                const SizedBox(height: 24),
                
                CupertinoButton(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isLoading ? null : _simpanMotor,
                  child: _isLoading 
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text('Simpan Data Motor', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}