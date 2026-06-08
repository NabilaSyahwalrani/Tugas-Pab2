class KomentarModel {
  final String id;
  final String spotId;
  final String userId;
  final String namaUser;
  final String fotoProfilUser;
  final String isiKomentar;
  final DateTime waktu;
  final String? parentId;

  KomentarModel({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.namaUser,
    required this.fotoProfilUser,
    required this.isiKomentar,
    required this.waktu,
    this.parentId,
  });

  factory KomentarModel.fromMap(Map<String, dynamic> map, String id) {
    return KomentarModel(
      id: id,
      spotId: map['spotId'] ?? '',
      userId: map['userId'] ?? '',
      namaUser: map['namaUser'] ?? '',
      fotoProfilUser: map['fotoProfilUser'] ?? '',
      isiKomentar: map['isiKomentar'] ?? '',
      waktu: map['waktu'] != null
          ? (map['waktu'] as dynamic).toDate()
          : DateTime.now(),
      parentId: map['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'spotId': spotId,
      'userId': userId,
      'namaUser': namaUser,
      'fotoProfilUser': fotoProfilUser,
      'isiKomentar': isiKomentar,
      'waktu': waktu,
      'parentId': parentId,
    };
  }
}
