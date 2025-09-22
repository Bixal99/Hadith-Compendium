import 'package:hadith_iq/api/network_helper.dart';
import 'package:hadith_iq/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NarratorService {
  final String _baseUrl = "${AppConfig.apiBaseUrl}/narrator";

  // Method to fetch projects narrators from backend
  Future<Map<String, dynamic>> getAllProjectNarrators(
      String projectName, int page) async {
    if (!isServerOnline()) {
      return {};
    }
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/getAllProjectNarrators?projectName=$projectName&page=$page'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      if (data.containsKey("results") && data["results"] is List) {
        return data;
      } else {
        throw Exception('Invalid API response format');
      }
    } else {
      throw Exception(
          'Failed to get all project narrators: ${response.reasonPhrase}');
    }
  }

  // Method to fetch all narrators from backend
  Future<Map<String, dynamic>> getAllNarrators(int page) async {
    if (!isServerOnline()) {
      return {};
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/getAllNarrators?page=$page'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      if (data.containsKey("results") && data["results"] is List) {
        return data;
      } else {
        throw Exception('Invalid API response format');
      }
    } else {
      throw Exception('Failed to get all narrators: ${response.reasonPhrase}');
    }
  }

  // Method to fetch all narrated hadiths from backend
  Future<Map<String, dynamic>> getNarratedHadiths(
      String projectName, String narratorName) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/getNarratedHadiths?project_name=$projectName&narrator_name=$narratorName'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      if (data.containsKey("results") && data["results"] is List) {
        return data;
      } else {
        throw Exception('Invalid API response format');
      }
    } else {
      throw Exception(
          'Failed to fetch narrated hadith: ${response.reasonPhrase}');
    }
  }

  // Method to fetch all chains where narrator appears from backend
  Future<dynamic> getNarratorChains(
      String projectName, String narratorName) async {
    final url =
        '$_baseUrl/getNarratorChains?project_name=$projectName&narrator_name=$narratorName';
    print('Making API request to: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    print('API Response Status Code: ${response.statusCode}');
    print('API Response Headers: ${response.headers}');

    if (response.statusCode == 200) {
      dynamic data = json.decode(utf8.decode(response.bodyBytes));
      print('Parsed data type: ${data.runtimeType}');
      return data;
    } else {
      print('API Error: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response body: ${response.body}');
      throw Exception(
          'Failed to fetch narrator chains: ${response.reasonPhrase}');
    }
  }

  // Method to send the request of convert html to text to backend
  Future<dynamic> convertHtmlToText(String filePath) async {
    try {
      if (!isServerOnline()) {
        return {
          'status': false,
          'message': 'Server is offline.',
        };
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/convertHtmlToText'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
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
          'status': false,
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Method to send the request to clean text  to backend
  Future<dynamic> cleanTextFile(String filePath, int count) async {
    try {
      if (!isServerOnline()) {
        return {
          'status': false,
          'message': 'Server is offline.',
        };
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/cleanFile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'filePath': filePath, 'arabic_count': count}),
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
          'status': false,
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Method to send the request fetch narrator data to backend
  Future<dynamic> fetchNarratorData(String filePath, int count) async {
    try {
      if (!isServerOnline()) {
        return {
          'status': false,
          'message': 'Server is offline.',
        };
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/fetchNarratorData'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'filePath': filePath, 'arabic_count': count}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(utf8.decode(response.bodyBytes));
        return responseBody;
      } else {
        return {
          'status': false,
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Function to fetch narrator search results
  Future<List<String>> fetchNarratorSearchResults(String narratorName) async {
    var response = await http.get(
      Uri.parse('$_baseUrl/searchNarrator?narrator_name=$narratorName'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);
      if (jsonResponse.containsKey('narrator') &&
          jsonResponse['narrator'] is List) {
        final List results = jsonResponse['narrator'];
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

  // Function to fetch narrator search results
  Future<List<String>> fetchSimilarNarrators(String narratorName) async {
    var response = await http.get(
      Uri.parse('$_baseUrl/getSimilarNarrators?narrator_name=$narratorName'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);
      if (jsonResponse.containsKey('narrator') &&
          jsonResponse['narrator'] is List) {
        final List results = jsonResponse['narrator'];
        return results.map((result) => result.toString()).toList();
      } else {
        throw Exception(
            'Invalid response format: results key not found or invalid');
      }
    } else {
      throw Exception(
          'Failed to fetch similar narrators. Status code: ${response.statusCode}');
    }
  }

  Future<dynamic> importNarrator(
      String narratorName,
      List<String> narratorTeacher,
      List<String> narratorStudent,
      List<String> opinion,
      List<String> scholar) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/importNarratorDetails'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'narratorName': narratorName,
          'narratorTeacher': narratorTeacher,
          'narratorStudent': narratorStudent,
          'opinion': opinion,
          'scholar': scholar
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(utf8.decode(response.bodyBytes));
        return responseBody;
      } else {
        return {
          'success': false,
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Method to send the request to associate narrator data to backend
  Future<dynamic> associateNarratorWithDetailedNarrator(String projectName,
      String narratorName, String detailedNarratorName) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/associateNarrator'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
          'narrator_name': narratorName,
          'detailed_narrator': detailedNarratorName
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(utf8.decode(response.bodyBytes));
        return responseBody;
      } else {
        return {
          'status': false,
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Method to send the request fetch narrator data to backend
  Future<dynamic> updateAssociateNarratorWithDetailedNarrator(
      String projectName,
      String narratorName,
      String detailedNarratorName) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/updateAssociateNarrator'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
          'narrator_name': narratorName,
          'detailed_narrator': detailedNarratorName
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody =
            json.decode(utf8.decode(response.bodyBytes));
        return responseBody;
      } else {
        return {
          'status': false,
          'message': 'Error: ${response.statusCode}. ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Method to fetch narrator details like opinion from backend
  Future<List<String>> getNarratorDetails(
      String projectName, String narratorName) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/getNarratorDetails?projectName=$projectName&narratorName=$narratorName'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        return [
          data["narrator_name"]?.toString() ?? "",
          data["detailed_name"]?.toString() ?? "",
          data["final_opinion"]?.toString() ?? "",
        ];
      } else {
        throw Exception(
            'Failed to fetch narrator details: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Exception while fetching narrator details: $e');
    }
  }

  // Method to fetch narator details like opinion from backend
  Future<List<dynamic>> getAllNarratorDetails(
      String projectName, List<String> narratorNames) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getAllNarratorDetails'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'narrator_names': narratorNames,
          'project_name': projectName,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedList =
            json.decode(utf8.decode(response.bodyBytes));
        return decodedList;
      } else {
        throw Exception(
            'Failed to fetch narrator details: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Exception while fetching narrator details: $e');
    }
  }

  // Method to fetch narrator teachers from backend
  Future<List<String>> getNarratorTeachers(
      String projectName, String narratorName) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/getNarratorTeacher?narratorName=$narratorName&projectName=$projectName'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => item.toString()).toList();
    } else {
      throw Exception(
          'Failed to get narrator teachers: ${response.reasonPhrase}');
    }
  }

  // Method to fetch narrator students from backend
  Future<List<String>> getNarratorStudents(
      String projectName, String narratorName) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/getNarratorStudent?narratorName=$narratorName&projectName=$projectName'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => item.toString()).toList();
    } else {
      throw Exception(
          'Failed to get narrator students: ${response.reasonPhrase}');
    }
  }

  // Function to fetch narrator search results
  Future<List<String>> sortNarrators(String projectName, List<String> narrators,
      bool byAuthenticity, bool byOrder) async {
    var response = await http.post(
      Uri.parse('$_baseUrl/sortNarrators'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({
        'byauthenticity': byAuthenticity,
        'byorder': byOrder,
        'narrator': narrators,
        'projectName': projectName,
      }),
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);
      if (jsonResponse.containsKey('narrator') &&
          jsonResponse['narrator'] is List) {
        final List results = jsonResponse['narrator'];
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

  // Method to get narrator tree data for tree visualization
  Future<Map<String, dynamic>> getNarratorTree(
      String projectName, String narratorName) async {
    if (!isServerOnline()) {
      return {};
    }

    final response = await http.get(
      Uri.parse(
          '$_baseUrl/getNarratorTree?projectName=$projectName&narratorName=$narratorName'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data;
    } else {
      throw Exception('Failed to get narrator tree: ${response.reasonPhrase}');
    }
  }
}
