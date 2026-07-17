class ServiceModel {
  final int? id;
  final int motorId;
  final String jenisService;
  final String tanggalService;
  final int kilometerService;
  final String catatan;
  final String status;

  ServiceModel({
    this.id,
    required this.motorId,
    required this.jenisService,
    required this.tanggalService,
    required this.kilometerService,
    this.catatan = '',
    required this.status,
  });

  // PERBAIKAN: Menggunakan <String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'motorId': motorId,
      'jenisService': jenisService,
      'tanggalService': tanggalService,
      'kilometerService': kilometerService,
      'catatan': catatan,
      'status': status,
    };
  }

  // PERBAIKAN: Menggunakan <String, dynamic>
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'],
      motorId: map['motorId'],
      jenisService: map['jenisService'],
      tanggalService: map['tanggalService'],
      kilometerService: map['kilometerService'],
      catatan: map['catatan'] ?? '',
      status: map['status'],
    );
  }
}