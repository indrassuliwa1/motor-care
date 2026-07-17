class Motor {
  final int? id;
  final String merk;
  final String namaMotor;
  final String tipeMotor;
  final int tahun;
  final String nomorPolisi;
  final int kilometerSaatIni;
  final String tanggalPembelian;
  final String? fotoMotor;

  Motor({
    this.id,
    required this.merk,
    required this.namaMotor,
    required this.tipeMotor,
    required this.tahun,
    required this.nomorPolisi,
    required this.kilometerSaatIni,
    required this.tanggalPembelian,
    this.fotoMotor,
  });

  // PERBAIKANNYA ADA DI SINI: Tambahkan <String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merk': merk,
      'namaMotor': namaMotor,
      'tipeMotor': tipeMotor,
      'tahun': tahun,
      'nomorPolisi': nomorPolisi,
      'kilometerSaatIni': kilometerSaatIni,
      'tanggalPembelian': tanggalPembelian,
      'fotoMotor': fotoMotor,
    };
  }

  // PERBAIKANNYA ADA DI SINI JUGA
  factory Motor.fromMap(Map<String, dynamic> map) {
    return Motor(
      id: map['id'],
      merk: map['merk'],
      namaMotor: map['namaMotor'],
      tipeMotor: map['tipeMotor'],
      tahun: map['tahun'],
      nomorPolisi: map['nomorPolisi'],
      kilometerSaatIni: map['kilometerSaatIni'],
      tanggalPembelian: map['tanggalPembelian'],
      fotoMotor: map['fotoMotor'],
    );
  }
}