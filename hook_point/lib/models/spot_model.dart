class SpotModel {
  final String id;
  final String userId;
  final String namaSpot;
  final String deskripsi;
  final String lokasi; 
  final double latitude;
  final double longitude;
  final String kategori; 
  final List<String> jenisIkan;
  final String kondisiAir; 
  final String imageBase64; 
  final String imageUrl; 
  final DateTime waktuPosting;
  final int jumlahLike;
  final String namaPoster;
  final String fotoProfilPoster;

  SpotModel({
    required this.id,
    required this.userId,
    required this.namaSpot,
    required this.deskripsi,
    required this.lokasi,
    required this.latitude,
    required this.longitude,
    required this.kategori,
    required this.jenisIkan,
    required this.kondisiAir,
    this.imageBase64 = '',
    this.imageUrl = '',
    required this.waktuPosting,
    this.jumlahLike = 0,
    this.namaPoster = '',
    this.fotoProfilPoster = '',
  });

  factory SpotModel.fromMap(Map<String, dynamic> map, String id) {
    return SpotModel(
      id: id,
      userId: map['userId'] ?? '',
      namaSpot: map['namaSpot'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      lokasi: map['lokasi'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      kategori: map['kategori'] ?? 'Lainnya',
      jenisIkan: List<String>.from(map['jenisIkan'] ?? []),
      kondisiAir: map['kondisiAir'] ?? 'Tidak diketahui',
      imageBase64: map['imageBase64'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      waktuPosting: map['waktuPosting'] != null
          ? (map['waktuPosting'] as dynamic).toDate()
          : DateTime.now(),
      jumlahLike: map['jumlahLike'] ?? 0,
      namaPoster: map['namaPoster'] ?? '',
      fotoProfilPoster: map['fotoProfilPoster'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'namaSpot': namaSpot,
      'deskripsi': deskripsi,
      'lokasi': lokasi,
      'latitude': latitude,
      'longitude': longitude,
      'kategori': kategori,
      'jenisIkan': jenisIkan,
      'kondisiAir': kondisiAir,
      'imageBase64': imageBase64,
      'imageUrl': imageUrl,
      'waktuPosting': waktuPosting,
      'jumlahLike': jumlahLike,
      'namaPoster': namaPoster,
      'fotoProfilPoster': fotoProfilPoster,
    };
  }

  SpotModel copyWith({
    String? id,
    String? userId,
    String? namaSpot,
    String? deskripsi,
    String? lokasi,
    double? latitude,
    double? longitude,
    String? kategori,
    List<String>? jenisIkan,
    String? kondisiAir,
    String? imageBase64,
    String? imageUrl,
    DateTime? waktuPosting,
    int? jumlahLike,
    String? namaPoster,
    String? fotoProfilPoster,
  }) {
    return SpotModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      namaSpot: namaSpot ?? this.namaSpot,
      deskripsi: deskripsi ?? this.deskripsi,
      lokasi: lokasi ?? this.lokasi,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      kategori: kategori ?? this.kategori,
      jenisIkan: jenisIkan ?? this.jenisIkan,
      kondisiAir: kondisiAir ?? this.kondisiAir,
      imageBase64: imageBase64 ?? this.imageBase64,
      imageUrl: imageUrl ?? this.imageUrl,
      waktuPosting: waktuPosting ?? this.waktuPosting,
      jumlahLike: jumlahLike ?? this.jumlahLike,
      namaPoster: namaPoster ?? this.namaPoster,
      fotoProfilPoster: fotoProfilPoster ?? this.fotoProfilPoster,
    );
  }
}
