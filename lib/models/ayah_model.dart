class AyahModel {
  final int id; // رقم الآية
  final int globalId; // رقم تسلسلي
  final String text; // نص الآية
  final String surahName; // اسم السورة
  final int surahNumber; // رقم السورة (جديد)
  final int pageNumber; // رقم الصفحة
  final int juz; // رقم الجزء
  final String audioSuffix; // رابط الصوت

  AyahModel({
    required this.id,
    required this.globalId,
    required this.text,
    required this.surahName,
    required this.surahNumber, // لا تنس إضافة هذا
    required this.pageNumber,
    required this.juz,
    required this.audioSuffix,
  });
}

class Reciter {
  final String name;
  final String serverUrl;
  Reciter(this.name, this.serverUrl);
}
