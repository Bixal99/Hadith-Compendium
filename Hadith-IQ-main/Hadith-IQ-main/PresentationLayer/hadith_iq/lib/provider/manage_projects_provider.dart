import 'package:flutter/material.dart';

class ManageProjectsProvider extends ChangeNotifier {
  String _selectedProject = '';

  String get selectedProject => _selectedProject;

  void selectProject(String projectName) {
    _selectedProject = projectName;
    notifyListeners();
  }

  void importHadithFile(String fileName) {
    notifyListeners();
  }
}
