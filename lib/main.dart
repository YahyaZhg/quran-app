import 'dart:ui'; // لعمل تأثير التغويش (Blur)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_provider.dart';
import 'models/ayah_model.dart';
import 'data/quran_data.dart';

void main() {
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'مصحف المدينة',

            // === الثيم الفاتح (الصحراوي) ===
            theme: ThemeData(
              fontFamily: GoogleFonts.amiri().fontFamily,
              brightness: Brightness.light,
              // لون خلفية صحراوي فاتح (بيج)
              scaffoldBackgroundColor: const Color(0xFFEEDCBB),
              primaryColor: const Color(0xFF5D4037), // بني غامق للعناصر
              iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Color(0xFF5D4037)), // النصوص بنية
              ),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: const Color(0xFFEEDCBB).withOpacity(0.8),
                hintStyle:
                    TextStyle(color: const Color(0xFF5D4037).withOpacity(0.6)),
              ),
            ),

            // === الثيم الداكن (الأسود الكامل) ===
            darkTheme: ThemeData(
              fontFamily: GoogleFonts.amiri().fontFamily,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212), // أسود فحمي
              primaryColor: const Color(0xFFD4AF37), // ذهبي
              iconTheme:
                  const IconThemeData(color: Colors.white), // الأيقونات بيضاء
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white), // النصوص بيضاء
              ),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: const Color(0xFF2C2C2C),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),

            themeMode: provider.currentThemeMode,
            home: const QuranBookScreen(),
          );
        },
      ),
    );
  }
}

class QuranBookScreen extends StatefulWidget {
  const QuranBookScreen({super.key});
  @override
  State<QuranBookScreen> createState() => _QuranBookScreenState();
}

class _QuranBookScreenState extends State<QuranBookScreen> {
  bool _showControls = true;

  // متغيرات للبحث المخصص
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  List<AyahModel> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF5D4037);

    return Scaffold(
      body: Stack(
        children: [
          // 1. طبقة المصحف (الخلفية الأساسية)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!_isSearchActive) {
                  setState(() => _showControls = !_showControls);
                }
              },
              child: _buildBookView(provider),
            ),
          ),

          // 2. طبقة التغويش (Blur) - تظهر فقط عند البحث
          if (_isSearchActive)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() =>
                    _isSearchActive = false), // إغلاق البحث عند الضغط خارجاً
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // قوة التغويش
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // تعتيم بسيط
                  ),
                ),
              ),
            ),

          // 3. واجهة البحث العائمة
          if (_isSearchActive)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildSearchOverlay(context, provider, isDark, textColor),
            ),

          // 4. الشريط العلوي (يختفي عند البحث)
          if (!_isSearchActive)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildTopBar(context, provider, isDark, textColor),
            ),
        ],
      ),
    );
  }

  // === واجهة البحث العائمة ===
  Widget _buildSearchOverlay(BuildContext context, AppProvider provider,
      bool isDark, Color textColor) {
    return Column(
      children: [
        // حقل البحث
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor, // نفس لون الخلفية (تمويه)
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: textColor.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            autofocus: true,
            decoration: InputDecoration(
              hintText: "ابحث عن سورة، آية، أو رقم صفحة...",
              prefixIcon: Icon(Icons.search, color: textColor),
              suffixIcon: IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => setState(() {
                  _isSearchActive = false;
                  _searchController.clear();
                  _searchResults.clear();
                }),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
            onChanged: (query) {
              _performSearch(query, provider);
            },
          ),
        ),

        const SizedBox(height: 10),

        // نتائج البحث
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Text(
                      _searchController.text.isEmpty ? "" : "لا توجد نتائج",
                      style: const TextStyle(color: Colors.white)))
              : Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: _searchResults.length,
                    separatorBuilder: (c, i) =>
                        Divider(color: textColor.withOpacity(0.2)),
                    itemBuilder: (context, index) {
                      final ayah = _searchResults[index];
                      return ListTile(
                        title: Text("سورة ${ayah.surahName} - آية ${ayah.id}",
                            style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFD4AF37)
                                    : const Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(ayah.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontFamily: 'Amiri')),
                        leading: Text("ص ${ayah.pageNumber}",
                            style: TextStyle(color: textColor, fontSize: 12)),
                        onTap: () {
                          provider.goToAyah(ayah);
                          setState(() => _isSearchActive = false);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _performSearch(String query, AppProvider provider) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // بحث برقم الصفحة
    int? pageNum = int.tryParse(query);
    if (pageNum != null && pageNum >= 1 && pageNum <= 604) {
      // ننشئ نتيجة وهمية للانتقال للصفحة
      final dummyAyah = AyahModel(
          id: 0,
          globalId: 0,
          text: "انتقال سريع للصفحة $pageNum",
          surahName: "الصفحة",
          surahNumber: 0,
          pageNumber: pageNum,
          juz: 0,
          audioSuffix: "");
      setState(() => _searchResults = [dummyAyah]);
      return;
    }

    // بحث نصي
    final results = provider.allAyahs
        .where((ayah) {
          return ayah.text.contains(query) || ayah.surahName.contains(query);
        })
        .take(20)
        .toList(); // نأخذ أول 20 نتيجة للأداء

    setState(() => _searchResults = results);
  }

  Widget _buildTopBar(BuildContext context, AppProvider provider, bool isDark,
      Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        isDark
            ? Colors.black.withOpacity(0.9)
            : const Color(0xFF5D4037).withOpacity(0.2),
        Colors.transparent
      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.amber : textColor),
            onPressed: () => provider.toggleTheme(),
            tooltip: "تغيير الثيم",
          ),
          Text("المصحف الشريف",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFF2E7D32))),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.search,
                    color: isDark
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF2E7D32),
                    size: 28),
                onPressed: () {
                  setState(() {
                    _isSearchActive = true;
                    _showControls = false;
                  });
                },
              ),
              IconButton(
                  icon: Icon(Icons.settings, color: textColor),
                  onPressed: () => _showSettingsDialog(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookView(AppProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 20 : 10, horizontal: isDesktop ? 40 : 10),
            child: AspectRatio(
              aspectRatio: isDesktop ? 1.55 : 0.7,
              child: Container(
                decoration:
                    BoxDecoration(color: Colors.transparent, boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 10))
                ]),
                child: PageView.builder(
                  controller: provider.pageController,
                  itemCount: isDesktop ? (604 / 2).ceil() : 604,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (isDesktop) {
                      int rightPageNum = (index * 2) + 1;
                      int leftPageNum = (index * 2) + 2;
                      return Row(
                        children: [
                          Expanded(
                              child: QuranPageWidget(
                                  pageNumber: rightPageNum, isRightPage: true)),
                          Container(
                              width: 15,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.black,
                                  Colors.grey.shade400
                                ],
                              ))),
                          Expanded(
                              child: QuranPageWidget(
                                  pageNumber: leftPageNum, isLeftPage: true)),
                        ],
                      );
                    } else {
                      return QuranPageWidget(pageNumber: index + 1);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) =>
      showDialog(context: context, builder: (ctx) => const SettingsDialog());
}

