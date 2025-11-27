import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضروري جداً للنسخ (Clipboard)
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

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
                titleMedium: TextStyle(fontSize: uiFont),
                labelLarge: TextStyle(fontSize: uiFont),
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
                titleMedium: TextStyle(fontSize: uiFont),
                labelLarge: TextStyle(fontSize: uiFont),
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
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 1)
                      ],
                    ),
                    // نمرر isDark هنا لنستخدمها في الديالوج
                    child: _buildSidebarContent(context, provider, textColor,
                        accentColor, provider.uiFontSize, isDark),
                  ),
                ),
              ),

              // 2. منطقة المصحف
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isSettingsOpen)
                      setState(() => _isSettingsOpen = false);
                  },
                  child: Stack(
                    children: [
                      _buildBookView(provider),
                      Positioned(
                        bottom: 15,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            "QuranTV.site",
                            style: GoogleFonts.inter(
                                fontSize: 13,
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

  // --- محتوى السايد بار (محدث مع زر الدعم الجديد) ---
  Widget _buildSidebarContent(BuildContext context, AppProvider provider,
      Color textColor, Color accentColor, double fontSize, bool isDark) {
    TextStyle itemStyle = TextStyle(color: textColor, fontSize: fontSize);
    TextStyle labelStyle =
        TextStyle(color: textColor.withOpacity(0.7), fontSize: fontSize * 0.85);

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

        // 1. القارئ
        Text("القارئ المفضل", style: labelStyle),
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

        // 2. حجم الخط
        Text("حجم خط الواجهة", style: labelStyle),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFontSizeOption(
                provider, 14.0, "صغير", accentColor, textColor, fontSize),
            _buildFontSizeOption(
                provider, 16.0, "متوسط", accentColor, textColor, fontSize),
            _buildFontSizeOption(
                provider, 20.0, "كبير", accentColor, textColor, fontSize),
          ],
        ),

        const SizedBox(height: 25),

        // 3. ألوان التظليل
        Text("لون التحديد", style: labelStyle),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _c(provider, const Color(0x44FFD700)),
            _c(provider, const Color(0x444CAF50)),
            _c(provider, const Color(0x442196F3)),
          ],
        ),

        const SizedBox(height: 40),

        // 4. زر الدعم الفني (يفتح النافذة)
        InkWell(
          onTap: () {
            // نغلق السايد بار أولاً لجمالية المنظر
            setState(() => _isSettingsOpen = false);
            // نفتح النافذة المنبثقة
            _showSupportDialog(
                context, isDark, textColor, accentColor, fontSize);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1), // لون محايد للدعم
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.contact_support_outlined,
                    color: textColor, size: fontSize + 4),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الدعم والاستفسارات",
                          style:
                              itemStyle.copyWith(fontWeight: FontWeight.bold)),
                      Text("تواصل معنا للإبلاغ أو الاقتراح",
                          style: itemStyle.copyWith(
                              fontSize: fontSize * 0.7,
                              color: textColor.withOpacity(0.6))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        // 5. زر الثيم
        InkWell(
          onTap: () => provider.toggleTheme(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border.all(color: textColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    style: itemStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // === نافذة الدعم الفني المنبثقة ===
  void _showSupportDialog(BuildContext context, bool isDark, Color textColor,
      Color accentColor, double fontSize) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFBE8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentColor.withOpacity(0.5))),
        title: Row(
          children: [
            Icon(Icons.headset_mic, color: accentColor, size: 30),
            const SizedBox(width: 10),
            Text("مركز الدعم الفني",
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize + 4)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "أهلاً بك في QuranTV.site\nيمكنك التواصل معنا مباشرة عبر البريد الإلكتروني في حال واجهت أي مشكلة تقنية، أو لطلب إضافة قراء جدد، أو لتقديم أي اقتراحات لتحسين الموقع.",
              style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: fontSize,
                  height: 1.6),
            ),
            const SizedBox(height: 25),

            // صندوق الإيميل مع زر النسخ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black45 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الإيميل
                  SelectableText(
                    "qurantv.site@gmail.com",
                    style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        fontFamily: GoogleFonts.inter().fontFamily),
                  ),

                  // زر النسخ
                  Tooltip(
                    message: "نسخ العنوان",
                    child: IconButton(
                      icon: Icon(Icons.copy, color: textColor.withOpacity(0.7)),
                      onPressed: () {
                        // نسخ للحافظة
                        Clipboard.setData(const ClipboardData(
                            text: "qurantv.site@gmail.com"));

                        // إظهار رسالة تأكيد (SnackBar)
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text("تم نسخ البريد الإلكتروني بنجاح"),
                          backgroundColor: accentColor,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إغلاق", style: TextStyle(color: textColor)),
          )
        ],
      ),
    );
  }

  // ودجت اختيار حجم الخط
  Widget _buildFontSizeOption(AppProvider provider, double size, String label,
      Color accent, Color text, double currentSize) {
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
            border:
                Border.all(color: isSelected ? accent : text.withOpacity(0.2)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : text)),
        ),
      ),
    );
  }

  Widget _c(AppProvider provider, Color color) {
    return GestureDetector(
      onTap: () => provider.changeHighlightColor(color),
      child: CircleAvatar(backgroundColor: color, radius: 15),
    );
  }

  // --- محتوى البحث ---
  Widget _buildSearchContent(AppProvider provider, Color textColor,
      Color accentColor, double fontSize) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white, fontSize: fontSize + 4),
          autofocus: true,
          decoration: InputDecoration(
            hintText: "ابحث عن آية، سورة، أو رقم صفحة...",
            hintStyle: TextStyle(color: Colors.white54, fontSize: fontSize),
            filled: true,
            fillColor: Colors.black45,
            prefixIcon:
                Icon(Icons.search, color: Colors.white, size: fontSize + 6),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide.none),
          ),
          onChanged: (q) => _performSearch(q, provider),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black87, borderRadius: BorderRadius.circular(15)),
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: _searchResults.length,
              separatorBuilder: (c, i) => const Divider(color: Colors.white10),
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

  // --- عرض الكتاب ---
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
              itemCount: isDesktop ? (604 / 2).ceil() : 604,
              reverse: true,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (idx) {
                int p = isDesktop ? (idx * 2) + 1 : idx + 1;
                provider.savePage(p);
              },
              itemBuilder: (context, index) {
                if (isDesktop) {
                  int right = (index * 2) + 1;
                  int left = (index * 2) + 2;
                  return Row(children: [
                    Expanded(child: QuranPageWidget(pageNumber: right)),
                    Container(
                        width: 15,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                          Colors.grey.shade400,
                          Colors.black,
                          Colors.grey.shade400
                        ]))),
                    Expanded(child: QuranPageWidget(pageNumber: left)),
                  ]);
                } else {
                  return QuranPageWidget(pageNumber: index + 1);
                }
              },
            ),
          ),
        ),
      );
    });
  }
}

