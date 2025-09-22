import 'dart:convert';
import 'package:hadith_iq/api/network_helper.dart';
import 'package:hadith_iq/config/app_config.dart';
import 'package:http/http.dart' as http;

class HadithService {
  final String _baseUrl = "${AppConfig.apiBaseUrl}/hadith";
  Future<dynamic> importHadithCSV(String filePath) async {
    try {
      if (!isServerOnline()) {
        return {
          'status': 'error',
          'message': 'Server is offline.',
        };
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/importHadithFileCSV'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'filePath': filePath,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(utf8.decode(response.bodyBytes));
        return {
          'status': responseBody['success'],
          'message': responseBody['message'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Exception occurred: $e',
      };
    }
  }

  Future<dynamic> importBookInProject(
      String projectName, List<String> bookNames) async {
    try {
      if (!isServerOnline()) {
        return {
          'status': 'error',
          'message': 'Server is offline.',
        };
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/importBook'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'projectName': projectName,
          'bookNames': bookNames,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(utf8.decode(response.bodyBytes));
        return {
          'status': responseBody['success'],
          'message': responseBody['message'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Function to fetch semantic search results
  Future<List<String>> fetchSemanticSearchResults(
      String hadith, String projectName, double threshold) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/semanticSearch'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'hadith': hadith,
        'projectName': projectName,
        'threshold': threshold,
      }),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);

      if (jsonResponse.containsKey('results') &&
          jsonResponse['results'] is List) {
        final List results = jsonResponse['results'];
        return results.map((result) => result.toString()).toList();
      } else {
        throw Exception(
            'Invalid response format: results key not found or invalid');
      }
    } else {
      throw Exception(
          'Failed to fetch search results. Status code: ${response.statusCode}');
    }
  }

  // API function to fetch expanded search results
  Future<List<String>> fetchExpandSearchResults(
      List<String> hadithList, String projectName, double threshold) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/expandSearch'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'hadithTO': hadithList,
        'projectName': projectName,
        'threshold': threshold,
      }),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);

      if (jsonResponse.containsKey('results') &&
          jsonResponse['results'] is List) {
        final List results = jsonResponse['results'];
        return results.map((result) => result.toString()).toList();
      } else {
        throw Exception(
            'Invalid response format: results key not found or invalid');
      }
    } else {
      throw Exception(
          'Failed to fetch search results. Status code: ${response.statusCode}');
    }
  }

  // API function to fetch expanded search results
  Future<List<String>> searchHadithsByString(
      String query, String projectName) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/searchHadithsByString?project_name=$projectName&hadith=$query'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final List<dynamic> dynamicList = json.decode(responseBody);
      final List<String> stringList =
          dynamicList.map((e) => e.toString()).toList();

      return stringList;
    } else {
      throw Exception(
          'Failed to fetch search results. Status code: ${response.statusCode}');
    }
  }

  // API function to fetch expanded search results
  Future<List<String>> searchHadithsByOperators(
      String query, String projectName) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/searchHadithsByOperators?project_name=$projectName&hadith=$query'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final List<dynamic> dynamicList = json.decode(responseBody);
      final List<String> stringList =
          dynamicList.map((e) => e.toString()).toList();
      return stringList;
    } else {
      throw Exception(
          'Failed to fetch search results. Status code: ${response.statusCode}');
    }
  }

  // API function to sorted result
  Future<List<String>> sortResult(List<String> hadithList, bool byNarrator,
      bool byAuthenticity, String authenticityType) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sortHadith'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'hadithList': hadithList,
        'sortByNarrator': byNarrator,
        'sortByAuthenticity': byAuthenticity,
        'authenticityType': authenticityType,
      }),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);

      if (jsonResponse.containsKey('results') &&
          jsonResponse['results'] is List) {
        final List results = jsonResponse['results'];
        return results.map((result) => result.toString()).toList();
      } else {
        throw Exception(
            'Invalid response format: results key not found or invalid');
      }
    } else {
      throw Exception(
          'Failed to sort search results. Status code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAllProjectHadiths(
      String projectName, int page) async {
    if (!isServerOnline()) {
      return {};
    }
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/getAllProjectHadiths?projectName=$projectName&page=$page'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      if (data.isNotEmpty) {
        return data[0] as Map<String, dynamic>;
      } else {
        throw Exception('Invalid API response format');
      }
    } else {
      throw Exception(
          'Failed to load project hadiths: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> getAllHadiths(int page) async {
    if (!isServerOnline()) {
      return {};
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/getAllHadiths?page=$page'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      if (data.isNotEmpty) {
        return data[0] as Map<String, dynamic>;
      } else {
        throw Exception('Invalid API response format');
      }
    } else {
      throw Exception('Failed to load all hadiths: ${response.reasonPhrase}');
    }
  }

  // Method to fetch hadith details from backend
  Future<Map<String, dynamic>> getHadithDetails(
      String matn, String projectName) async {
    try {
      final response = await http.post(Uri.parse("$_baseUrl/getHadithDetails"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode({'matn': matn, 'projectName': projectName}));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        throw Exception("Failed to load project state: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching project state: $e");
    }
  }

  // Method to fetch list of hadith details from backend
  Future<List<Map<String, dynamic>>> getListOfHadithDetails(
      List<String> matn) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/getListOfHadithsDetails"),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'matn': matn}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedList =
            json.decode(utf8.decode(response.bodyBytes));
        return decodedList
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        throw Exception(
            "Failed to load Hadith details: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching Hadith details: $e");
    }
  }
}
