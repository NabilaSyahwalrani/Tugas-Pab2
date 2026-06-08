import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hook_point/models/spot_model.dart';

class SpotCard extends StatelessWidget {
  final SpotModel spot;
  final VoidCallback onTap;

  const SpotCard({
    super.key,
    required this.spot,
    required this.onTap,
  });

  Color _warnaKondisiAir(String kondisi) {
    if (kondisi == 'Jernih') return Colors.green;
    if (kondisi == 'Sedang') return Colors.orange;
    return Colors.red;
  }
  IconData _iconKategori(String kategori) {
    switch (kategori) {
      case 'Sungai':
        return Icons.water;
      case 'Danau':
        return Icons.waves;
      case 'Waduk':
        return Icons.water_damage;
      case 'Tambak':
        return Icons.set_meal;
      case 'Empang':
        return Icons.water_drop;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Widget gambar;
    if (spot.imageBase64.isNotEmpty) {
      try {
        gambar = Image.memory(
          base64Decode(spot.imageBase64),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
        );
      } catch (_) {
        gambar = _placeholderGambar(context);
      }
    } else if (spot.imageUrl.isNotEmpty) {
      gambar = Image.network(
        spot.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (_, __, ___) => _placeholderGambar(context),
      );
    } else {
      gambar = _placeholderGambar(context);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(height: 180, width: double.infinity, child: gambar),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconKategori(spot.kategori),
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          spot.kategori,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _warnaKondisiAir(spot.kondisiAir),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      spot.kondisiAir,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.namaSpot,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.lokasi,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    spot.deskripsi,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  if (spot.jenisIkan.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: spot.jenisIkan.take(3).map((ikan) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A3A5C)
                                : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '🐟 $ikan',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.primaryColor),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.primaryColor.withOpacity(0.2),
                        child: spot.fotoProfilPoster.isNotEmpty
                            ? null
                            : Text(
                                spot.namaPoster.isNotEmpty
                                    ? spot.namaPoster[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          spot.namaPoster,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeago.format(spot.waktuPosting, locale: 'id'),
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderGambar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      width: double.infinity,
      color: theme.primaryColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phishing, size: 48, color: theme.primaryColor.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            'Tidak ada foto',
            style: TextStyle(color: theme.primaryColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
