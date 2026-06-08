import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hook_point/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> daftar({
    required String email,
    required String password,
    required String nama,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return 'Gagal membuat akun';

      await user.updateDisplayName(nama);

  
      UserModel userBaru = UserModel(
        id: user.uid,
        nama: nama,
        email: email,
        bio: 'Pemancing dari Indonesia 🎣',
        spotFavorit: [],
        jumlahPosting: 0,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userBaru.toMap());

      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email sudah digunakan';
      } else if (e.code == 'weak-password') {
        return 'Password terlalu lemah (minimal 6 karakter)';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid';
      }
      return e.message ?? 'Terjadi kesalahan';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Akun tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        return 'Password salah';
      } else if (e.code == 'invalid-email') {
        return 'Format email tidak valid';
      } else if (e.code == 'user-disabled') {
        return 'Akun telah dinonaktifkan';
      } else if (e.code == 'invalid-credential') {
        return 'Email atau password salah';
      }
      return e.message ?? 'Terjadi kesalahan';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> updateProfil({
    required String userId,
    required String nama,
    required String bio,
    String? fotoProfilBase64,
  }) async {
    try {
      Map<String, dynamic> data = {
        'nama': nama,
        'bio': bio,
      };

      if (fotoProfilBase64 != null) {
        data['fotoProfilBase64'] = fotoProfilBase64;
      }

      await _firestore.collection('users').doc(userId).update(data);
      await _auth.currentUser?.updateDisplayName(nama);
      return null;
    } catch (e) {
      return 'Gagal update profil: $e';
    }
  }
}
