import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Provides unified export functionality via native Share menus and Save Dialogs.
class ExportService {
  /// Original saveBytes method (internal use / fallback)
  static Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    return FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
    );
  }

  /// Original saveText method (internal use / fallback)
  static Future<String?> saveText({
    required String content,
    required String fileName,
  }) {
    return saveBytes(
      bytes: Uint8List.fromList(utf8.encode(content)),
      fileName: fileName,
    );
  }

  /// Displays a BottomSheet asking the user how they want to handle the exported file.
  static Future<void> showExportOptions(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Export Options",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: Colors.blue),
                  title: const Text("Share File"),
                  subtitle: const Text("Send via WhatsApp, Email, iCloud, etc."),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final tempDir = await getTemporaryDirectory();
                      final file = File('${tempDir.path}/$fileName');
                      await file.writeAsBytes(bytes);
                      await Share.shareXFiles(
                        [XFile(file.path, mimeType: mimeType)],
                        text: "Exported report: $fileName",
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Share failed: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.green),
                  title: const Text("Save to Downloads"),
                  subtitle: const Text("Save a copy directly to your device"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final path = await FilePicker.platform.saveFile(
                        fileName: fileName,
                        bytes: bytes,
                      );
                      if (path != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('File saved successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Save failed: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
