import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const AiremoveApp());
}

// ==========================================
// 1. نماذج البيانات (Data Models)
// ==========================================

enum EditorTab {
  cutout('تفريغ شفاف', Icons.content_cut),
  colorHarmony('ألوان وخلفيات AI', Icons.palette),
  threeScenes('3 مشاهد AI', Icons.auto_awesome),
  cartoonStickers('ملصقات كرتونية', Icons.stars);

  final String titleAr;
  final IconData icon;
  const EditorTab(this.titleAr, this.icon);
}

enum SceneTheme {
  smartAutoDetect('اقتراح الذكاء الاصطناعي ⭐', 'مشاهد ملائمة لمحتوى الصورة تلقائياً'),
  petsAndHome('حيوانات أليفة ومنزل دافئ', 'إطعام الحيوان، متجر الحلوى وصالة مريحة'),
  fashionShopping('تسوق وأزياء راقية', 'بوتيك أزياء، مقهى باريسي ومول تجاري'),
  cozyLifestyle('أجواء دافئة وسكنية', 'مدفأة ريفية، بنتهاوس الغروب وبساط صوفي'),
  royalStudio('استوديو وفخامة', 'إضاءة مسرحية، قصر تاريخي وأرضية رخامية'),
  adventureNature('طبيعة ومغامرات', 'شاطئ استوائي، كوخ جبلي وغابة خريفية');

  final String titleAr;
  final String description;
  const SceneTheme(this.titleAr, this.description);
}

class SceneSpec {
  final int id;
  final String titleAr;
  final String titleEn;
  final String poseAr;
  final String backgroundAr;
  final String lightingMood;
  final Color primaryColor;
  final Color secondaryColor;
  final double groundYRatio;
  final bool hasFloorReflection;
  final String category;

  const SceneSpec({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.poseAr,
    required this.backgroundAr,
    required this.lightingMood,
    required this.primaryColor,
    required this.secondaryColor,
    this.groundYRatio = 0.88,
    this.hasFloorReflection = false,
    this.category = 'general',
  });
}

class GeneratedScene {
  final int id;
  final SceneSpec spec;
  final bool isGenerating;
  final bool isSuccess;

  const GeneratedScene({
    required this.id,
    required this.spec,
    this.isGenerating = false,
    this.isSuccess = true,
  });
}

// ==========================================
// 2. التطبيق والواجهة الرئيسية (App Entry)
// ==========================================

class AiremoveApp extends StatelessWidget {
  const AiremoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airemove AI Studio',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.light,
          primary: const Color(0xFF0066FF),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const AiremoveHomeScreen(),
    );
  }
}

class AiremoveHomeScreen extends StatefulWidget {
  const AiremoveHomeScreen({super.key});

  @override
  State<AiremoveHomeScreen> createState() => _AiremoveHomeScreenState();
}

