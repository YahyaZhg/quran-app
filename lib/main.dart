import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart'; // مكتبة الصور

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
          double uiFont = provider.uiFontSize;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'QuranTV',
            theme: FlexThemeData.light(
              scheme: FlexScheme.gold,
              useMaterial3: true,
              fontFamily: GoogleFonts.amiri().fontFamily,
            ).copyWith(
              scaffoldBackgroundColor: const Color(0xFFEEDCBB),
              textTheme: TextTheme(
                bodyMedium: TextStyle(fontSize: uiFont),
                bodyLarge: TextStyle(fontSize: uiFont + 2),
              ),
            ),
            darkTheme: FlexThemeData.dark(
              scheme: FlexScheme.gold,
              useMaterial3: true,
              fontFamily: GoogleFonts.amiri().fontFamily,
            ).copyWith(
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme: TextTheme(
                bodyMedium: TextStyle(fontSize: uiFont),
                bodyLarge: TextStyle(fontSize: uiFont + 2),
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
  bool _isSettingsOpen = false;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  List<AyahModel> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF5D4037);
    final accentColor =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFF2E7D32);

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 1. السايد بار
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                width: _isSettingsOpen ? 320 : 0,
                child: Visibility(
                  visible: _isSettingsOpen,
                  maintainState: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                          right: BorderSide(
                              color: Theme.of(context).dividerColor)),
                      boxShadow: [
                        if (_isSettingsOpen)
                          const BoxShadow(color: Colors.black12, blurRadius: 20)
                      ],
                    ),
                    child: _buildSidebarContent(
                        provider, textColor, accentColor, provider.uiFontSize),
                  ),
                ),
              ),

              // 2. منطقة المصحف (الصور)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isSettingsOpen)
                      setState(() => _isSettingsOpen = false);
                  },
                  child: Stack(
                    children: [
                      _buildBookView(provider),

                      // التذييل
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            "QuranTV.site",
                            style: GoogleFonts.inter(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: accentColor.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. الأزرار العلوية
          if (!_isSearchActive)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                          _isSettingsOpen ? Icons.close : Icons.menu_rounded,
                          size: 32,
                          color: textColor),
                      onPressed: () =>
                          setState(() => _isSettingsOpen = !_isSettingsOpen),
                    ),
                    IconButton(
                      icon: Icon(Icons.search_rounded,
                          size: 32, color: accentColor),
                      onPressed: () => setState(() {
                        _isSearchActive = true;
                        _isSettingsOpen = false;
                      }),
                    ),
                  ],
                ),
              ),
            ),

          // 4. البحث
          if (_isSearchActive)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isSearchActive = false),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    alignment: Alignment.center,
                    child: Container(
                      width: 600,
                      height: 600,
                      margin: const EdgeInsets.only(top: 50),
                      padding: const EdgeInsets.all(20),
                      child: _buildSearchContent(provider, textColor,
                          accentColor, provider.uiFontSize),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- السايد بار ---
  Widget _buildSidebarContent(AppProvider provider, Color textColor,
      Color accentColor, double fontSize) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
      children: [
        Center(
            child: Text("QuranTV.site",
                style: GoogleFonts.inter(
                    fontSize: fontSize + 8,
                    fontWeight: FontWeight.bold,
                    color: accentColor))),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 20),
        Text("القارئ المفضل",
            style: TextStyle(
                color: textColor.withOpacity(0.7), fontSize: fontSize * 0.85)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Reciter>(
              isExpanded: true,
              value: provider.currentReciter,
              dropdownColor: Theme.of(context).cardColor,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: textColor, size: fontSize + 4),
              style: TextStyle(
                  color: textColor,
                  fontFamily: 'Amiri',
                  fontSize: fontSize + 2),
              items: provider.availableReciters
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (v) => provider.changeReciter(v!),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Text("حجم خط الواجهة",
            style: TextStyle(
                color: textColor.withOpacity(0.7), fontSize: fontSize * 0.85)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFontSizeOption(
                provider, 14.0, "صغير", accentColor, textColor),
            _buildFontSizeOption(
                provider, 16.0, "متوسط", accentColor, textColor),
            _buildFontSizeOption(
                provider, 20.0, "كبير", accentColor, textColor),
          ],
        ),
        const SizedBox(height: 40),
        InkWell(
          onTap: () async {
            final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'qurantv.site@gmail.com',
                query: 'subject=دعم فني - QuranTV');
            if (await canLaunchUrl(emailLaunchUri))
              await launchUrl(emailLaunchUri);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: textColor, size: fontSize + 4),
                const SizedBox(width: 15),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text("الدعم الفني",
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize)),
                      Text("تواصل معنا",
                          style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: fontSize * 0.7)),
                    ])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        InkWell(
          onTap: () => provider.toggleTheme(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border.all(color: textColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                  provider.currentThemeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: accentColor,
                  size: fontSize + 4),
              const SizedBox(width: 10),
              Text(
                  provider.currentThemeMode == ThemeMode.dark
                      ? "الوضع النهاري"
                      : "الوضع الليلي",
                  style: TextStyle(color: textColor, fontSize: fontSize)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeOption(AppProvider provider, double size, String label,
      Color accent, Color text) {
    bool isSelected = provider.uiFontSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.changeUiFontSize(size),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: isSelected ? accent : text.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? accent : text.withOpacity(0.2))),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : text)),
        ),
      ),
    );
  }

  // --- البحث ---
  Widget _buildSearchContent(AppProvider provider, Color textColor,
      Color accentColor, double fontSize) {
    return Column(children: [
      TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white, fontSize: fontSize + 4),
        autofocus: true,
        decoration: InputDecoration(
            hintText: "بحث...",
            hintStyle: TextStyle(color: Colors.white54, fontSize: fontSize),
            filled: true,
            fillColor: Colors.black45,
            prefixIcon:
                Icon(Icons.search, color: Colors.white, size: fontSize + 6),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide.none)),
        onChanged: (q) => _performSearch(q, provider),
      ),
      const SizedBox(height: 15),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15)),
              child: ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: _searchResults.length,
                  separatorBuilder: (c, i) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (c, i) {
                    final ayah = _searchResults[i];
                    return ListTile(
                      title: Text("سورة ${ayah.surahName}",
                          style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize)),
                      subtitle: Text(ayah.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white70, fontSize: fontSize * 0.9)),
                      leading: Text("${ayah.id}",
                          style: TextStyle(
                              color: Colors.white38, fontSize: fontSize * 0.8)),
                      onTap: () {
                        provider.goToAyah(ayah);
                        setState(() => _isSearchActive = false);
                      },
                    );
                  }))),
    ]);
  }

  void _performSearch(String query, AppProvider provider) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    int? pageNum = int.tryParse(query);
    if (pageNum != null && pageNum >= 1 && pageNum <= 604) {
      final dummy = AyahModel(
          id: 0,
          globalId: 0,
          text: "انتقال للصفحة $pageNum",
          surahName: "صفحة",
          surahNumber: 0,
          pageNumber: pageNum,
          juz: 0,
          audioSuffix: "");
      setState(() => _searchResults = [dummy]);
      return;
    }
    final results = provider.allAyahs
        .where((a) => a.text.contains(query) || a.surahName.contains(query))
        .take(15)
        .toList();
    setState(() => _searchResults = results);
  }

  // --- بناء الكتاب (نظام الصور) ---
  Widget _buildBookView(AppProvider provider) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth > 900;
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: AspectRatio(
            aspectRatio: isDesktop ? 1.55 : 0.72,
            child: PageView.builder(
              controller: provider.pageController,
              // 302 زوج من الصفحات (604 / 2)
              itemCount: isDesktop ? (604 / 2).ceil() : 604,
              reverse: true, // RTL
              physics: const BouncingScrollPhysics(),
              onPageChanged: (idx) {
                int p = isDesktop ? (idx * 2) + 1 : idx + 1;
                provider.savePage(p);
              },
              itemBuilder: (context, index) {
                if (isDesktop) {
                  // المعادلة الصحيحة للكتب العربية:
                  // عندما نفتح الكتاب:
                  // اليمين هو الرقم الفردي (مثلاً 1, 3, 5)
                  // اليسار هو الرقم الزوجي التالي (مثلاً 2, 4, 6)

                  int rightPageNum = (index * 2) + 1;
                  int leftPageNum = (index * 2) + 2;

                  return Row(children: [
                    // صفحة اليمين
                    Expanded(child: QuranImagePage(pageNumber: rightPageNum)),

                    // كعب الكتاب
                    Container(
                        width: 15,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                          Colors.grey.shade400,
                          Colors.black,
                          Colors.grey.shade400
                        ]))),

                    // صفحة اليسار (نتأكد أنها موجودة)
                    Expanded(
                        child: (leftPageNum <= 604)
                            ? QuranImagePage(pageNumber: leftPageNum)
                            : Container(color: const Color(0xFFFFFBE8))),
                  ]);
                } else {
                  return QuranImagePage(pageNumber: index + 1);
                }
              },
            ),
          ),
        ),
      );
    });
  }
}

// ============================ صفحة المصحف (صور) ============================
class QuranImagePage extends StatelessWidget {
  final int pageNumber;
  const QuranImagePage({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    // رابط الصورة (مصدر موثوق عالي الجودة)
    // نستخدم padLeft لضمان أن رقم 1 يصبح 001
    String pageStr = pageNumber.toString().padLeft(3, '0');
    // هذا المصدر ممتاز جداً ونظيف
    String imageUrl =
        "https://raw.githubusercontent.com/HossamAbdelLatif/quran_images/master/images/$pageStr.png";

    return Container(
      color: const Color(0xFFFFFBE8), // خلفية الورقة (تحت الصورة)
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.fill, // ملء الصفحة بالكامل
        placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
        errorWidget: (context, url, error) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
  }
}
