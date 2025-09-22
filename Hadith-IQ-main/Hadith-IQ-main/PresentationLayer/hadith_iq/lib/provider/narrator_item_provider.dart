import 'package:flutter/material.dart';

class NarratorProvider extends ChangeNotifier {
  String _selectedNarrator = '';
  List<List<String>> _narratedHadiths = [[], []];
  String _narratorDetails = '';
  List<String> _narratorTeachers = [];
  List<String> _narratorStudents = [];

  String get selectedNarrator => _selectedNarrator;
  String get narratorDetails => _narratorDetails;
  List<List<String>> get narratedHadiths => _narratedHadiths;
  List<String> get narratorTeachers => _narratorTeachers;
  List<String> get narratorStudents => _narratorStudents;

  void setNarrator(String name) {
    _selectedNarrator = name;
    notifyListeners();
  }

  void setNarratedHadiths(List<List<String>> allNarratedHadiths) {
    _narratedHadiths = allNarratedHadiths;
    notifyListeners();
  }

  void setNarratorDetails(
      String name,
      List<List<String>> allNarratedHadiths,
      String narratorDetials,
      List<String> narratorTeachers,
      List<String> narratorStudents) {
    _selectedNarrator = name;
    _narratedHadiths = allNarratedHadiths;
    _narratorDetails = narratorDetials;
    _narratorTeachers = narratorTeachers;
    _narratorStudents = narratorStudents;

    notifyListeners();
  }
}