// ============================ صفحة المصحف ============================
class QuranPageWidget extends StatelessWidget {
  final int pageNumber;
  const QuranPageWidget({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final ayahs = provider.getAyahsForPage(pageNumber);
    if (ayahs.isEmpty) return Container(color: const Color(0xFFFFFBE8));

    bool isSpecialPage = pageNumber == 1 || pageNumber == 2;
    const paperColor = Color(0xFFFFFBE8);
    const borderColor = Color(0xFF2E7D32);
    const goldColor = Color(0xFFFFD700);

    return Container(
      color: paperColor,
      padding: const EdgeInsets.all(3),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 5),
            gradient: const LinearGradient(
                colors: [Color(0xFF43A047), borderColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Container(
          decoration: BoxDecoration(
            color: paperColor,
            border: Border.all(color: goldColor, width: 2),
          ),
          child: isSpecialPage
              ? _buildSpecialLayout(context, ayahs, provider)
              : _buildFullPageLayout(context, ayahs, provider, pageNumber),
        ),
      ),
    );
  }

  Widget _buildSpecialLayout(
      BuildContext context, List<AyahModel> ayahs, AppProvider provider) {
    return Column(
      children: [
        _buildHeader(ayahs.first),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (ayahs.first.surahNumber != 9) _buildBasmalah(),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: ayahs
                        .map((ayah) => _buildAyahSpan(ayah, provider))
                        .toList(),
                  )
                ],
              ),
            ),
          ),
        ),
        _buildFooter(pageNumber),
      ],
    );
  }

  Widget _buildFullPageLayout(BuildContext context, List<AyahModel> ayahs,
      AppProvider provider, int pageNum) {
    List<Widget> content = [];
    List<AyahModel> currentBlock = [];

    void flush() {
      if (currentBlock.isNotEmpty) {
        content.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              children: currentBlock
                  .map((a) => _buildAyahTextSpan(a, provider))
                  .toList(),
            ),
          ),
        ));
        currentBlock = [];
      }
    }

    for (var a in ayahs) {
      if (a.id == 1 && a.surahNumber != 1 && a.surahNumber != 9) {
        flush();
        content.add(const SizedBox(height: 10));
        content.add(_buildSurahBanner(a.surahName));
        content.add(_buildBasmalah());
        content.add(const SizedBox(height: 5));
        currentBlock.add(a);
      } else {
        currentBlock.add(a);
      }
    }
    flush();

    return Column(
      children: [
        _buildHeader(ayahs.first),
        const Divider(height: 4, color: Colors.black),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content),
            ),
          ),
        ),
        _buildFooter(pageNum),
      ],
    );
  }

  Widget _buildHeader(AyahModel ayah) {
    return Container(
      height: 30,
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("سورة ${ayah.surahName}",
              style: GoogleFonts.amiri(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black)),
          Text("الجزء ${ayah.juz}",
              style: GoogleFonts.amiri(fontSize: 14, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildFooter(int num) {
    return Container(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text("$num",
          style: GoogleFonts.amiri(fontSize: 12, color: Colors.black)),
    );
  }

  Widget _buildSurahBanner(String name) => Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
      height: 35,
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2E7D32)),
          borderRadius: BorderRadius.circular(5)),
      alignment: Alignment.center,
      child: Text("سورة $name",
          style: GoogleFonts.amiri(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32))));
  Widget _buildBasmalah() => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
          textAlign: TextAlign.center,
          style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold)));

  Widget _buildAyahSpan(AyahModel ayah, AppProvider provider) {
    bool active = provider.currentGlobalId == ayah.globalId;
    return InkWell(
      onTap: () => provider.playAyah(ayah),
      child: Container(
          color: active ? provider.highlightColor : null,
          child: Text("${ayah.text} ﴿${ayah.id}﴾ ",
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                  fontSize: provider.fixedQuranFontSize,
                  height: 2.0,
                  color: Colors.black))),
    );
  }

  TextSpan _buildAyahTextSpan(AyahModel ayah, AppProvider provider) {
    bool active = provider.currentGlobalId == ayah.globalId;
    return TextSpan(
      children: [
        TextSpan(
          text: "${ayah.text} ",
          style: GoogleFonts.amiri(
            fontSize: provider.fixedQuranFontSize,
            height: 2.3,
            color: Colors.black,
            backgroundColor: active ? provider.highlightColor : null,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => provider.playAyah(ayah),
        ),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => provider.playAyah(ayah),
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Stack(alignment: Alignment.center, children: [
                Icon(Icons.brightness_1_outlined,
                    size: provider.fixedQuranFontSize + 4,
                    color: const Color(0xFF2E7D32)),
                Text("${ayah.id}",
                    style: GoogleFonts.amiri(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black))
              ]),
            ),
          ),
        ),
        const TextSpan(text: " "),
      ],
    );
  }
}