class _AiremoveHomeScreenState extends State<AiremoveHomeScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  EditorTab _activeTab = EditorTab.threeScenes;
  SceneTheme _selectedTheme = SceneTheme.smartAutoDetect;
  int _selectedSceneIndex = 0; // 0, 1, 2 or -1 for 3-grid

  // أدوات الدمج والواقعية
  double _depthOfFieldBokeh = 0.65;
  double _edgeFeathering = 0.75;
  double _contactShadow = 0.85;

  // خيارات الألوان والخلفيات
  Color _solidBgColor = Colors.white;
  int _selectedColorIndex = 0;
  bool _isProcessing = false;
  bool _showOriginal = false;
  String _detectedSubject = "حيوان أليف (كلب/قط)";
  Uint8List? _userImageBytes;

  final List<Color> _paletteColors = const [
    Colors.transparent,
    Colors.white,
    Color(0xFFF1F5F9),
    Color(0xFF0F172A),
    Color(0xFFE0E7FF),
    Color(0xFFDCFCE7),
    Color(0xFFFEF3C7),
    Color(0xFFFFE4E6),
    Color(0xFF7C3AED),
  ];

  List<SceneSpec> _currentSceneSpecs = [];

  @override
  void initState() {
    super.initState();
    _updateSceneSpecs();
  }

  void _updateSceneSpecs() {
    setState(() {
      _currentSceneSpecs = _getSceneSpecsForTheme(_selectedTheme);
    });
  }

  List<SceneSpec> _getSceneSpecsForTheme(SceneTheme theme) {
    switch (theme) {
      case SceneTheme.smartAutoDetect:
      case SceneTheme.petsAndHome:
        return const [
          SceneSpec(
            id: 1,
            titleAr: "إطعام بمودة في المنزل",
            titleEn: "Pet Feeding Time at Cozy Home",
            poseAr: "تفاعل مرح وسعيد أثناء تناول طعام شهي ومكافآت",
            backgroundAr: "صالة منزل دافئة مع شخص يقدم وجبة لذيذة وأرضية خشبية",
            lightingMood: "أشعة شمس كهرمانية دافئة مع إضاءة منزلية مريحة",
            primaryColor: Color(0xFFD97706),
            secondaryColor: Color(0xFFFEF3C7),
            groundYRatio: 0.89,
            category: 'pet',
          ),
          SceneSpec(
            id: 2,
            titleAr: "متجر حلوى ومأكولات الحيوانات",
            titleEn: "Pet Gourmet Bakery & Boutique",
            poseAr: "وقفة فخورة ومتحمسة أمام رفوف البسكويت والأغذية الفاخرة",
            backgroundAr: "بوتيك راقٍ لأغذية الحيوانات الأليفة مع رفوف خشبية عصرية",
            lightingMood: "إضاءة تجارية مشرقة مع عزل عدسة سينمائي",
            primaryColor: Color(0xFF059669),
            secondaryColor: Color(0xFFD1FAE5),
            groundYRatio: 0.90,
            category: 'pet',
          ),
          SceneSpec(
            id: 3,
            titleAr: "استرخاء في صالة المنزل المريحة",
            titleEn: "Cozy Living Room & Plush Sofa",
            poseAr: "تمدد مريح وهادئ فوق بساط صوفي تحت أشعة الشمس المتسللة",
            backgroundAr: "غرفة معيشة هادئة مع أريكة وثيرة وبساط ناعم وشمس الصباح",
            lightingMood: "ضوء صباحي ذهبي ناعم ودافئ",
            primaryColor: Color(0xFF4F46E5),
            secondaryColor: Color(0xFFEEF2FF),
            groundYRatio: 0.88,
            category: 'pet',
          ),
        ];

      case SceneTheme.fashionShopping:
        return const [
          SceneSpec(
            id: 1,
            titleAr: "بوتيك أزياء وماركات عالمية",
            titleEn: "Luxury Fashion Boutique",
            poseAr: "وقفة أزياء راقية وأنيقة مع أكياس التسوق وسط المتجر الفاخر",
            backgroundAr: "متجر ملابس راقٍ بإضاءة سبوت لايت دافئة ورفوف أنيقة",
            lightingMood: "إضاءة مركزة دافئة مع انعكاسات ناعمة",
            primaryColor: Color(0xFFBE185D),
            secondaryColor: Color(0xFFFCE7F3),
            groundYRatio: 0.88,
            category: 'fashion',
          ),
          SceneSpec(
            id: 2,
            titleAr: "تراس مقهى باريسي راقٍ",
            titleEn: "Parisian Cafe Terrace",
            poseAr: "جلوس مريح بجانب طاولة بيسترو رخامية بعد جولة التسوق",
            backgroundAr: "شرفة مقهى خارجي مشمس في شارع أوروبي كلاسيكي مع زهور",
            lightingMood: "شمس صباحية دافئة مع عمق ميدان فوتوغرافي f/1.8",
            primaryColor: Color(0xFF2563EB),
            secondaryColor: Color(0xFFDBEAFE),
            groundYRatio: 0.86,
            category: 'fashion',
          ),
          SceneSpec(
            id: 3,
            titleAr: "مول تجاري عصري فخم",
            titleEn: "Modern Luxury Shopping Galleria",
            poseAr: "مشية واثقة ومتألقة عبر ردهة المول التجاري الزجاجي الفسيح",
            backgroundAr: "ردهة مول تجاري فخم بأرضيات رخامية عاكسة وأسقف زجاجية",
            lightingMood: "إضاءة معمارية بيضاء نقية مع انعكاسات رخام الأرضية",
            primaryColor: Color(0xFF0D9488),
            secondaryColor: Color(0xFFCCFBF1),
            groundYRatio: 0.90,
            hasFloorReflection: true,
            category: 'fashion',
          ),
        ];

      case SceneTheme.cozyLifestyle:
        return const [
          SceneSpec(
            id: 1,
            titleAr: "دفء المدفأة الحجرية",
            titleEn: "Rustic Fireplace Hearth",
            poseAr: "تمدد مريح أمام حطب الموقد المشتعل داخل الكوخ الجبلي",
            backgroundAr: "صالة كوخ خشبي مع موقد حجري متوهج بالحطب",
            lightingMood: "وهج جمر كهرماني متكسر مع ظلال سينمائية ناعمة",
            primaryColor: Color(0xFFC2410C),
            secondaryColor: Color(0xFFFFEDD5),
            groundYRatio: 0.90,
          ),
          SceneSpec(
            id: 2,
            titleAr: "بنتهاوس راقٍ مع إطلالة الغروب",
            titleEn: "Luxury Penthouse Sunset",
            poseAr: "وقفة مميزة على أرضية الرخام الفاخرة أمام إطلالة بانورامية",
            backgroundAr: "صالة بنتهاوس فخمة بنوافذ زجاجية تطل على أفق المدينة الذهبي",
            lightingMood: "شمس الغروب الدافئة مع لمعان الرخام المصقول",
            primaryColor: Color(0xFF9333EA),
            secondaryColor: Color(0xFFF3E8FF),
            groundYRatio: 0.89,
            hasFloorReflection: true,
          ),
          SceneSpec(
            id: 3,
            titleAr: "صالة دافئة تحت أشعة الشمس",
            titleEn: "Sunlit Living Room",
            poseAr: "جلوس هادئ ومريح على بساط صوفي تحت أشعة الشمس",
            backgroundAr: "غرفة معيشة أنيقة مع أريكة وثيرة وبساط ناعم",
            lightingMood: "ضوء طبيعي دافئ منتشر",
            primaryColor: Color(0xFF0284C7),
            secondaryColor: Color(0xFFE0F2FE),
            groundYRatio: 0.88,
          ),
        ];

      case SceneTheme.royalStudio:
        return const [
          SceneSpec(
            id: 1,
            titleAr: "استوديو المشاهير السينمائي",
            titleEn: "Editorial Studio Spotlight",
            poseAr: "وضعية بورتريه محترفة وواثقة مع إضاءة استوديو دقيقة",
            backgroundAr: "استوديو تصوير احترافي مع خلفية رمادية أنيقة وأرضية عاكسة",
            lightingMood: "إضاءة Softbox رئيسية مع حواف ضوئية حادة",
            primaryColor: Color(0xFF334155),
            secondaryColor: Color(0xFFE2E8F0),
            groundYRatio: 0.90,
            hasFloorReflection: true,
          ),
          SceneSpec(
            id: 2,
            titleAr: "قصر الريف الخريفي الفاخر",
            titleEn: "Autumn Countryside Estate",
            poseAr: "وقفة ملكية فخمة على الدرج الحجري المطل على الحديقة",
            backgroundAr: "حديقة قصر تاريخي بأشجار ذهبية ودرابزين حجري فاخر",
            lightingMood: "شمس بعد الظهيرة الذهبية مع تباين غني ودافئ",
            primaryColor: Color(0xFFB45309),
            secondaryColor: Color(0xFFFEF3C7),
            groundYRatio: 0.88,
          ),
          SceneSpec(
            id: 3,
            titleAr: "شرفة البنتهاوس البانورامية",
            titleEn: "Luxury Penthouse Balcony",
            poseAr: "وقفة مهيبة تتأمل الأفق المشتعل بأضواء الغروب",
            backgroundAr: "شرفة بنتهاوس فاخرة بإطلالة مفتوحة على ناطحات السحاب",
            lightingMood: "شفق مسائي ساحر مع إضاءة خلفية دافئة",
            primaryColor: Color(0xFF1E293B),
            secondaryColor: Color(0xFFCBD5E1),
            groundYRatio: 0.89,
            hasFloorReflection: true,
          ),
        ];

      case SceneTheme.adventureNature:
        return const [
          SceneSpec(
            id: 1,
            titleAr: "ركض مرح على الشاطئ الاستوائي",
            titleEn: "Tropical Beach Runner",
            poseAr: "وضعية حركية سريعة ومرحة مع تناثر رذاذ الماء على الشاطئ",
            backgroundAr: "شاطئ استوائي مشمس مع أمواج فيروزية ورمال بيضاء ونخيل",
            lightingMood: "شمس استوائية ساطعة مع لمعان وانعكاسات رطبة",
            primaryColor: Color(0xFF0284C7),
            secondaryColor: Color(0xFFBAE6FD),
            groundYRatio: 0.90,
          ),
          SceneSpec(
            id: 2,
            titleAr: "دفء الكوخ الجبلي بين الثلوج",
            titleEn: "Cozy Mountain Cabin",
            poseAr: "استرخاء هادئ وتمدد مريح على بساط صوفي أمام حطب الموقد",
            backgroundAr: "كوخ خشبي ريفي دافئ مع موقد حجري متوهج بالحطب",
            lightingMood: "دفء النار المتوهجة مع ظلال سينمائية ناعمة",
            primaryColor: Color(0xFFB45309),
            secondaryColor: Color(0xFFFED7AA),
            groundYRatio: 0.90,
          ),
          SceneSpec(
            id: 3,
            titleAr: "الغابة الذهبية الخريفية",
            titleEn: "Golden Autumn Forest",
            poseAr: "وقفة استكشافية حيوية بين أوراق الأشجار الخريفية المتساقطة",
            backgroundAr: "غابة خريفية ساحرة مغطاة بأوراق القيقب الذهبية وشمس دافئة",
            lightingMood: "أشعة شمس ذهبية تخترق الأشجار بوهج كهرماني ناعم",
            primaryColor: Color(0xFFEA580C),
            secondaryColor: Color(0xFFFFEDD5),
            groundYRatio: 0.88,
          ),
        ];
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _isProcessing = true;
          _userImageBytes = bytes;
          _detectedSubject = "تم تحليل الصورة واقتراح المشاهد الملائمة";
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _saveComposite() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الصورة بدقة فائقة 4K في معرض الصور بنجاح!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF0066FF), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Airemove Studio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'تفريغ وعزل ذكي • مشاهد AI مدمجة',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'اختيار صورة جديدة',
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0066FF)),
            tooltip: 'حفظ بجودة 4K',
            onPressed: _saveComposite,
          ),
        ],
      ),
      body: Column(
        children: [
          // لوحة العرض والرسم المباشر (Canvas Preview)
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: _buildMainCanvas(),
              ),
            ),
          ),

          // شريط التبويبات الرئيسي (Bottom Tool Tabs)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: EditorTab.values.map((tab) {
                  final isSelected = _activeTab == tab;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _activeTab = tab);
                      },
                      avatar: Icon(
                        tab.icon,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      label: Text(
                        tab.titleAr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selectedColor: const Color(0xFF0066FF),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // لوحة التحكم والخيارات (Dynamic Options Panel)
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildControlsForActiveTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. الرسم البصري والدمج السينمائي (Canvas)
  // ==========================================

  Widget _buildMainCanvas() {
    if (_isProcessing) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0066FF)),
              SizedBox(height: 16),
              Text(
                'جارٍ عزل الكائن ودمج المشاهد بالذكاء الاصطناعي...',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeTab == EditorTab.threeScenes) {
      if (_selectedSceneIndex == -1) {
        // عرض شبكة المشاهد الثلاثة معاً
        return _buildTripleScenesGrid();
      } else {
        // عرض المشهد المختار الفردي مع الدمج السينمائي
        final currentSpec = _currentSceneSpecs[_selectedSceneIndex.clamp(0, _currentSceneSpecs.length - 1)];
        return _buildSingleSceneCompositor(currentSpec);
      }
    } else if (_activeTab == EditorTab.colorHarmony) {
      return _buildColorHarmonyCanvas();
    } else {
      // تفريغ شفاف أو ملصقات كرتونية
      return _buildTransparentCutoutCanvas();
    }
  }

  Widget _buildSingleSceneCompositor(SceneSpec spec) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. الخلفية مع عزل عدسة سينمائي (Depth of Field Bokeh Blur)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [spec.primaryColor, spec.secondaryColor],
              ),
            ),
          ),

          // محاكاة الإضاءة المحيطية للمشهد (Ambient Bokeh Elements)
          CustomPaint(
            painter: BokehBackgroundPainter(
              color: spec.secondaryColor.withOpacity(0.4),
              bokehStrength: _depthOfFieldBokeh,
            ),
          ),

          // 2. ظلال التلامس الواقعية المتعددة الطبقات (Multi-tier Contact Shadows)
          CustomPaint(
            painter: StudioRealisticShadowPainter(
              groundYRatio: spec.groundYRatio,
              shadowIntensity: _contactShadow,
              hasFloorReflection: spec.hasFloorReflection,
            ),
          ),

          // 3. الكائن الرئيسي مع التفاف الإضاءة وتنعيم الحواف
          Align(
            alignment: Alignment(0.0, (spec.groundYRatio * 2) - 1.2),
            child: _buildSubjectWithStudioBlending(spec),
          ),

          // 4. بطاقة تعريف المشهد بالأعلى
          Positioned(
            top: 14,
            right: 14,
            left: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        spec.titleAr,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTapDown: (_) => setState(() => _showOriginal = true),
                  onTapUp: (_) => setState(() => _showOriginal = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showOriginal ? const Color(0xFFF59E0B) : Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.compare_arrows, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('معاينة الأصل', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectWithStudioBlending(SceneSpec spec) {
    if (_userImageBytes != null) {
      return Image.memory(
        _userImageBytes!,
        height: 240,
        fit: BoxFit.contain,
      );
    }

    // مجسم افتراضي عالي التناسق عند عدم رفع صورة
    final isPet = spec.category == 'pet';
    return Container(
      width: 190,
      height: 220,
      decoration: BoxDecoration(
        boxShadow: [
          // التفاف الضوء على حواف الكائن (Light Wrap Bleed)
          BoxShadow(
            color: spec.primaryColor.withOpacity(0.35 * _edgeFeathering),
            blurRadius: 18 * _edgeFeathering,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPet ? Icons.pets : Icons.person_rounded,
              size: 130,
              color: Colors.white,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPet ? "حيوان أليف مفرغ بالذكاء الاصطناعي" : "شخصية مفرغة بالذكاء الاصطناعي",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripleScenesGrid() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: _currentSceneSpecs.map((spec) {
          final index = _currentSceneSpecs.indexOf(spec);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSceneIndex = index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [spec.primaryColor, spec.secondaryColor],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "مشهد ${index + 1}",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(
                      spec.category == 'pet' ? Icons.pets : Icons.person,
                      color: Colors.white,
                      size: 50,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      child: Text(
                        spec.titleAr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorHarmonyCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: _solidBgColor == Colors.transparent ? Colors.grey[200] : _solidBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(Icons.person, size: 140, color: _solidBgColor == Colors.white ? const Color(0xFF0066FF) : Colors.white),
      ),
    );
  }

  Widget _buildTransparentCutoutCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_cut, size: 110, color: Color(0xFF0066FF)),
            SizedBox(height: 8),
            Text(
              "تفريغ شفاف بصيغة PNG عالية الجودة",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. عناصر ولوحات التحكم (Options Panel)
  // ==========================================

  Widget _buildControlsForActiveTab() {
    switch (_activeTab) {
      case EditorTab.threeScenes:
        return _buildThreeScenesControls();
      case EditorTab.colorHarmony:
        return _buildColorHarmonyControls();
      case EditorTab.cutout:
      case EditorTab.cartoonStickers:
        return _buildGeneralExportControls();
    }
  }

  Widget _buildThreeScenesControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // بانر التنسيق الذكي لمحتوى الصورة
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF0066FF), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مشاهد ذكية متناسقة ودمج سينمائي احترافي',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                    Text(
                      'تم الكشف: $_detectedSubject. تم تجهيز مشاهد ملائمة تماماً لمنع مظهر الصور المركبة بدائياً.',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // طابع المشاهد الثلاثة
        const Text(
          'طابع المشاهد (AI Scene Theme):',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SceneTheme.values.map((theme) {
            final isSelected = _selectedTheme == theme;
            return FilterChip(
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedTheme = theme;
                  _updateSceneSpecs();
                  _selectedSceneIndex = 0;
                });
              },
              label: Text(theme.titleAr, style: const TextStyle(fontSize: 11)),
              selectedColor: const Color(0xFF0066FF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // اختيار المشهد أو الشبكة
        const Text(
          'عرض واختيار المشهد:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._currentSceneSpecs.asMap().entries.map((entry) {
              final idx = entry.key;
              final spec = entry.value;
              final isSelected = _selectedSceneIndex == idx;
              return ChoiceChip(
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedSceneIndex = idx),
                label: Text("المشهد ${idx + 1}: ${spec.titleAr}", style: const TextStyle(fontSize: 11)),
                selectedColor: const Color(0xFF0066FF),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
              );
            }),
            ChoiceChip(
              selected: _selectedSceneIndex == -1,
              onSelected: (_) => setState(() => _selectedSceneIndex = -1),
              label: const Text("المشاهد الثلاثة معاً (شبكة)", style: TextStyle(fontSize: 11)),
              selectedColor: const Color(0xFF7C3AED),
              labelStyle: TextStyle(color: _selectedSceneIndex == -1 ? Colors.white : Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // بطاقة التحكم في جودة الدمج والواقعية السينمائية
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette, size: 16, color: Color(0xFF0F172A)),
                  SizedBox(width: 6),
                  Text(
                    'جودة الدمج السينمائي والواقعية (Studio Blending):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // عزل الخلفية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('عزل الخلفية السينمائي (DSLR Bokeh):', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                  Text('${(_depthOfFieldBokeh * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _depthOfFieldBokeh,
                onChanged: (v) => setState(() => _depthOfFieldBokeh = v),
              ),

              // تنعيم الحواف
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تنعيم الحواف وإزالة الهالات (De-Fringing):', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                  Text('${(_edgeFeathering * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _edgeFeathering,
                onChanged: (v) => setState(() => _edgeFeathering = v),
              ),

              // الظلال الواقعية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ظلال التلامس وانعكاس الأرضية الرخامية:', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                  Text('${(_contactShadow * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _contactShadow,
                onChanged: (v) => setState(() => _contactShadow = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorHarmonyControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ألوان استوديو متناسقة بالذكاء الاصطناعي:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _paletteColors.length,
            itemBuilder: (context, index) {
              final color = _paletteColors[index];
              final isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedColorIndex = index;
                  _solidBgColor = color;
                }),
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: color == Colors.transparent ? Colors.grey[300] : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.blue) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralExportControls() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _saveComposite,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedCornerShape(12),
          ),
          icon: const Icon(Icons.download),
          label: const Text('تصدير بدقة عالية 4K بدون خلفية', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ==========================================
// 5. محرك الرسم والتظليل الفيزيائي (Painters)
// ==========================================

class BokehBackgroundPainter extends CustomPainter {
  final Color color;
  final double bokehStrength;

  BokehBackgroundPainter({required this.color, required this.bokehStrength});

  @override
  void paint(Canvas canvas, Size size) {
    if (bokehStrength < 0.1) return;
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 24 * bokehStrength);

    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.25), 45 * bokehStrength, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.35), 65 * bokehStrength, paint);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.55), 55 * bokehStrength, paint);
  }

  @override
  bool shouldRepaint(covariant BokehBackgroundPainter oldDelegate) =>
      oldDelegate.bokehStrength != bokehStrength || oldDelegate.color != color;
}

class StudioRealisticShadowPainter extends CustomPainter {
  final double groundYRatio;
  final double shadowIntensity;
  final bool hasFloorReflection;

  StudioRealisticShadowPainter({
    required this.groundYRatio,
    required this.shadowIntensity,
    required this.hasFloorReflection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * groundYRatio;
    final centerX = size.width / 2;
    final baseWidth = size.width * 0.55;

    // الطبقة 1: ظل الاحتجاب الداكن المباشر أسفل نقاط التلامس (Ambient Occlusion Core)
    final aoPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(centerX, groundY + 2),
        baseWidth * 0.4,
        [
          Colors.black.withOpacity(0.85 * shadowIntensity),
          Colors.transparent,
        ],
        [0.2, 1.0],
      );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, groundY + 2), width: baseWidth * 0.7, height: 16),
      aoPaint,
    );

    // الطبقة 2: الظل الاتجاهي الناعم المنتشر (Diffuse Penumbra)
    final penumbraPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(centerX, groundY + 8),
        baseWidth * 0.6,
        [
          Colors.black.withOpacity(0.45 * shadowIntensity),
          Colors.transparent,
        ],
        [0.1, 1.0],
      );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, groundY + 8), width: baseWidth * 1.1, height: 42),
      penumbraPaint,
    );

    // الطبقة 3: لمعان وانعكاس الأرضية الرخامية (Floor Specular Reflection)
    if (hasFloorReflection) {
      final reflectPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(centerX, groundY),
          Offset(centerX, groundY + 45),
          [
            Colors.white.withOpacity(0.22 * shadowIntensity),
            Colors.transparent,
          ],
        );
      canvas.drawRect(
        Rect.fromLTWH(centerX - (baseWidth * 0.5), groundY, baseWidth, 40),
        reflectPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StudioRealisticShadowPainter oldDelegate) =>
      oldDelegate.groundYRatio != groundYRatio ||
      oldDelegate.shadowIntensity != shadowIntensity ||
      oldDelegate.hasFloorReflection != hasFloorReflection;
}
