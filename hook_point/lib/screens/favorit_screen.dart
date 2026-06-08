import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hook_point/models/spot_model.dart';
import 'package:hook_point/models/user_model.dart';
import 'package:hook_point/services/firestore_service.dart';
import 'package:hook_point/services/auth_service.dart';
import 'package:hook_point/widgets/spot_card.dart';
import 'detail_screen.dart';

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Silakan login terlebih dahulu'));
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.streamUser(uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = userSnapshot.data;
        final spotFavorit = user?.spotFavorit ?? [];

        if (spotFavorit.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border,
                    size: 80, color: theme.primaryColor.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada spot favorit',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tandai spot yang kamu suka dengan ♥',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<SpotModel>>(
          future: _firestoreService.getSpotFavorit(spotFavorit),
          builder: (context, spotSnapshot) {
            if (spotSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final spots = spotSnapshot.data ?? [];

            if (spots.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text('Spot favorit tidak ditemukan'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: spots.length,
              itemBuilder: (context, index) {
                return SpotCard(
                  spot: spots[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(spot: spots[index]),
                      ),
                    ).then((_) => setState(() {}));
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
