class UserModel {
  final String id;
  final String nama;
  final String email;
  final String bio;
  final String fotoProfilBase64;
  final List<String> spotFavorit;
  final int jumlahPosting;
  final String role; 

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    this.bio = '',
    this.fotoProfilBase64 = '',
    this.spotFavorit = const [],
    this.jumlahPosting = 0,
    this.role = 'user', 
  });

  bool get isAdmin => role == 'admin'; 

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      fotoProfilBase64: map['fotoProfilBase64'] ?? '',
      spotFavorit: List<String>.from(map['spotFavorit'] ?? []),
      jumlahPosting: map['jumlahPosting'] ?? 0,
      role: map['role'] ?? 'user', 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'bio': bio,
      'fotoProfilBase64': fotoProfilBase64,
      'spotFavorit': spotFavorit,
      'jumlahPosting': jumlahPosting,
      'role': role, 
    };
  }

  UserModel copyWith({
    String? id,
    String? nama,
    String? email,
    String? bio,
    String? fotoProfilBase64,
    List<String>? spotFavorit,
    int? jumlahPosting,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      fotoProfilBase64: fotoProfilBase64 ?? this.fotoProfilBase64,
      spotFavorit: spotFavorit ?? this.spotFavorit,
      jumlahPosting: jumlahPosting ?? this.jumlahPosting,
      role: role ?? this.role,
    );
  }
}