import 'package:quran/quran.dart' as quran;
import '../models/ayah_model.dart';

class QuranData {
  static List<Reciter> reciters = [
    Reciter("مشاري العفاسي", "https://www.everyayah.com/data/Alafasy_128kbps/"),
    Reciter("ماهر المعيقلي",
        "https://www.everyayah.com/data/MaherAlMuaiqly128kbps/"),
    Reciter("سعد الغامدي", "https://www.everyayah.com/data/Ghamadi_40kbps/"),
    Reciter("عبدالرحمن السديس",
        "https://www.everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/"),
    Reciter("الحصري", "https://www.everyayah.com/data/Husary_128kbps/"),
    Reciter("المنشاوي",
        "https://www.everyayah.com/data/Minshawy_Mujawwad_192kbps/"),
    Reciter("عبدالباسط",
        "https://www.everyayah.com/data/Abdul_Basit_Mujawwad_128kbps/"),
    Reciter("أحمد العجمي",
        "https://www.everyayah.com/data/Ahmed_ibn_Ali_al-Ajamy_128kbps_bitrate/"),
  ];

  static String _fmt(int surah, int ayah) =>
      "${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3";

  static List<AyahModel> generateFullQuran() {
    List<AyahModel> allAyahs = [];
    int globalIdCounter = 1;

    for (int surahIndex = 1; surahIndex <= 114; surahIndex++) {
      int verseCount = quran.getVerseCount(surahIndex);
      String surahName = quran.getSurahNameArabic(surahIndex);

      for (int verseIndex = 1; verseIndex <= verseCount; verseIndex++) {
        int pageNum = quran.getPageNumber(surahIndex, verseIndex);
        int juz = quran.getJuzNumber(surahIndex, verseIndex);

        allAyahs.add(AyahModel(
          id: verseIndex,
          globalId: globalIdCounter++,
          surahName: surahName,
          surahNumber: surahIndex,
          pageNumber: pageNum,
          juz: juz,
          text: quran.getVerse(surahIndex, verseIndex, verseEndSymbol: false),
          audioSuffix: _fmt(surahIndex, verseIndex),
        ));
      }
    }
    return allAyahs;
  }
}

class Reciter {
  final String name;
  final String serverUrl;
  Reciter(this.name, this.serverUrl);
}