// ==========================================
// === صفحة المصحف (التصميم الثابت) ===
// ==========================================
class QuranPageWidget extends StatelessWidget {
  final int pageNumber;
  final bool isRightPage;
  final bool isLeftPage;

  const QuranPageWidget(
      {super.key,
      required this.pageNumber,
      this.isRightPage = false,
      this.isLeftPage = false});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final ayahs = provider.getAyahsForPage(pageNumber);

    if (ayahs.isEmpty) return Container(color: const Color(0xFFFFFBE8));

    String topSurahName = ayahs.first.surahName;
    int topJuz = ayahs.first.juz;

    // === ورق المصحف (كريمي ثابت) ===
    return Container(
      color: const Color(0xFFFFFBE8),
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2E7D32), width: 6),
            gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBE8),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          child: Column(
            children: [
              Container(
                height: 30,
                color: const Color(0xFFE8F5E9),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("سورة $topSurahName",
                        style: GoogleFonts.amiri(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black)),
                    Text("الجزء $topJuz",
                        style: GoogleFonts.amiri(
                            fontSize: 14, color: Colors.black)),
                  ],
                ),
              ),
              Container(height: 2, color: Colors.black),
              const SizedBox(height: 5),
              Expanded(
                child: _buildJustifiedText(context, ayahs, provider),
              ),
              Text("$pageNumber",
                  style: GoogleFonts.amiri(fontSize: 12, color: Colors.black)),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJustifiedText(
      BuildContext context, List<AyahModel> ayahs, AppProvider provider) {
    List<Widget> pageBlocks = [];
    List<AyahModel> currentBlockAyahs = [];

    void flushBlock() {
      if (currentBlockAyahs.isNotEmpty) {
        pageBlocks.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              children: currentBlockAyahs.map((ayah) {
                bool isActive = provider.currentGlobalId == ayah.globalId;
                return TextSpan(
                  children: [
                    TextSpan(
                      text: " ${ayah.text} ",
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        height: 1.9,
                        color: Colors.black,
                        backgroundColor:
                            isActive ? provider.highlightColor : null,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () => provider.playAyah(ayah),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.brightness_1_outlined,
                                  size: 22, color: Color(0xFF2E7D32)),
                              Text("${ayah.id}",
                                  style: GoogleFonts.amiri(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ));
        currentBlockAyahs = [];
      }
    }

    for (var ayah in ayahs) {
      if (ayah.id == 1 && ayah.surahNumber != 1 && ayah.surahNumber != 9) {
        flushBlock();
        pageBlocks.add(const SizedBox(height: 5));
        pageBlocks.add(_buildSurahBanner(ayah.surahName));
        pageBlocks.add(_buildBasmalah());
        pageBlocks.add(const SizedBox(height: 5));
        currentBlockAyahs.add(ayah);
      } else {
        currentBlockAyahs.add(ayah);
      }
    }
    flushBlock();

    return SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: pageBlocks),
    );
  }

  Widget _buildSurahBanner(String surahName) {
    return Container(
      height: 35,
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text("سورة $surahName",
          style: GoogleFonts.amiri(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32))),
    );
  }

  Widget _buildBasmalah() {
    return Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
        textAlign: TextAlign.center,
        style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold));
  }
}

// === إعدادات بنفس لون الخلفية ===
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF5D4037);

    return AlertDialog(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // لون الخلفية مطابق للثيم
      title:
          Center(child: Text("الإعدادات", style: TextStyle(color: textColor))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<Reciter>(
            value: provider.currentReciter,
            isExpanded: true,
            dropdownColor: Theme.of(context).scaffoldBackgroundColor,
            style: TextStyle(color: textColor),
            items: provider.availableReciters
                .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                provider.changeReciter(v);
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 20),
          Text("لون الإشارة", style: TextStyle(color: textColor)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _c(context, const Color(0x44FFD700)),
              const SizedBox(width: 10),
              _c(context, const Color(0x444CAF50)),
              const SizedBox(width: 10),
              _c(context, const Color(0x442196F3)),
            ],
          )
        ],
      ),
    );
  }

  Widget _c(BuildContext context, Color color) => GestureDetector(
      onTap: () => Provider.of<AppProvider>(context, listen: false)
          .changeHighlightColor(color),
      child: CircleAvatar(backgroundColor: color, radius: 15));
}
