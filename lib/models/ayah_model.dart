class AyahModel {
  final int id;
  final int globalId;
  final String text;
  final String surahName;
  final int surahNumber;
  final int pageNumber;
  final int juz;
  final String audioSuffix;

  AyahModel({
    required this.id,
    required this.globalId,
    required this.text,
    required this.surahName,
    required this.surahNumber,
    required this.pageNumber,
    required this.juz,
    required this.audioSuffix,
  });
}
