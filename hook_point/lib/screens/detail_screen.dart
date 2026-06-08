import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hook_point/models/spot_model.dart';
import 'package:hook_point/models/komen_model.dart';
import 'package:hook_point/models/user_model.dart';
import 'package:hook_point/services/firestore_service.dart';
import 'package:hook_point/services/auth_service.dart';
import 'package:hook_point/widgets/komentar_item.dart';

class DetailScreen extends StatefulWidget {
  final SpotModel spot;

  const DetailScreen({super.key, required this.spot});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _komentarController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _replyToId;
  String? _replyToName;
  bool _isSendingKomentar = false;
  UserModel? _currentUser;
  bool _isFavorit = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _komentarController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final user = await _authService.getUserData(uid);
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isFavorit = user?.spotFavorit.contains(widget.spot.id) ?? false;
      });
    }
  }

  Future<void> _toggleFavorit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestoreService.toggleFavorit(uid, widget.spot.id);
    setState(() => _isFavorit = !_isFavorit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorit ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _bukaGoogleMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${widget.spot.latitude},${widget.spot.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
        );
      }
    }
  }

  Future<void> _kirimKomentar() async {
    if (_komentarController.text.trim().isEmpty) return;
    if (_currentUser == null) return;

    setState(() => _isSendingKomentar = true);

    KomentarModel komentar = KomentarModel(
      id: '',
      spotId: widget.spot.id,
      userId: _currentUser!.id,
      namaUser: _currentUser!.nama,
      fotoProfilUser: _currentUser!.fotoProfilBase64,
      isiKomentar: _komentarController.text.trim(),
      waktu: DateTime.now(),
      parentId: _replyToId,
    );

    String? error = await _firestoreService.tambahKomentar(komentar);

    if (mounted) {
      setState(() {
        _isSendingKomentar = false;
        _replyToId = null;
        _replyToName = null;
      });
      _komentarController.clear();
      _focusNode.unfocus();

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusSpot() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Spot'),
        content: const Text('Yakin ingin menghapus spot ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.hapusSpot(
          widget.spot.id, widget.spot.userId);
      if (mounted) Navigator.pop(context);
    }
  }

  void _setBalas(String komentarId, String namaUser) {
    setState(() {
      _replyToId = komentarId;
      _replyToName = namaUser;
    });
    _focusNode.requestFocus();
  }

  void _batalBalas() {
    setState(() {
      _replyToId = null;
      _replyToName = null;
    });
    _komentarController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final spot = widget.spot;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

  
    final isAdmin = _currentUser?.isAdmin ?? false;
    final isPemilik = currentUid == spot.userId;
    final bisaHapusSpot = isAdmin || isPemilik;

    return Scaffold(
      appBar: AppBar(
        title: Text(spot.namaSpot, overflow: TextOverflow.ellipsis),
        actions: [
  
          IconButton(
            icon: Icon(
              _isFavorit ? Icons.favorite : Icons.favorite_border,
              color: _isFavorit ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorit,
            tooltip: _isFavorit ? 'Hapus Favorit' : 'Tambah Favorit',
          ),
        
          if (bisaHapusSpot)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _hapusSpot,
              tooltip: 'Hapus Spot',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGambar(spot, theme),

                
                  if (isAdmin)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      color: Colors.red.withOpacity(0.1),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              size: 14, color: Colors.red),
                          SizedBox(width: 6),
                          Text(
                            'Mode Admin — kamu dapat menghapus konten ini',
                            style:
                                TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                spot.namaSpot,
                                style:
                                    theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                spot.kategori,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        GestureDetector(
                          onTap: _bukaGoogleMaps,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      theme.primaryColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: theme.primaryColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        spot.lokasi,
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Lat: ${spot.latitude.toStringAsFixed(4)}, Long: ${spot.longitude.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.open_in_new,
                                    color: theme.primaryColor, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _infoBadge(
                              context,
                              icon: Icons.water_drop,
                              label: spot.kondisiAir,
                              color: spot.kondisiAir == 'Jernih'
                                  ? Colors.green
                                  : spot.kondisiAir == 'Sedang'
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            _infoBadge(
                              context,
                              icon: Icons.access_time,
                              label: timeago.format(spot.waktuPosting,
                                  locale: 'id'),
                              color: Colors.blueGrey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (spot.jenisIkan.isNotEmpty) ...[
                          Text(
                            'Jenis Ikan',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: spot.jenisIkan.map((ikan) {
                              return Chip(
                                label: Text('🐟 $ikan'),
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Text(
                          'Deskripsi',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          spot.deskripsi,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  theme.primaryColor.withOpacity(0.2),
                              child: Text(
                                spot.namaPoster.isNotEmpty
                                    ? spot.namaPoster[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Diposting oleh ${spot.namaPoster}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  timeago.format(spot.waktuPosting,
                                      locale: 'id'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        Text(
                          'Komentar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        StreamBuilder<List<KomentarModel>>(
                          stream:
                              _firestoreService.streamKomentar(spot.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final semuaKomentar = snapshot.data ?? [];
                            final komentarUtama = semuaKomentar
                                .where((k) => k.parentId == null)
                                .toList();
                            final balasanMap =
                                <String, List<KomentarModel>>{};
                            for (var k in semuaKomentar) {
                              if (k.parentId != null) {
                                balasanMap
                                    .putIfAbsent(k.parentId!, () => [])
                                    .add(k);
                              }
                            }

                            if (komentarUtama.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20),
                                  child: Text(
                                    'Belum ada komentar. Jadilah yang pertama!',
                                    style:
                                        TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: komentarUtama.map((komentar) {
                                final balasan =
                                    balasanMap[komentar.id] ?? [];
                                return Column(
                                  children: [
                                    KomentarItem(
                                      komentar: komentar,
                                      onBalas: () => _setBalas(
                                          komentar.id, komentar.namaUser),
                                
                                      bisaHapus: isAdmin ||
                                          currentUid == komentar.userId,
                                      onHapus: () => _firestoreService
                                          .hapusKomentar(komentar.id),
                                    ),
                                    ...balasan.map((balas) => KomentarItem(
                                          komentar: balas,
                                          isBalasan: true,
                                          onBalas: () => _setBalas(
                                              komentar.id, balas.namaUser),
                                          bisaHapus: isAdmin ||
                                              currentUid == balas.userId,
                                          onHapus: () => _firestoreService
                                              .hapusKomentar(balas.id),
                                        )),
                                  ],
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyToName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Membalas $_replyToName',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _batalBalas,
                          child: Icon(Icons.close,
                              size: 16, color: theme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _komentarController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: _replyToId != null
                              ? 'Tulis balasan...'
                              : 'Tulis komentar...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          isDense: true,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _kirimKomentar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed:
                          _isSendingKomentar ? null : _kirimKomentar,
                      icon: _isSendingKomentar
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Icon(Icons.send, color: theme.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGambar(SpotModel spot, ThemeData theme) {
    if (spot.imageBase64.isNotEmpty) {
      try {
        return SizedBox(
          width: double.infinity,
          height: 250,
          child: Image.memory(
            base64Decode(spot.imageBase64),
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    if (spot.imageUrl.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 250,
        child: Image.network(spot.imageUrl, fit: BoxFit.cover),
      );
    }
    return Container(
      width: double.infinity,
      height: 200,
      color: theme.primaryColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phishing,
              size: 64, color: theme.primaryColor.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text('Tidak ada foto',
              style: TextStyle(
                  color: theme.primaryColor.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _infoBadge(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}