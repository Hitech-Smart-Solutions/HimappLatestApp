import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePopup extends StatelessWidget {
  const UpdatePopup({super.key});

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.mycompany.himappnew';

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(playStoreUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🔒 Back button disable
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: const [
            Icon(
              Icons.system_update_alt_rounded,
              color: Colors.blue,
              size: 28,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi-Mapp has a newer version with important improvements.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 10),
            Text(
              'To continue using the app smoothly and securely, please update to the latest version.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text(
                'Update from Play Store',
                style: TextStyle(fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _openPlayStore,
            ),
          ),
        ],
      ),
    );
  }
}
