import 'package:motor_care/models/motor.dart';
import 'package:motor_care/models/service.dart';

class RuleResult {
  final String statusAkhir;
  final List<String> rekomendasi;
  final int jumlahTerlambat;

  RuleResult({
    required this.statusAkhir,
    required this.rekomendasi,
    required this.jumlahTerlambat,
  });
}

class RuleEngine {
  // PERUBAHAN: Sekarang menerima seluruh daftar riwayat servis (List<ServiceModel>)
  static RuleResult evaluasi(Motor motor, List<ServiceModel> riwayatServis) {
    List<String> daftarRekomendasi = [];
    int komponenTerlambat = 0;

    int kmSekarang = motor.kilometerSaatIni;
    DateTime tanggalHariIni = DateTime.now();
    int tahunSekarang = tanggalHariIni.year;
    
    // Umur motor keseluruhan (untuk Ban & Aki bawaan)
    int umurMotorBulan = (tahunSekarang - motor.tahun) * 12;

    // =========================================================================
    // FUNGSI BANTUAN UNTUK PENCARIAN KOMPONEN
    // =========================================================================
    
    // 1. Mencari data servis terakhir berdasarkan KATA KUNCI (misal: "rem", "oli")
    ServiceModel? getServisTerakhir(String keyword) {
      try {
        // Karena data dari Dashboard nanti sudah diurutkan dari yang terbaru,
        // .firstWhere akan otomatis mendapatkan servis paling akhir (terbaru)
        return riwayatServis.firstWhere((s) => 
          s.jenisService.toLowerCase().contains(keyword.toLowerCase()) && 
          s.status.toLowerCase() != 'upcoming' // Hanya hitung servis yang sudah selesai
        );
      } catch (e) {
        return null; // Jika belum pernah diservis sama sekali
      }
    }

    // 2. Menghitung Delta KM spesifik per komponen
    int getDeltaKm(String keyword) {
      final servis = getServisTerakhir(keyword);
      if (servis != null) {
        return kmSekarang - servis.kilometerService;
      }
      return kmSekarang; // Jika belum pernah, hitung dari KM 0
    }

    // 3. Menghitung Delta Hari (Khusus Oli)
    int getDeltaHari(String keyword) {
      final servis = getServisTerakhir(keyword);
      if (servis != null) {
        DateTime tglServis = DateTime.parse(servis.tanggalService);
        return tanggalHariIni.difference(tglServis).inDays;
      }
      // Jika belum pernah ganti oli, asumsikan dari 1 Januari tahun pembuatan
      DateTime asumsiBeli = DateTime(motor.tahun, 1, 1);
      return tanggalHariIni.difference(asumsiBeli).inDays;
    }

    // =========================================================================
    // PERHITUNGAN DELTA (SELISIH) SPESIFIK
    // =========================================================================
    
    int deltaOli = getDeltaKm('oli');
    int deltaHariOli = getDeltaHari('oli');
    
    int deltaRem = getDeltaKm('rem');
    int deltaBusi = getDeltaKm('busi');
    int deltaFilter = getDeltaKm('filter');
    
    String tipe = motor.tipeMotor.toLowerCase();
    int deltaTransmisi = getDeltaKm(tipe.contains('matic') ? 'cvt' : 'rantai');

    // =========================================================================
    // EVALUASI RULE BERDASARKAN DELTA MASING-MASING
    // =========================================================================
    
    if (deltaOli >= 3000 || deltaHariOli >= 90) {
      daftarRekomendasi.add('Oli Mesin: Terlambat! Segera Ganti (Prioritas Tinggi)');
      komponenTerlambat++;
    } else if (deltaOli >= 2000 || deltaHariOli >= 60) {
      daftarRekomendasi.add('Oli Mesin: Waktunya Ganti Oli Berkala');
      komponenTerlambat++;
    }

    // Umur komponen bawaan (Ban & Aki) dihitung dari umur total motor
    if (umurMotorBulan >= 24) {
      daftarRekomendasi.add('Ban: Periksa Kondisi Ban (Umur > 24 Bulan)');
    }
    if (umurMotorBulan >= 24) {
      daftarRekomendasi.add('Aki: Periksa Tegangan Aki (Umur > 24 Bulan)');
    }

    if (deltaRem >= 10000) {
      daftarRekomendasi.add('Kampas Rem: Periksa Ketebalan Kampas Rem');
      komponenTerlambat++;
    }

    if (deltaBusi >= 8000) {
      daftarRekomendasi.add('Busi: Waktunya Ganti Busi');
      komponenTerlambat++;
    }

    if (deltaFilter >= 12000) {
      daftarRekomendasi.add('Filter Udara: Bersihkan/Ganti Filter Udara');
      komponenTerlambat++;
    }

    if (tipe.contains('matic') && deltaTransmisi >= 12000) {
      daftarRekomendasi.add('Transmisi: Servis CVT (Khusus Matic)');
      komponenTerlambat++;
    } else if (!tipe.contains('matic') && deltaTransmisi >= 1000) {
      daftarRekomendasi.add('Transmisi: Lumasi Rantai (Jarak > 1.000 KM)');
      komponenTerlambat++;
    }

    // =========================================================================
    // KESIMPULAN STATUS AKHIR
    // =========================================================================
    
    String statusAkhir = 'Baik';
    if (komponenTerlambat > 4) {
      statusAkhir = 'Kritis';
    } else if (komponenTerlambat > 2) {
      statusAkhir = 'Perlu Perhatian';
    } else if (komponenTerlambat > 0) {
      statusAkhir = 'Perlu Servis';
    }

    if (daftarRekomendasi.isEmpty) {
      daftarRekomendasi.add('Semua komponen aman. Tidak ada perawatan mendesak.');
    }

    return RuleResult(
      statusAkhir: statusAkhir,
      rekomendasi: daftarRekomendasi,
      jumlahTerlambat: komponenTerlambat,
    );
  }
}