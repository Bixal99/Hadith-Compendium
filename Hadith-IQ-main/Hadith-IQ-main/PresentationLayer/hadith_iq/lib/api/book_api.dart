import 'package:hadith_iq/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookService {
  final String _baseUrl = "${AppConfig.apiBaseUrl}/book";
  // Method to fetch projects from backend

  Future<List<String>> getAllBooks() async {
    final response = await http.get(Uri.parse('$_baseUrl/getAllBooks'));

    if (response.statusCode == 200) {
      // Decode JSON response
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));

      // Extract the list of books from the "books" key
      if (data.containsKey('books') && data['books'] is List) {
        return List<String>.from(data['books']);
      } else {
        throw Exception('Unexpected response format: $data');
      }
    } else {
      throw Exception('Failed to load books: ${response.reasonPhrase}');
    }
  }

  Future<List<String>> getAllBooksOfProject(String projectName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/getAllBooksOfProjects?projectName=$projectName'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      // Decode JSON response
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));

      // Extract the list of books from the "books" key
      if (data.containsKey('books') && data['books'] is List) {
        return List<String>.from(data['books']);
      } else {
        throw Exception('Unexpected response format: $data');
      }
    } else {
      throw Exception('Failed to load books: ${response.reasonPhrase}');
    }
  }
}
