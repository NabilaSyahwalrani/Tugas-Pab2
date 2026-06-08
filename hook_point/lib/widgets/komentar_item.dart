import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hook_point/models/komen_model.dart';

class KomentarItem extends StatelessWidget {
  final KomentarModel komentar;
  final bool isBalasan;
  final VoidCallback onBalas;
  final VoidCallback? onHapus;
  final bool bisaHapus;

  const KomentarItem({
    super.key,
    required this.komentar,
    this.isBalasan = false,
    required this.onBalas,
    this.onHapus,
    this.bisaHapus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        left: isBalasan ? 40 : 0,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isBalasan ? 14 : 18,
            backgroundColor: theme.primaryColor.withOpacity(0.2),
            child: Text(
              komentar.namaUser.isNotEmpty
                  ? komentar.namaUser[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: isBalasan ? 10 : 13,
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        komentar.namaUser,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        komentar.isiKomentar,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        timeago.format(komentar.waktu, locale: 'id'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!isBalasan)
                        GestureDetector(
                          onTap: onBalas,
                          child: Text(
                            'Balas',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (bisaHapus && onHapus != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onHapus,
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
