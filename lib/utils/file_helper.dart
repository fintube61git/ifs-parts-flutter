import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Helper class for file operations and directory management.
class FileHelper {
  /// Get the default export directory for the current platform.
  /// On macOS, uses Documents instead of Downloads due to restrictions.
  /// On Windows/Linux, tries Downloads first, then falls back to Documents.
  static Future<Directory> getDefaultExportDirectory() async {
    try {
      // On macOS, Downloads is often restricted — use Documents instead
      if (Platform.isMacOS) {
        final docs = await getApplicationDocumentsDirectory();
        if (docs.existsSync()) return docs;
      }
      // On Windows/Linux, try Downloads first
      final downloads = await getDownloadsDirectory();
      if (downloads != null && downloads.existsSync()) return downloads;
    } catch (_) {
      // Silently catch and continue to fallback
    }
    
    // Final fallback for all platforms
    try {
      final docs = await getApplicationDocumentsDirectory();
      return docs;
    } catch (_) {
      return Directory.current;
    }
  }

  /// Generate a timestamp string for filenames.
  /// Format: yyyyMMdd_HHmmss
  static String generateTimestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, "0");
    return "${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}";
  }

  /// Generate a full export path with the given filename prefix and extension.
  static Future<String> generateExportPath(String prefix, String extension) async {
    final dir = await getDefaultExportDirectory();
    final timestamp = generateTimestamp();
    return "${dir.path}${Platform.pathSeparator}${prefix}_$timestamp.$extension";
  }

  /// Reveal a file in the system file explorer.
  /// On macOS, opens Finder and selects the file.
  /// On Windows, opens Explorer and selects the file.
  /// On other platforms, opens the containing directory.
  static Future<void> revealInExplorer(String filePath, Directory fallbackDir) async {
    try {
      if (Platform.isMacOS) {
        // Try to reveal the specific file
        try {
          await Process.run('open', ['-R', filePath]);
        } catch (_) {
          // Fallback: open the folder
          await Process.run('open', [fallbackDir.path]);
        }
      } else if (Platform.isWindows) {
        // Try to reveal the specific file
        try {
          await Process.run('explorer', ['/select,', filePath]);
        } catch (_) {
          // Fallback: open the folder
          await Process.run('explorer', [fallbackDir.path]);
        }
      } else {
        // For Linux and other platforms, just open the directory
        await Process.run('xdg-open', [fallbackDir.path]);
      }
    } catch (e) {
      // Silently fail if we can't open the file explorer
    }
  }
}
