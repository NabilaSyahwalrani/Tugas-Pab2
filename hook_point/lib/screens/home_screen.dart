import 'package:flutter/material.dart';
import 'package:hook_point/models/spot_model.dart';
import 'package:hook_point/services/firestore_service.dart';
import 'package:hook_point/widgets/spot_card.dart';
import 'package:hook_point/screens/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterKategori = 'Semua';

  final List<String> _kategoriList = [
    'Semua',
    'Sungai',
    'Danau',
    'Waduk',
    'Tambak',
    'Empang',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 48,
            color: theme.scaffoldBackgroundColor,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _kategoriList.length,
              itemBuilder: (context, index) {
                final kategori = _kategoriList[index];
                final isSelected = _filterKategori == kategori;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(kategori),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _filterKategori = kategori);
                    },
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<SpotModel>>(
              stream: _firestoreService.streamSemuaSpot(
                kategori: _filterKategori,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('Terjadi kesalahan: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final spots = snapshot.data ?? [];

                if (spots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phishing,
                            size: 80,
                            color: theme.primaryColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          _filterKategori == 'Semua'
                              ? 'Belum ada spot mancing'
                              : 'Belum ada spot $_filterKategori',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jadilah yang pertama berbagi!',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount: spots.length,
                    itemBuilder: (context, index) {
                      return SpotCard(
                        spot: spots[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailScreen(spot: spots[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
