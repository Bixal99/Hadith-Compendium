import 'package:hadith_iq/api/network_helper.dart';
import 'package:hadith_iq/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectService {
  final String _baseUrl = "${AppConfig.apiBaseUrl}/project";
  // Method to fetch projects from backend
  Future<List<List<String>>> fetchProjects() async {
    
    final response = await http.get(Uri.parse('$_baseUrl/getProjects'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      return data.map<List<String>>((project) {
        return [
          project['projectName'] ?? '',
          project['lastUpdated'] ?? '',
          project['createdAt'] ?? ''
        ];
      }).toList();
    } else {
      throw Exception('Failed to load projects: ${response.reasonPhrase}');
    }
  }

  // Method to send the new project request to backend
  Future<dynamic> addProject(String projectName) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/addProject'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
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

  // Method to send the rename project request to backend
  Future<dynamic> renameProject(String currentName, String newName) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/renameProject'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'currentName': currentName, 'newName': newName}),
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

  // Method to send the delete project request to backend
  Future<dynamic> deleteProject(String projectName) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/deleteProject'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
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

  // Method to fetch project state from backend
  Future<List<String>> getProjectState(String projectName) async {
    
    final response = await http.get(
      Uri.parse('$_baseUrl/getProjectState?projectName=$projectName'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      // Ensure the key 'stateQuery' exists and is a list
      if (data.containsKey('stateQuery') && data['stateQuery'] is List) {
        return List<String>.from(data['stateQuery']);
      } else {
        throw Exception('Invalid API response format');
      }
    } else {
      throw Exception('Failed to load project state: ${response.reasonPhrase}');
    }
  }

  // Method to fetch project state from backend
  Future<Map<String, dynamic>> getSingleProjectState(
      String projectName, String stateQuery) async {
    
    try {
      final response = await http.post(
          Uri.parse("$_baseUrl/getSingleProjectState"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json
              .encode({'projectName': projectName, 'stateQuery': stateQuery}));

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

  // Method to send the rename project state request to backend
  Future<dynamic> renameProjectState(
      String projectName, String currentName, String newName) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/renameProjectState'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
          'oldQueryName': currentName,
          'newQueryName': newName
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

  // Method to send the delete project state request to backend
  Future<dynamic> deleteProjectState(
      String projectName, String queryName) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/deleteProjectState'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
          'queryName': queryName,
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

  // Method to send the merge project state request to backend
  Future<dynamic> mergeProjectState(
      String projectName, String queryName, List<String> queryNames) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/mergeProjectState'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
          'queryNames': queryNames,
          'queryName': queryName,
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

  // Method to send the delete single hadith from project state request to backend
  Future<dynamic> removeHadithFromStateQuery(
      String projectName, String queryName, List<String> matn) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/removeHadithFromState'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'matn': matn,
          'projectName': projectName,
          'stateQuery': queryName,
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

  // Method to send the save project state request to backend
  Future<dynamic> saveProjectState(
      String projectName, String queryName, List<String> matnList) async {
    if (!isServerOnline()) {
      return {
        'status': false,
        'message': 'Server is offline.',
      };
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/saveProjectState'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'projectName': projectName,
          'stateData': matnList,
          'stateQuery': queryName,
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

  // Method to fetch project stats from backend
  Future<Map<String, dynamic>> getProjectStats(String projectName) async {
    
    final response = await http.get(
      Uri.parse('$_baseUrl/getProjectStats?projectName=$projectName'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      return data;
    } else {
      throw Exception('Failed to load project stats: ${response.reasonPhrase}');
    }
  }
}
