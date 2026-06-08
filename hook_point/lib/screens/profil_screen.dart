import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hook_point/models/user_model.dart';
import 'package:hook_point/models/spot_model.dart';
import 'package:hook_point/services/auth_service.dart';
import 'package:hook_point/services/firestore_service.dart';
import 'package:hook_point/services/theme_provider.dart';
import 'package:hook_point/widgets/spot_card.dart';
import 'detail_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();

  final _namaController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String? _newFotoBase64;
  Uint8List? _newFotoBytes; // ✅ Ganti File dengan Uint8List

  @override
  void dispose() {
    _namaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pilihFotoProfil() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );

    if (file != null) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 300 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Foto profil terlalu besar! Maks 300KB.'),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }
      setState(() {
        _newFotoBytes = bytes; // ✅ Simpan sebagai bytes
        _newFotoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _simpanProfil(String userId) async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? error = await _authService.updateProfil(
      userId: userId,
      nama: _namaController.text.trim(),
      bio: _bioController.text.trim(),
      fotoProfilBase64: _newFotoBase64,
    );

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Silakan login'));
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.streamUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('Data pengguna tidak ditemukan'));
        }

        if (_isEditing && _namaController.text.isEmpty) {
          _namaController.text = user.nama;
          _bioController.text = user.bio;
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _pilihFotoProfil : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            // ✅ Pakai MemoryImage untuk semua platform
                            backgroundImage: _newFotoBytes != null
                                ? MemoryImage(_newFotoBytes!) as ImageProvider
                                : (user.fotoProfilBase64.isNotEmpty
                                    ? MemoryImage(
                                            base64Decode(
                                                user.fotoProfilBase64))
                                        as ImageProvider
                                    : null),
                            child: (_newFotoBytes == null &&
                                    user.fotoProfilBase64.isEmpty)
                                ? Text(
                                    user.nama.isNotEmpty
                                        ? user.nama[0].toUpperCase()
                                        : 'P',
                                    style: const TextStyle(
                                        fontSize: 36,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.camera_alt,
                                    size: 16, color: theme.primaryColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!_isEditing) ...[
                      Text(
                        user.nama,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.bio,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statItem('Posting', user.jumlahPosting.toString()),
                          const SizedBox(width: 32),
                          _statItem(
                              'Favorit', user.spotFavorit.length.toString()),
                        ],
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _namaController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                          filled: false,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isEditing)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                _namaController.text = user.nama;
                                _bioController.text = user.bio;
                              });
                            },
                            icon: const Icon(Icons.edit,
                                color: Colors.white, size: 16),
                            label: const Text('Edit Profil',
                                style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white)),
                          )
                        else ...[
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _newFotoBase64 = null;
                                _newFotoBytes = null; // ✅ Reset bytes
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white)),
                            child: const Text('Batal',
                                style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed:
                                _isSaving ? null : () => _simpanProfil(uid),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.primaryColor),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Simpan'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              _sectionTitle(context, 'Pengaturan'),
              Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: theme.primaryColor,
                      ),
                      title: const Text('Mode Gelap'),
                      subtitle: Text(
                          themeProvider.isDarkMode ? 'Aktif' : 'Nonaktif'),
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: theme.primaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              _sectionTitle(context, 'Posting Saya'),
              StreamBuilder<List<SpotModel>>(
                stream: _firestoreService.streamSpotByUser(uid),
                builder: (context, spotSnapshot) {
                  final spots = spotSnapshot.data ?? [];

                  if (spots.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Belum ada posting',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: spots.map((spot) {
                      return SpotCard(
                        spot: spot,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(spot: spot),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Keluar',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}