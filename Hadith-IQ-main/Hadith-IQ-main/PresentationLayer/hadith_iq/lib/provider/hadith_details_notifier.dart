import 'package:flutter/material.dart';

class HadithDetailsProvider extends ChangeNotifier {
  String _selectedHadith = '';
  String _books = '';
  List<String> _sanad = [];
  
  String get selectedHadith => _selectedHadith;
  String get books => _books;
  List<String> get sanad => _sanad; 

  void setHadithDetails(String matn, List<String> sanad, String books) {
    _selectedHadith = matn;
    _books = books;
    _sanad = sanad;
    notifyListeners(); // Notify UI to rebuild with new value
  }
}
