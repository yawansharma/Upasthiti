import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Saves exported reports (CSV/Excel/PDF) via the OS's native "Save" dialog
/// instead of a hardcoded app-private directory. On Android this uses the
/// Storage Access Framework — the file lands wherever the user picks
/// (normally Downloads), and is always visible in the phone's file manager,
/// never buried in an inaccessible app sandbox. On Windows/macOS/Linux it
/// shows the familiar native save dialog. No storage permissions needed on
/// any platform.
class ExportService {
  /// Prompts the user to choose where to save [bytes] as [fileName].
  /// Returns the saved path, or null if the user cancelled the dialog.
  static Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    return FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
    );
  }

  /// Convenience for text-based exports (CSV).
  static Future<String?> saveText({
    required String content,
    required String fileName,
  }) {
    return saveBytes(
      bytes: Uint8List.fromList(utf8.encode(content)),
      fileName: fileName,
    );
  }
}
