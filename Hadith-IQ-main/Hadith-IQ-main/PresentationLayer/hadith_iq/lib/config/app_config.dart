class AppConfig {
  static const bool isDebug = true;

  static const String appName = "Hadith IQ";
  // Localhost URL
  static const String apiBaseUrl = "http://localhost:8000/api";
  //static const String apiBaseUrl = "https://more-keen-elk.ngrok-free.app/api";
  //static const String webSocketUrl = "wss://more-keen-elk.ngrok-free.app/ws/status";
  static const String webSocketUrl = "ws://localhost:8000/ws/status";

  // UI preferences
  static const double defaultFontSize = 16.0;
  static const String fontFamily = "Cairo";
}
