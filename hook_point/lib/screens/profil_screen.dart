import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hook_point/models/spot_model.dart';
import 'package:hook_point/models/user_model.dart';
import 'package:hook_point/services/firestore_service.dart';
import 'package:hook_point/services/auth_service.dart';
import 'package:hook_point/services/location_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _namaSpotController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _ikanController = TextEditingController();

  String _kategori = 'Sungai';
  String _kondisiAir = 'Jernih';
  List<String> _jenisIkan = [];
  File? _gambar;
  String _gambarBase64 = '';
  double? _latitude;
  double? _longitude;
  bool _isLoadingLokasi = false;
  bool _isPosting = false;

  final List<String> _kategoriList = [
    'Sungai', 'Danau', 'Waduk', 'Tambak', 'Empang'
  ];
  final List<String> _kondisiList = ['Jernih', 'Sedang', 'Keruh'];

  @override
  void dispose() {
    _namaSpotController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _ikanController.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70, 
    );

    if (file != null) {
      final bytes = await file.readAsBytes();
      
    
      if (bytes.length > 800 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar terlalu besar! Maksimal 800KB. Pilih gambar yang lebih kecil.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _gambar = File(file.path);
        _gambarBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _ambilFoto() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );

    if (file != null) {
      final bytes = await file.readAsBytes();

      if (bytes.length > 800 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto terlalu besar! Coba lagi dengan resolusi lebih rendah.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _gambar = File(file.path);
        _gambarBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _ambilLokasi() async {
    setState(() => _isLoadingLokasi = true);

    Position? position = await _locationService.getLokasiSekarang();

    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendapatkan lokasi. Aktifkan GPS dan izinkan akses lokasi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Lokasi berhasil: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    setState(() => _isLoadingLokasi = false);
  }

  void _tambahIkan() {
    final ikan = _ikanController.text.trim();
    if (ikan.isEmpty) return;
    if (_jenisIkan.contains(ikan)) {
      _ikanController.clear();
      return;
    }
    setState(() {
      _jenisIkan.add(ikan);
      _ikanController.clear();
    });
  }

  void _hapusIkan(String ikan) {
    setState(() => _jenisIkan.remove(ikan));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ambil lokasi GPS terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isPosting = false);
      return;
    }

    UserModel? user = await _authService.getUserData(uid);

    SpotModel spotBaru = SpotModel(
      id: '',
      userId: uid,
      namaSpot: _namaSpotController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      kategori: _kategori,
      jenisIkan: _jenisIkan,
      kondisiAir: _kondisiAir,
      imageBase64: _gambarBase64,
      imageUrl: '',
      waktuPosting: DateTime.now(),
      jumlahLike: 0,
      namaPoster: user?.nama ?? 'Anonim',
      fotoProfilPoster: user?.fotoProfilBase64 ?? '',
    );

    String? error = await _firestoreService.tambahSpot(spotBaru);

    setState(() => _isPosting = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spot berhasil diposting! 🎣'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _namaSpotController.clear();
        _deskripsiController.clear();
        _lokasiController.clear();
        setState(() {
          _jenisIkan = [];
          _gambar = null;
          _gambarBase64 = '';
          _latitude = null;
          _longitude = null;
          _kategori = 'Sungai';
          _kondisiAir = 'Jernih';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Foto Spot',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showPilihGambar(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  child: _gambar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_gambar!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 48,
                                color: theme.primaryColor.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Tap untuk tambah foto',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ),
                            Text(
                              'Maks. 800KB',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _namaSpotController,
                decoration: const InputDecoration(
                  labelText: 'Nama Spot *',
                  hintText: 'Contoh: Sungai Citarum Hulu',
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama spot wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _kategoriList.map((k) {
                  return DropdownMenuItem(value: k, child: Text(k));
                }).toList(),
                onChanged: (v) => setState(() => _kategori = v!),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _kondisiAir,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Air',
                  prefixIcon: Icon(Icons.water_drop),
                ),
                items: _kondisiList.map((k) {
                  return DropdownMenuItem(value: k, child: Text(k));
                }).toList(),
                onChanged: (v) => setState(() => _kondisiAir = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi *',
                  hintText: 'Ceritakan tentang spot ini...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lokasi *',
                  hintText: 'Contoh: Bandung, Jawa Barat',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Lokasi wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              Text('Koordinat GPS',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_latitude != null && _longitude != null) ...[
                            Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Long: ${_longitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600),
                            ),
                          ] else
                            Text(
                              'Belum ada koordinat',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoadingLokasi ? null : _ambilLokasi,
                      icon: _isLoadingLokasi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.gps_fixed, size: 18),
                      label: Text(
                          _isLoadingLokasi ? 'Mengambil...' : 'Ambil GPS'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text('Jenis Ikan',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ikanController,
                      decoration: const InputDecoration(
                        hintText: 'Tambah jenis ikan...',
                        prefixIcon: Icon(Icons.set_meal),
                        isDense: true,
                      ),
                      onFieldSubmitted: (_) => _tambahIkan(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _tambahIkan,
                    icon: Icon(Icons.add_circle, color: theme.primaryColor),
                  ),
                ],
              ),
              if (_jenisIkan.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _jenisIkan.map((ikan) {
                    return Chip(
                      label: Text('🐟 $ikan'),
                      onDeleted: () => _hapusIkan(ikan),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPosting ? null : _submit,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isPosting ? 'Memposting...' : 'Post Spot Mancing',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showPilihGambar() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pilih dari Galeri'),
            onTap: () {
              Navigator.pop(context);
              _pilihGambar();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Ambil Foto'),
            onTap: () {
              Navigator.pop(context);
              _ambilFoto();
            },
          ),
        ],
      ),
    );
  }
}
