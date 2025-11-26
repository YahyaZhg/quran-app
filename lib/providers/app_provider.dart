import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/ayah_model.dart';
import '../data/quran_data.dart';

class AppProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<AyahModel> _allAyahs = [];

  // حالة التشغيل
  int _currentGlobalId = -1;
  bool _isPlaying = false;

  // الإعدادات
  Reciter _currentReciter = QuranData.reciters[0];
  Color _highlightColor = const Color(0x44FFD700);

  // التحكم في الصفحات
  PageController pageController = PageController();

  // === جديد: التحكم في الثيم (ليلي/نهاري) ===
  ThemeMode _currentThemeMode = ThemeMode.dark; // الافتراضي داكن

  AppProvider() {
    _allAyahs = QuranData.generateFullQuran();
    _audioPlayer.onPlayerComplete.listen((event) => playNextAyah());
  }

  // Getters
  List<AyahModel> get allAyahs => _allAyahs;
  List<AyahModel> getAyahsForPage(int pageNum) =>
      _allAyahs.where((a) => a.pageNumber == pageNum).toList();
  int get currentGlobalId => _currentGlobalId;
  bool get isPlaying => _isPlaying;
  Reciter get currentReciter => _currentReciter;
  Color get highlightColor => _highlightColor;
  List<Reciter> get availableReciters => QuranData.reciters;
  ThemeMode get currentThemeMode => _currentThemeMode;

  // دوال الثيم
  void toggleTheme() {
    _currentThemeMode =
        _currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // دوال التنقل
  void goToPage(int pageNum) {
    if (pageNum < 1) pageNum = 1;
    if (pageNum > 604) pageNum = 604;
    int targetIndex = (pageNum - 1) ~/ 2;
    if (pageController.hasClients) {
      pageController.jumpToPage(targetIndex); // استخدام Jump لسرعة الانتقال
    }
  }

  void goToAyah(AyahModel ayah) {
    goToPage(ayah.pageNumber);
    Future.delayed(const Duration(milliseconds: 500), () {
      playAyah(ayah);
    });
  }

  void changeReciter(Reciter newReciter) {
    _currentReciter = newReciter;
    notifyListeners();
  }

  void changeHighlightColor(Color color) {
    _highlightColor = color;
    notifyListeners();
  }

  Future<void> playAyah(AyahModel ayah) async {
    _currentGlobalId = ayah.globalId;
    _isPlaying = true;
    notifyListeners();

    try {
      await _audioPlayer.stop();
      String url = "${_currentReciter.serverUrl}${ayah.audioSuffix}";
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void playNextAyah() {
    int currentIndex =
        _allAyahs.indexWhere((a) => a.globalId == _currentGlobalId);
    if (currentIndex != -1 && currentIndex < _allAyahs.length - 1) {
      playAyah(_allAyahs[currentIndex + 1]);
    } else {
      stopAudio();
    }
  }

  void stopAudio() {
    _audioPlayer.stop();
    _isPlaying = false;
    _currentGlobalId = -1;
    notifyListeners();
  }
}
