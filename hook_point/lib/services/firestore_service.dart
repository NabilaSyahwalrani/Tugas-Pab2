import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hook_point/models/spot_model.dart';
import 'package:hook_point/models/komen_model.dart';
import 'package:hook_point/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _ensureUserExists(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final userBaru = UserModel(
        id: userId,
        nama: firebaseUser?.displayName ?? firebaseUser?.email?.split('@')[0] ?? 'Pengguna',
        email: firebaseUser?.email ?? '',
        bio: 'Pemancing dari Indonesia 🎣',
        spotFavorit: [],
        jumlahPosting: 0,
      );
      await _firestore.collection('users').doc(userId).set(userBaru.toMap());
    }
  }

  Future<String?> tambahSpot(SpotModel spot) async {
    try {
      await _firestore.collection('spots').add(spot.toMap());

      await _firestore.collection('users').doc(spot.userId).update({
        'jumlahPosting': FieldValue.increment(1),
      });

      return null;
    } catch (e) {
      return 'Gagal menambah spot: $e';
    }
  }

  Stream<List<SpotModel>> streamSemuaSpot({String? kategori}) {
    Query query = _firestore
        .collection('spots')
        .orderBy('waktuPosting', descending: true);

    if (kategori != null && kategori != 'Semua') {
      query = query.where('kategori', isEqualTo: kategori);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<List<SpotModel>> streamSpotByUser(String userId) {
    return _firestore
        .collection('spots')
        .where('userId', isEqualTo: userId)
        .orderBy('waktuPosting', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<SpotModel?> getSpotById(String spotId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('spots').doc(spotId).get();
      if (doc.exists) {
        return SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> hapusSpot(String spotId, String userId) async {
    try {
      await _firestore.collection('spots').doc(spotId).delete();

      QuerySnapshot komentar = await _firestore
          .collection('komentar')
          .where('spotId', isEqualTo: spotId)
          .get();

      for (var doc in komentar.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('users').doc(userId).update({
        'jumlahPosting': FieldValue.increment(-1),
      });

      return null;
    } catch (e) {
      return 'Gagal hapus spot: $e';
    }
  }

  Future<void> toggleFavorit(String userId, String spotId) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);

    DocumentSnapshot userDoc = await userRef.get();
    List<String> favorit =
        List<String>.from((userDoc.data() as Map)['spotFavorit'] ?? []);

    if (favorit.contains(spotId)) {
      await userRef.update({
        'spotFavorit': FieldValue.arrayRemove([spotId]),
      });
    } else {
      await userRef.update({
        'spotFavorit': FieldValue.arrayUnion([spotId]),
      });
    }
  }

  Future<List<SpotModel>> getSpotFavorit(List<String> spotIds) async {
    if (spotIds.isEmpty) return [];

    try {
      List<SpotModel> result = [];

      List<List<String>> chunks = [];
      for (int i = 0; i < spotIds.length; i += 10) {
        chunks.add(spotIds.sublist(
            i, i + 10 > spotIds.length ? spotIds.length : i + 10));
      }

      for (var chunk in chunks) {
        QuerySnapshot snapshot = await _firestore
            .collection('spots')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in snapshot.docs) {
          result.add(
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  Future<String?> tambahKomentar(KomentarModel komentar) async {
    try {
      await _firestore.collection('komentar').add(komentar.toMap());
      return null;
    } catch (e) {
      return 'Gagal tambah komentar: $e';
    }
  }

  Stream<List<KomentarModel>> streamKomentar(String spotId) {
    return _firestore
        .collection('komentar')
        .where('spotId', isEqualTo: spotId)
        .orderBy('waktu', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return KomentarModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> hapusKomentar(String komentarId) async {
    await _firestore.collection('komentar').doc(komentarId).delete();
  }

  Stream<UserModel?> streamUser(String userId) async* {
    await _ensureUserExists(userId);
    yield* _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }
}