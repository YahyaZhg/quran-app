import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ayah_model.dart';
import '../data/quran_data.dart';

class AppProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<AyahModel> _allAyahs = [];

  // الحالة
  int _currentGlobalId = -1;
  bool _isPlaying = false;
  Reciter _currentReciter = QuranData.reciters[0];
  Color _highlightColor = const Color(0x44FFD700);

  // التحكم
  PageController pageController = PageController();
  ThemeMode _currentThemeMode = ThemeMode.light;

  // === الخطوط ===
  // 👇 تم تصحيح الاسم هنا ليطابق ما استخدمناه في main.dart
  final double fixedQuranFontSize = 22.0;

  double _uiFontSize = 14.0; // متغير للواجهة (الإعدادات والقوائم)

  AppProvider() {
    _init();
  }

  void _init() async {
    _allAyahs = QuranData.generateFullQuran();
    final prefs = await SharedPreferences.getInstance();

    int savedPage = prefs.getInt('last_page') ?? 1;
    // تحميل حجم خط الواجهة المحفوظ
    _uiFontSize = prefs.getDouble('ui_font_size') ?? 14.0;

    int initialIndex = (savedPage - 1) ~/ 2;
    pageController = PageController(initialPage: initialIndex);

    _audioPlayer.onPlayerComplete.listen((event) => playNextAyah());
    notifyListeners();
  }

  // Getters
  List<AyahModel> get allAyahs => _allAyahs;
  List<AyahModel> getAyahsForPage(int pageNum) =>
      _allAyahs.where((a) => a.pageNumber == pageNum).toList();
  int get currentGlobalId => _currentGlobalId;
  Reciter get currentReciter => _currentReciter;
  Color get highlightColor => _highlightColor;
  ThemeMode get currentThemeMode => _currentThemeMode;
  List<Reciter> get availableReciters => QuranData.reciters;
  double get uiFontSize => _uiFontSize;

  // Actions

  // تغيير حجم خط الواجهة وحفظه
  void changeUiFontSize(double size) async {
    _uiFontSize = size;
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('ui_font_size', size);
    notifyListeners();
  }

  void savePage(int pageNum) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('last_page', pageNum);
  }

  void toggleTheme() {
    _currentThemeMode =
        _currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void changeReciter(Reciter newReciter) {
    _currentReciter = newReciter;
    notifyListeners();
  }

  void changeHighlightColor(Color color) {
    _highlightColor = color;
    notifyListeners();
  }

  void goToPage(int pageNum) {
    if (pageNum < 1) pageNum = 1;
    if (pageNum > 604) pageNum = 604;
    int targetIndex = (pageNum - 1) ~/ 2;
    if (pageController.hasClients) {
      pageController.animateToPage(targetIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    }
  }

  void goToAyah(AyahModel ayah) {
    goToPage(ayah.pageNumber);
    Future.delayed(const Duration(milliseconds: 700), () => playAyah(ayah));
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
      debugPrint("Error: $e");
    }
  }

  void playNextAyah() {
    int currentIndex =
        _allAyahs.indexWhere((a) => a.globalId == _currentGlobalId);
    if (currentIndex != -1 && currentIndex < _allAyahs.length - 1) {
      playAyah(_allAyahs[currentIndex + 1]);
    } else {
      _audioPlayer.stop();
      _isPlaying = false;
      _currentGlobalId = -1;
      notifyListeners();
    }
  }
}
