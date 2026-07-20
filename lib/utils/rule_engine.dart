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
  static RuleResult evaluasi(Motor motor, List<ServiceModel> riwayatServis) {
    List<String> daftarRekomendasi = [];
    int komponenTerlambat = 0;

    int kmSekarang = motor.kilometerSaatIni;
    DateTime tanggalHariIni = DateTime.now();
    
    // =========================================================================
    // FUNGSI BANTUAN UNTUK PENCARIAN KOMPONEN
    // =========================================================================
    
    ServiceModel? getServisTerakhir(String keyword) {
      try {
        return riwayatServis.firstWhere((s) => 
          s.jenisService.toLowerCase().contains(keyword.toLowerCase()) && 
          s.status.toLowerCase() != 'upcoming' 
        );
      } catch (e) {
        return null; 
      }
    }

    int getDeltaKm(String keyword) {
      final servis = getServisTerakhir(keyword);
      if (servis != null) {
        return kmSekarang - servis.kilometerService;
      }
      return kmSekarang; 
    }

    // Khusus untuk Minyak Rem yang dihitung berdasarkan Bulan
    int getDeltaBulan(String keyword) {
      final servis = getServisTerakhir(keyword);
      if (servis != null) {
        DateTime tglServis = DateTime.parse(servis.tanggalService);
        return (tanggalHariIni.difference(tglServis).inDays / 30).floor();
      }
      // Jika belum pernah diservis, asumsikan umur dari 1 Januari tahun perakitan
      DateTime asumsiBeli = DateTime(motor.tahun, 1, 1);
      return (tanggalHariIni.difference(asumsiBeli).inDays / 30).floor();
    }

    // =========================================================================
    // PERHITUNGAN DELTA BERDASARKAN KNOWLEDGE BASE BARU
    // =========================================================================
    
    int deltaOli = getDeltaKm('oli');
    int deltaFilter = getDeltaKm('filter');
    int deltaBusi = getDeltaKm('busi');
    int deltaMinyakRem = getDeltaBulan('minyak rem');
    
    // Mengecek V-Belt atau CVT
    int deltaVBelt = getDeltaKm('v-belt');
    if (getServisTerakhir('v-belt') == null) {
      deltaVBelt = getDeltaKm('cvt');
    }

    String tipe = motor.tipeMotor.toLowerCase();
    bool isWaktunyaServisBerkala = false;

    // =========================================================================
    // EVALUASI 8 RULE BERDASARKAN TABEL ACUAN PABRIKAN
    // =========================================================================
    
    // 1. Rule Oli Mesin (4.000 km)
    if (deltaOli >= 4000) {
      daftarRekomendasi.add('Ganti Oli Mesin: Sudah melewati batas 4.000 km');
      komponenTerlambat++;
      isWaktunyaServisBerkala = true; // Ganti oli menjadi patokan utama servis berkala
    }

    // 2. Rule Filter Udara (12.000 km)
    if (deltaFilter >= 12000) {
      daftarRekomendasi.add('Ganti Filter Udara: Sudah melewati batas 12.000 km');
      komponenTerlambat++;
    }

    // 3. Rule Busi (8.000 km)
    if (deltaBusi >= 8000) {
      daftarRekomendasi.add('Ganti Busi: Sudah melewati batas 8.000 km');
      komponenTerlambat++;
    }

    // 4. Rule Minyak Rem (24 Bulan / 2 Tahun)
    if (deltaMinyakRem >= 24) {
      daftarRekomendasi.add('Ganti Minyak Rem: Sudah melewati umur 24 bulan');
      komponenTerlambat++;
    }

    // 5. Rule V-Belt (25.000 km) - Dieksekusi khusus untuk motor Matic
    if (tipe.contains('matic') && deltaVBelt >= 25000) {
      daftarRekomendasi.add('Ganti V-Belt: Sudah melewati batas 25.000 km');
      komponenTerlambat++;
    }

    // 6, 7, 8. Rule Kampas Rem, Ban, dan Aki (Pemeriksaan Setiap Servis)
    // Sesuai tabel, tiga komponen ini berstatus "Perlu Pemeriksaan" saat servis berkala tiba
    if (isWaktunyaServisBerkala) {
      daftarRekomendasi.add('Pemeriksaan Rutin: Cek kondisi Ban, Kampas Rem, dan Aki');
    }

    // =========================================================================
    // KESIMPULAN STATUS AKHIR (CONFLICT RESOLUTION)
    // =========================================================================
    
    String statusAkhir = 'Baik';
    
    // Karena rule disederhanakan, batas prioritas juga kita sesuaikan
    if (komponenTerlambat >= 3) {
      statusAkhir = 'Kritis'; // Jika ada 3 atau lebih komponen yang terlambat
    } else if (komponenTerlambat > 0) {
      statusAkhir = 'Perlu Servis'; // Jika ada 1 atau 2 komponen yang terlambat
    }

    // Jika tidak ada masalah sama sekali
    if (daftarRekomendasi.isEmpty) {
      daftarRekomendasi.add('Kondisi motor aman. Rutin periksa Ban, Rem, dan Aki.');
    }

    return RuleResult(
      statusAkhir: statusAkhir,
      rekomendasi: daftarRekomendasi,
      jumlahTerlambat: komponenTerlambat,
    );
  }
}