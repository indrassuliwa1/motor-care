import 'package:motor_care/models/motor.dart';
import 'package:motor_care/models/service.dart';

class RuleBasedService {
  
  /// RULE 1: Menentukan Rekomendasi berdasarkan Kilometer
  static List<String> generateRecommendations(Motor motor, List<ServiceModel> riwayatService) {
    List<String> recommendations = [];
    int km = motor.kilometerSaatIni;

    if (km >= 2000) {
      bool sudahGantiOliBaru = riwayatService.any((service) => 
        service.jenisService.toLowerCase().contains('oli') && 
        (km - service.kilometerService) < 2000
      );
      if (!sudahGantiOliBaru) {
        recommendations.add("Ganti Oli Mesin");
      }
    }

    if (km >= 8000) {
      recommendations.add("Periksa Kampas Rem");
    }

    if (km >= 12000) {
      recommendations.add("Ganti Busi");
    }

    if (km >= 24000) {
      recommendations.add("Servis CVT");
    }

    return recommendations;
  }

  /// RULE 2: Menentukan Status berdasarkan Tanggal (Pengecekan Otomatis)
  static String calculateStatus(String tanggalService, String currentStatus) {
    if (currentStatus == 'Done') return 'Done'; 

    DateTime today = DateTime.now();
    DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
    
    DateTime? serviceDate = DateTime.tryParse(tanggalService);
    if (serviceDate == null) return currentStatus; 
    
    DateTime serviceDateOnly = DateTime(serviceDate.year, serviceDate.month, serviceDate.day);

    int differenceInDays = serviceDateOnly.difference(todayDateOnly).inDays;

    if (differenceInDays < 0) {
      return 'Overdue'; 
    } else if (differenceInDays == 0) {
      return 'Hari Ini'; 
    } else if (differenceInDays <= 7) {
      return 'Upcoming'; 
    } else {
      return 'Upcoming'; 
    }
  }
}