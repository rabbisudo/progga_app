import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'profile_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/avatar/progga_avatar_engine.dart';
import '../../../core/widgets/progga_animated_avatar.dart';

class AvatarEditorScreen extends ConsumerStatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  ConsumerState<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends ConsumerState<AvatarEditorScreen> with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  bool _isInitialized = false;

  // Scroll and Tab synchronization variables (9 sections)
  late ScrollController _scrollController;
  late TabController _tabController;
  final List<GlobalKey> _sectionKeys = List.generate(9, (_) => GlobalKey());
  bool _isAutoScrolling = false;

  // Selected avatar options
  String _selectedFaceShape = 'chiseledSquare';
  String _selectedHair = 'modernQuiff';
  String _selectedHairColor = '1b203a';
  String _selectedHat = 'none';
  String _selectedHatColor = '262e33';
  String _selectedEyes = 'confident';
  String _selectedEyebrows = 'default';
  String _selectedMouth = 'smirk';
  String _selectedSkinColor = 'ffdbb4';
  String _selectedClothing = 'shirtCrewNeck';
  String _selectedClothingColor = '86198f';
  String _selectedGlasses = 'rectShades';
  String _selectedGlassesColor = '18181b';
  String _selectedAccessories = 'none';
  String _selectedAccessoriesColor = '18181b';
  String _selectedBeard = 'none';
  String _selectedBeardColor = '1b203a';
  String _selectedMoustache = 'none';
  String _selectedMoustacheColor = '1b203a';
  String _selectedBgColor = 'd8b4fe';
  String _selectedBgStyle = 'cloud';

  // Face Shape Options
  final List<Map<String, String>> _faceShapeOptions = [
    {'id': 'chiseledSquare', 'name': 'শার্প স্কয়ার জ'},
    {'id': 'slenderOval', 'name': 'স্লিম ওভাল / ভি-লাইন'},
    {'id': 'softRound', 'name': 'সফট রাউন্ড'},
    {'id': 'diamondSharp', 'name': 'ডায়মন্ড কাট'},
  ];

  // Option lists with descriptions (Separated Hair and Hats!)
  final List<Map<String, String>> _hairOptions = [
    {'id': 'modernQuiff', 'name': 'মডার্ন কুইফ'},
    {'id': 'sideChignon', 'name': 'সাইড খোঁপা'},
    {'id': 'bald', 'name': 'নেড়া মাথা'},
    {'id': 'shortFlat', 'name': 'সাইড পার্ট'},
    {'id': 'shortRound', 'name': 'মাঝখানে সিঁথি'},
    {'id': 'theCaesar', 'name': 'সিজার কাট'},
    {'id': 'shortCurly', 'name': 'কোঁকড়া ছোট'},
    {'id': 'frizzle', 'name': 'ফক্স হক / স্ট্রাইক'},
    {'id': 'shavedSides', 'name': 'ফেড কাট'},
    {'id': 'shaggy', 'name': 'পম্পাডোর'},
    {'id': 'shortWaved', 'name': 'ঢেউ খেলানো'},
    {'id': 'theCaesarAndSidePart', 'name': 'স্পাইক কাট'},
    {'id': 'bob', 'name': 'বব কাট'},
    {'id': 'bun', 'name': 'টপ নট / খোঁপা'},
    {'id': 'curly', 'name': 'কোঁকড়া লম্বা'},
    {'id': 'curvy', 'name': 'ঢেউ খেলানো লম্বা'},
    {'id': 'fro', 'name': 'আফ্রো'},
  ];

  final List<Map<String, String>> _hatOptions = [
    {'id': 'none', 'name': 'টুপি ছাড়া'},
    {'id': 'cap', 'name': 'বেসবল ক্যাপ'},
    {'id': 'snapback', 'name': 'স্ন্যাপব্যাক ক্যাপ'},
    {'id': 'helmetMoto', 'name': 'রেসিং হেলমেট'},
    {'id': 'helmetSkate', 'name': 'স্কেট হেলমেট'},
    {'id': 'beanie', 'name': 'শীতের বিনি টুপি'},
    {'id': 'beaniePom', 'name': 'পম-পম বিনি'},
    {'id': 'bucketHat', 'name': 'ট্রেন্ডি বাকেট হ্যাট'},
    {'id': 'fedora', 'name': 'ক্লাসিক ফেডোরা'},
    {'id': 'beret', 'name': 'ফ্রেঞ্চ বেরেট'},
    {'id': 'hijab', 'name': 'মার্জিত হিজাব'},
    {'id': 'turban', 'name': 'রয়্যাল পাগড়ি'},
    {'id': 'headband', 'name': 'স্পোর্টস হেডব্যান্ড'},
    {'id': 'bandana', 'name': 'স্টাইলিশ ব্যান্ডানা'},
    {'id': 'kufi', 'name': 'ইসলামিক কুফি টুপি'},
    {'id': 'cowboy', 'name': 'ওয়েস্টার্ন কাউবয় হ্যাট'},
  ];

  final List<Map<String, String>> _eyeOptions = [
    {'id': 'confident', 'name': 'আত্মবিশ্বাসী'},
    {'id': 'intense', 'name': 'তীক্ষ্ণ দৃষ্টি'},
    {'id': 'default', 'name': 'স্বাভাবিক'},
    {'id': 'happy', 'name': 'হাসিখুশি'},
    {'id': 'wink', 'name': 'চোখ টেপা'},
    {'id': 'surprised', 'name': 'অবাক'},
    {'id': 'eyeRoll', 'name': 'বিরক্ত ভাব'},
    {'id': 'sparkle', 'name': 'উজ্জ্বল তারা'},
    {'id': 'cool', 'name': 'কুল ভাব'},
    {'id': 'sleepy', 'name': 'ঘুম ঘুম / ক্লান্ত'},
    {'id': 'cryingJoy', 'name': 'আনন্দের অশ্রু'},
  ];

  final List<Map<String, String>> _eyebrowOptions = [
    {'id': 'default', 'name': 'স্বাভাবিক'},
    {'id': 'angryFierce', 'name': 'তীক্ষ্ণ রাগী'},
    {'id': 'determined', 'name': 'দৃঢ়প্রতিজ্ঞ'},
    {'id': 'raisedExcited', 'name': 'উত্তেজিত'},
  ];

  final List<Map<String, String>> _mouthOptions = [
    {'id': 'smirk', 'name': 'মুচকি হাসি'},
    {'id': 'smileTeeth', 'name': 'উজ্জ্বল হাসি'},
    {'id': 'grit', 'name': 'দাঁত কিড়মিড়'},
    {'id': 'smile', 'name': 'স্বাভাবিক হাসি'},
    {'id': 'twinkle', 'name': 'ঝিলিক'},
    {'id': 'default', 'name': 'স্বাভাবিক'},
    {'id': 'eating', 'name': 'খাচ্ছে'},
    {'id': 'concerned', 'name': 'চিন্তিত'},
  ];

  final List<Map<String, String>> _clothingOptions = [
    {'id': 'shirtCrewNeck', 'name': 'গোল গলা টিশার্ট'},
    {'id': 'shirtScoopNeck', 'name': 'স্কুপ নেক টপ'},
    {'id': 'hoodie', 'name': 'হুডি'},
    {'id': 'blazerAndShirt', 'name': 'ব্লেজার ও শার্ট'},
    {'id': 'collarAndSweater', 'name': 'কলার ও সোয়েটার'},
    {'id': 'graphicShirt', 'name': 'গ্রাফিক শার্ট'},
  ];

  // Dedicated high-definition Glasses Styles
  final List<Map<String, String>> _glassesOptions = [
    {'id': 'none', 'name': 'চশমা ছাড়া'},
    {'id': 'roundWire', 'name': 'রাউন্ড ওয়্যারফ্রেম'},
    {'id': 'wayfarers', 'name': 'ক্লাসিক ওয়েফেয়ারার'},
    {'id': 'clubmaster', 'name': 'ক্লাবমাস্টার ব্রো-লাইন'},
    {'id': 'aviator', 'name': 'এভিয়েটর পাইলট'},
    {'id': 'catEye', 'name': 'ভিন্টেজ ক্যাট-আই'},
    {'id': 'rectOptical', 'name': 'রেক্ট্যাঙ্গেল অপটিক্যাল'},
    {'id': 'rectShades', 'name': 'ডার্ক শেডস'},
    {'id': 'hexagonal', 'name': 'হেক্সাগোনাল ওয়্যার'},
    {'id': 'roundShades', 'name': 'ডার্ক রাউন্ড শেডস'},
    {'id': 'cyberVisor', 'name': 'সাইবারপঙ্ক ভাইজর'},
    {'id': 'halfRim', 'name': 'সেমি-রিমলেস'},
  ];

  // Headgear & Jewelry Accessories
  final List<Map<String, String>> _accessoriesOptions = [
    {'id': 'none', 'name': 'কিছু ছাড়া'},
    {'id': 'headphones', 'name': 'স্টুডিও হেডফোন'},
    {'id': 'hoopEarrings', 'name': 'গোল দুল (হুপ)'},
    {'id': 'studEarrings', 'name': 'টপ দুল (স্টাড)'},
    {'id': 'bindi', 'name': 'কপালের টিপ'},
  ];

  final List<Map<String, String>> _beardOptions = [
    {'id': 'none', 'name': 'দাড়ি ছাড়া'},
    {'id': 'stubble', 'name': 'খোঁচা দাড়ি'},
    {'id': 'chinStrap', 'name': 'চিনস্ট্র্যাপ'},
    {'id': 'goatee', 'name': 'গোটি'},
    {'id': 'beardMedium', 'name': 'মাঝারি দাড়ি'},
    {'id': 'beardMajestic', 'name': 'ঘন দাড়ি'},
    {'id': 'anchor', 'name': 'অ্যাঙ্কর দাড়ি'},
  ];

  final List<Map<String, String>> _moustacheOptions = [
    {'id': 'none', 'name': 'গোঁফ ছাড়া'},
    {'id': 'pencil', 'name': 'পেন্সিল গোঁফ'},
    {'id': 'classic', 'name': 'ক্লাসিক গোঁফ'},
    {'id': 'handlebar', 'name': 'হ্যান্ডেলবার'},
    {'id': 'chevron', 'name': 'শেভরন'},
    {'id': 'horseshoe', 'name': 'হর্সশু'},
  ];

  final List<Map<String, String>> _bgStyleOptions = [
    {'id': 'cloud', 'name': 'ক্লাউড ব্যাজ'},
    {'id': 'circle', 'name': 'বৃত্তাকার'},
    {'id': 'squircle', 'name': 'স্কয়ার্কেল'},
  ];

  // Hex Colors
  final List<String> _hairColors = [
    '1b203a', '6d381c', '2c1b18', '4a312c', '724133', 'a55728', 'b58143', '1a1a1a', 'e8e1e1'
  ];

  final List<String> _hatColors = [
    '262e33', '25557c', '86198f', '086057', '1d4ed8', 'ff5c5c', 'f59e0b', 'ffffff', '1a1a1a', '7f1d1d', '064e3b', 'b45309'
  ];

  final List<String> _skinColors = [
    'ffdbb4', 'edb98a', 'fde047', 'ffedd5', 'fed7aa', 'fd9841', 'd08b5b', 'ae5d29'
  ];

  final List<String> _clothingColors = [
    '86198f', '1d4ed8', '9333ea', '086057', '25557c', '5199e4', 'ff5c5c', '262e33', 'e6e6e6', 'ffffff'
  ];

  final List<String> _glassesColors = [
    '18181b', 'd4af37', 'a8a29e', 'b58143', 'ef4444', '2563eb', '10b981', '7c3aed', 'ffffff'
  ];

  final List<String> _accessoriesColors = [
    '18181b', '086057', 'f59e0b', 'ef4444', 'c026d3', '2563eb', '10b981', 'b58143', '262e33'
  ];

  final List<String> _bgColors = [
    'd8b4fe', 'fdba74', '2dd4bf', '7dd3fc', 'f472b6', '34d399', '086057', '6366f1', '1e293b', 'ffffff'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 9, vsync: this);
    
    _scrollController.addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _tabController.removeListener(_onTabChanged);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final profileState = ref.read(userProfileProvider);
      profileState.whenData((userData) {
        final avatarUrl = userData.profile?.avatarKey;
        if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
          _parseAvatarUrl(avatarUrl);
        }
      });
      _isInitialized = true;
    }
  }

  void _onScroll() {
    if (_isAutoScrolling) return;

    int activeIndex = 0;
    double closestDiff = double.infinity;
    const targetY = 420.0;

    for (int i = 0; i < 9; i++) {
      final context = _sectionKeys[i].currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final diff = (position.dy - targetY).abs();
          if (diff < closestDiff) {
            closestDiff = diff;
            activeIndex = i;
          }
        }
      }
    }

    if (activeIndex != _tabController.index) {
      _isAutoScrolling = true;
      _tabController.animateTo(
        activeIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        _isAutoScrolling = false;
      });
    }
  }

  void _onTabChanged() {
    if (_isAutoScrolling) return;
    if (_tabController.indexIsChanging) {
      _scrollToSection(_tabController.index);
    }
  }

  void _scrollToSection(int index) async {
    _isAutoScrolling = true;
    
    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }

    await Future.delayed(const Duration(milliseconds: 150));
    _isAutoScrolling = false;
  }

  ProggaAvatarConfig get _currentConfig => ProggaAvatarConfig(
    faceShape: _selectedFaceShape,
    hair: _selectedHair,
    hairColor: _selectedHairColor,
    hat: _selectedHat,
    hatColor: _selectedHatColor,
    skinColor: _selectedSkinColor,
    eyes: _selectedEyes,
    eyebrows: _selectedEyebrows,
    mouth: _selectedMouth,
    clothing: _selectedClothing,
    clothingColor: _selectedClothingColor,
    glasses: _selectedGlasses,
    glassesColor: _selectedGlassesColor,
    accessories: _selectedAccessories,
    accessoriesColor: _selectedAccessoriesColor,
    beard: _selectedBeard,
    beardColor: _selectedBeardColor,
    moustache: _selectedMoustache,
    moustacheColor: _selectedMoustacheColor,
    bgColor: _selectedBgColor,
    bgStyle: _selectedBgStyle,
  );

  String get _avatarUrl => _currentConfig.toProggaKey();

  void _applyPreset(ProggaAvatarConfig config) {
    setState(() {
      _selectedFaceShape = config.faceShape;
      _selectedHair = config.hair;
      _selectedHairColor = config.hairColor;
      _selectedHat = config.hat;
      _selectedHatColor = config.hatColor;
      _selectedSkinColor = config.skinColor;
      _selectedEyes = config.eyes;
      _selectedEyebrows = config.eyebrows;
      _selectedMouth = config.mouth;
      _selectedClothing = config.clothing;
      _selectedClothingColor = config.clothingColor;
      _selectedGlasses = config.glasses;
      _selectedGlassesColor = config.glassesColor;
      _selectedAccessories = config.accessories;
      _selectedAccessoriesColor = config.accessoriesColor;
      _selectedBeard = config.beard;
      _selectedBeardColor = config.beardColor;
      _selectedMoustache = config.moustache;
      _selectedMoustacheColor = config.moustacheColor;
      _selectedBgColor = config.bgColor;
      _selectedBgStyle = config.bgStyle;
    });
  }

  void _parseAvatarUrl(String url) {
    try {
      final config = ProggaAvatarConfig.fromKey(url);
      _applyPreset(config);
    } catch (_) {}
  }

  void _showPresetsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'স্পেশাল চরিত্র প্রিসেট',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _applyPreset(ProggaAvatarConfig.random());
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('র‍্যান্ডম'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 175,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ProggaAvatarConfig.presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (ctx, i) {
                      final p = ProggaAvatarConfig.presets[i];
                      final config = p['config'] as ProggaAvatarConfig;
                      return GestureDetector(
                        onTap: () {
                          _applyPreset(config);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          width: 125,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF086057).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ProggaAnimatedAvatar(
                                config: config,
                                radius: 36,
                                isAnimated: false,
                                isCircle: false,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'Li Ador Noirrit',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    try {
      final payload = {
        'avatarKey': _avatarUrl,
      };

      await ref.read(userProfileProvider.notifier).updateProfileDetails(payload);

      ref.invalidate(leaderboardProvider);
      ref.invalidate(practiceProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'অ্যাভাটার সফলভাবে সংরক্ষণ করা হয়েছে!',
              style: TextStyle(fontFamily: 'Li Ador Noirrit'),
            ),
            backgroundColor: Color(0xFF017A47),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'অ্যাভাটার সংরক্ষণ করা যায়নি: $e',
              style: const TextStyle(fontFamily: 'Li Ador Noirrit'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brandTealColor = Color(0xFF086057);
    final canvasBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F3FA);
    final topBarFgColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: canvasBg,
      body: Column(
        children: [
          // 1. Character Hero Canvas
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: double.infinity,
            color: canvasBg,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Custom App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomBackButton(
                            color: topBarFgColor,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Text(
                          'অ্যাভাটার কাস্টমাইজ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Li Ador Noirrit',
                            color: topBarFgColor,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.auto_awesome_rounded, color: topBarFgColor),
                            tooltip: 'প্রিসেট চরিত্র',
                            onPressed: _showPresetsModal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Character Area:
                  SizedBox(
                    height: 280,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: ProggaAnimatedAvatar(
                            config: _currentConfig,
                            radius: 135,
                            hasBg: true,
                            isCircle: false,
                            isAnimated: true,
                            showAura: false,
                          ),
                        ),
                        if (_isSaving)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.35),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Customization Sheet
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141A1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Sticky Tab Menu (7 separated tabs)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: brandTealColor,
                      indicatorWeight: 3.0,
                      labelColor: brandTealColor,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Li Ador Noirrit'),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13, fontFamily: 'Li Ador Noirrit'),
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: [
                        _buildTab('চুল', Icons.face_retouching_natural),
                        _buildTab('ফেস শেপ', Icons.face_rounded),
                        _buildTab('টুপি ও হেডওয়্যার', Icons.sports_baseball_rounded),
                        _buildTab('চোখ ও ভ্রু', Icons.visibility_rounded),
                        _buildTab('মুখ ও দাড়ি', Icons.sentiment_satisfied_alt_rounded),
                        _buildTab('পোশাক', Icons.checkroom_rounded),
                        _buildTab('চশমা', Icons.remove_red_eye_outlined),
                        _buildTab('এক্সেসরিজ', Icons.headset_rounded),
                        _buildTab('ব্যাকগ্রাউন্ড ও রঙ', Icons.palette_rounded),
                      ],
                    ),
                  ),

                  // 3. Vertically Scrollable Content Panel
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 0: Hair Only
                          _buildSectionHeader(0, 'চুল (Hairstyles)'),
                          const SizedBox(height: 12),
                          _buildHairGrid(),
                          const SizedBox(height: 16),
                          _buildColorRowTitle('চুলের রঙ (Hair Color)'),
                          const SizedBox(height: 8),
                          _buildColorRow(_hairColors, _selectedHairColor, (color) {
                            setState(() => _selectedHairColor = color);
                          }),
                          const SizedBox(height: 32),

                          // Section 1: Face Shape Structure
                          _buildSectionHeader(1, 'ফেসের গঠন (Face Shape)'),
                          const SizedBox(height: 12),
                          _buildFaceShapeGrid(),
                          const SizedBox(height: 32),

                          // Section 2: Hats & Headwear Only
                          _buildSectionHeader(2, 'টুপি ও হেডওয়্যার (Hats & Headwear)'),
                          const SizedBox(height: 12),
                          _buildHatGrid(),
                          const SizedBox(height: 16),
                          _buildColorRowTitle('টুপির রঙ (Hat Color)'),
                          const SizedBox(height: 8),
                          _buildColorRow(_hatColors, _selectedHatColor, (color) {
                            setState(() => _selectedHatColor = color);
                          }),
                          const SizedBox(height: 32),

                          // Section 3: Eyes & Brows
                          _buildSectionHeader(3, 'চোখ ও ভ্রু (Eyes & Brows)'),
                          const SizedBox(height: 12),
                          _buildSubTitle('চোখের ভঙ্গি (Eyes) • ${_getSelectedEyeName()}'),
                          const SizedBox(height: 8),
                          _buildEyesGrid(),
                          const SizedBox(height: 20),
                          _buildSubTitle('ভ্রু-র ডিজাইন (Eyebrows)'),
                          const SizedBox(height: 8),
                          _buildEyebrowsGrid(),
                          const SizedBox(height: 32),

                          // Section 4: Mouth, Beard & Moustache
                          _buildSectionHeader(4, 'মুখ, দাড়ি ও গোঁফ (Mouth, Beard & Moustache)'),
                          const SizedBox(height: 12),
                          _buildSubTitle('মুখের অভিব্যক্তি (Mouth Expression)'),
                          const SizedBox(height: 8),
                          _buildMouthGrid(),
                          const SizedBox(height: 24),

                          _buildSubTitle('দাড়ির স্টাইল (Beard Style)'),
                          const SizedBox(height: 8),
                          _buildBeardGrid(),
                          const SizedBox(height: 16),
                          _buildColorRowTitle('দাড়ির রঙ (Beard Color)'),
                          const SizedBox(height: 8),
                          _buildColorRow(_hairColors, _selectedBeardColor, (color) {
                            setState(() => _selectedBeardColor = color);
                          }),
                          const SizedBox(height: 24),

                          _buildSubTitle('গোঁফের স্টাইল (Moustache Style)'),
                          const SizedBox(height: 8),
                          _buildMoustacheGrid(),
                          const SizedBox(height: 16),
                          _buildColorRowTitle('গোঁফের রঙ (Moustache Color)'),
                          const SizedBox(height: 8),
                          _buildColorRow(_hairColors, _selectedMoustacheColor, (color) {
                            setState(() => _selectedMoustacheColor = color);
                          }),
                          const SizedBox(height: 32),

                          // Section 5: Clothing
                          _buildSectionHeader(5, 'পোশাক (Clothing Style)'),
                          const SizedBox(height: 12),
                          _buildClothingGrid(),
                          const SizedBox(height: 16),
                          _buildColorRowTitle('পোশাকের রঙ (Clothes Color)'),
                          const SizedBox(height: 8),
                          _buildColorRow(_clothingColors, _selectedClothingColor, (color) {
                            setState(() => _selectedClothingColor = color);
                          }),
                          const SizedBox(height: 32),

                          // Section 6: Glasses (Dedicated)
                          _buildSectionHeader(6, 'চশমা ও শেডস (Glasses & Shades)'),
                          const SizedBox(height: 12),
                          _buildGlassesGrid(),
                          const SizedBox(height: 16),
                          _buildColorRowTitle('চশমার ফ্রেমের রঙ (Frame Color)'),
                          const SizedBox(height: 8),
                          _buildColorRow(_glassesColors, _selectedGlassesColor, (color) {
                            setState(() => _selectedGlassesColor = color);
                          }),
                          const SizedBox(height: 32),

                          // Section 7: Accessories (Headphones & Jewelry)
                          _buildSectionHeader(7, 'এক্সেসরিজ ও হেডফোন (Accessories)'),
                          const SizedBox(height: 12),
                          _buildAccessoriesGrid(),
                          const SizedBox(height: 16),
                          _buildColorRowTitle('এক্সেসরিজের রঙ (Accessories Color)'),
                          const SizedBox(height: 8),
                          _buildColorRow(_accessoriesColors, _selectedAccessoriesColor, (color) {
                            setState(() => _selectedAccessoriesColor = color);
                          }),
                          const SizedBox(height: 32),

                          // Section 8: Colors & Backdrop
                          _buildSectionHeader(8, 'ব্যাকগ্রাউন্ড ও গায়ের রঙ (Backdrop & Skin)'),
                          const SizedBox(height: 16),
                          _buildColorsPanel(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAvatar,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandTealColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'সংরক্ষণ করুন',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTab(String title, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int index, String title) {
    const brandTealColor = Color(0xFF086057);

    return Container(
      key: _sectionKeys[index],
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: brandTealColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: brandTealColor.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: brandTealColor,
          fontFamily: 'Li Ador Noirrit',
        ),
      ),
    );
  }

  String _getSelectedEyeName() {
    final match = _eyeOptions.firstWhere(
      (e) => e['id'] == _selectedEyes,
      orElse: () => _eyeOptions.first,
    );
    return match['name'] ?? '';
  }

  Widget _buildSubTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
        fontFamily: 'Li Ador Noirrit',
      ),
    );
  }

  Widget _buildThumbnailCard({
    required String svgContent,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const selectedColor = Color(0xFF017A47);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E252B) : const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SvgPicture.string(
            svgContent,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFaceShapeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _faceShapeOptions.length,
      itemBuilder: (context, index) {
        final option = _faceShapeOptions[index];
        final isSelected = _selectedFaceShape == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildFaceShapeThumbnailSvg(
          faceShape: option['id']!,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedFaceShape = option['id']!),
        );
      },
    );
  }

  Widget _buildHairGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _hairOptions.length,
      itemBuilder: (context, index) {
        final option = _hairOptions[index];
        final isSelected = _selectedHair == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildHairThumbnailSvg(
          hairStyle: option['id']!,
          hairColor: _selectedHairColor,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedHair = option['id']!),
        );
      },
    );
  }

  Widget _buildHatGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _hatOptions.length,
      itemBuilder: (context, index) {
        final option = _hatOptions[index];
        final isSelected = _selectedHat == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildHatThumbnailSvg(
          hat: option['id']!,
          hatColor: _selectedHatColor,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedHat = option['id']!),
        );
      },
    );
  }

  Widget _buildEyesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _eyeOptions.length,
      itemBuilder: (context, index) {
        final option = _eyeOptions[index];
        final isSelected = _selectedEyes == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildEyesThumbnailSvg(
          eyeType: option['id']!,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedEyes = option['id']!),
        );
      },
    );
  }

  Widget _buildEyebrowsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _eyebrowOptions.length,
      itemBuilder: (context, index) {
        final option = _eyebrowOptions[index];
        final isSelected = _selectedEyebrows == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildEyebrowThumbnailSvg(
          eyebrowType: option['id']!,
          hairColor: _selectedHairColor,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedEyebrows = option['id']!),
        );
      },
    );
  }

  Widget _buildMouthGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _mouthOptions.length,
      itemBuilder: (context, index) {
        final option = _mouthOptions[index];
        final isSelected = _selectedMouth == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildMouthThumbnailSvg(
          mouthType: option['id']!,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedMouth = option['id']!),
        );
      },
    );
  }

  Widget _buildBeardGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _beardOptions.length,
      itemBuilder: (context, index) {
        final option = _beardOptions[index];
        final isSelected = _selectedBeard == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildBeardThumbnailSvg(
          beard: option['id']!,
          beardColor: _selectedBeardColor,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedBeard = option['id']!),
        );
      },
    );
  }

  Widget _buildMoustacheGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _moustacheOptions.length,
      itemBuilder: (context, index) {
        final option = _moustacheOptions[index];
        final isSelected = _selectedMoustache == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildMoustacheThumbnailSvg(
          moustache: option['id']!,
          moustacheColor: _selectedMoustacheColor,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedMoustache = option['id']!),
        );
      },
    );
  }

  Widget _buildClothingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _clothingOptions.length,
      itemBuilder: (context, index) {
        final option = _clothingOptions[index];
        final isSelected = _selectedClothing == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildClothingThumbnailSvg(
          clothing: option['id']!,
          clothingColor: _selectedClothingColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedClothing = option['id']!),
        );
      },
    );
  }

  Widget _buildGlassesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _glassesOptions.length,
      itemBuilder: (context, index) {
        final option = _glassesOptions[index];
        final isSelected = _selectedGlasses == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildGlassesThumbnailSvg(
          glasses: option['id']!,
          glassesColor: _selectedGlassesColor,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedGlasses = option['id']!),
        );
      },
    );
  }

  Widget _buildAccessoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _accessoriesOptions.length,
      itemBuilder: (context, index) {
        final option = _accessoriesOptions[index];
        final isSelected = _selectedAccessories == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildAccessoriesThumbnailSvg(
          accessory: option['id']!,
          accessoryColor: _selectedAccessoriesColor,
          skinColor: _selectedSkinColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedAccessories = option['id']!),
        );
      },
    );
  }

  Widget _buildColorsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColorRowTitle('ব্যাকগ্রাউন্ডের ধরন (Backdrop Shape)'),
        const SizedBox(height: 8),
        _buildBackdropStyleGrid(),
        const SizedBox(height: 20),
        _buildColorRowTitle('ব্যাকগ্রাউন্ডের রঙ (Backdrop Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_bgColors, _selectedBgColor, (color) {
          setState(() => _selectedBgColor = color);
        }),
        const Divider(height: 28),
        _buildColorRowTitle('গায়ের রঙ (Skin Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_skinColors, _selectedSkinColor, (color) {
          setState(() => _selectedSkinColor = color);
        }),
      ],
    );
  }

  Widget _buildBackdropStyleGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _bgStyleOptions.length,
      itemBuilder: (context, index) {
        final option = _bgStyleOptions[index];
        final isSelected = _selectedBgStyle == option['id'];
        final svg = ProggaAvatarSvgBuilder.buildBackdropThumbnailSvg(
          bgStyle: option['id']!,
          bgColor: _selectedBgColor,
        );
        return _buildThumbnailCard(
          svgContent: svg,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedBgStyle = option['id']!),
        );
      },
    );
  }

  Widget _buildColorRowTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
        fontFamily: 'Li Ador Noirrit',
      ),
    );
  }

  Widget _buildColorRow(List<String> hexColors, String selectedHex, Function(String) onSelected) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hexColors.length,
        itemBuilder: (context, index) {
          final hex = hexColors[index];
          final color = Color(int.parse('0xFF$hex'));
          final isSelected = selectedHex == hex;

          return GestureDetector(
            onTap: () => onSelected(hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 12),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF086057)
                      : (hex == 'ffffff' ? Colors.grey.shade400 : Colors.transparent),
                  width: isSelected ? 3.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF086057).withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
