import 'package:file_picker/file_picker.dart';

class ImportFile {
  // Function to handle CSV file selection
  static Future<String?> selectCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      } else {
        return null; // No file selected
      }
    } catch (e) {
      return null;
    }
  }

  static Future<String?> selectHtmlFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['htm', 'html'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      } else {
        return null; // No file selected
      }
    } catch (e) {
      return null;
    }
  }
}