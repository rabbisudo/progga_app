import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'profile_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';

class AvatarEditorScreen extends ConsumerStatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  ConsumerState<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends ConsumerState<AvatarEditorScreen> with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  bool _isInitialized = false;

  // Scroll and Tab synchronization variables
  late ScrollController _scrollController;
  late TabController _tabController;
  final List<GlobalKey> _sectionKeys = List.generate(6, (_) => GlobalKey());
  bool _isAutoScrolling = false;

  // Selected avatar options matching DiceBear avataaars schema
  String _selectedHair = 'shortFlat';
  String _selectedHairColor = '2c1b18';
  String _selectedHatColor = '262e33';
  String _selectedEyes = 'default';
  String _selectedEyebrows = 'default';
  String _selectedMouth = 'smile';
  String _selectedSkinColor = 'ffdbb4';
  String _selectedClothing = 'shirtCrewNeck';
  String _selectedClothingColor = '3c4f76';
  String _selectedAccessories = 'none';
  String _selectedAccessoriesColor = '262e33';
  String _selectedFacialHair = 'none';
  String _selectedFacialHairColor = '2c1b18';
  String _selectedBgColor = 'b1c9ef';

  // Option lists with descriptions
  final List<Map<String, String>> _hairOptions = [
    {'id': 'shortFlat', 'name': 'সোজা ছোট'},
    {'id': 'shortRound', 'name': 'গোল ছোট'},
    {'id': 'shortCurly', 'name': 'কোঁকড়া ছোট'},
    {'id': 'shortWaved', 'name': 'ঢেউ খেলানো ছোট'},
    {'id': 'shavedSides', 'name': 'সাইড ছাঁটা'},
    {'id': 'dreads', 'name': 'ড্রেইডলক'},
    {'id': 'dreads01', 'name': 'ড্রেইডলক ১'},
    {'id': 'dreads02', 'name': 'ড্রেইডলক ২'},
    {'id': 'frizzle', 'name': 'ঝাঁকড়া'},
    {'id': 'shaggy', 'name': 'এলোমেলো'},
    {'id': 'shaggyMullet', 'name': 'মালেট'},
    {'id': 'theCaesar', 'name': 'সিজার কাট'},
    {'id': 'theCaesarAndSidePart', 'name': 'সিজার ও সাইড পার্ট'},
    {'id': 'straight01', 'name': 'লম্বা সোজা ১'},
    {'id': 'straight02', 'name': 'লম্বা সোজা ২'},
    {'id': 'bob', 'name': 'বব কাট'},
    {'id': 'bun', 'name': 'খোঁপা'},
    {'id': 'curly', 'name': 'কোঁকড়া লম্বা'},
    {'id': 'curvy', 'name': 'ঢেউ খেলানো লম্বা'},
    {'id': 'fro', 'name': 'আফ্রো'},
    {'id': 'froBand', 'name': 'হেডব্যান্ড আফ্রো'},
    {'id': 'longButNotTooLong', 'name': 'মাঝারি লম্বা'},
    {'id': 'miaWallace', 'name': 'মিয়া স্টাইল'},
    {'id': 'straightAndStrand', 'name': 'সোজা ও স্ট্র্যান্ড'},
    {'id': 'bigHair', 'name': 'ফোলানো'},
    {'id': 'frida', 'name': 'ফ্রিদা কাট'},
    {'id': 'hijab', 'name': 'হিজাব'},
    {'id': 'hat', 'name': 'টুপি'},
    {'id': 'turban', 'name': 'পাগড়ি'},
    {'id': 'winterHat1', 'name': 'শীতের টুপি ১'},
    {'id': 'winterHat02', 'name': 'শীতের টুপি ২'},
    {'id': 'winterHat03', 'name': 'শীতের টুপি ৩'},
    {'id': 'winterHat04', 'name': 'শীতের টুপি ৪'},
    {'id': 'bald', 'name': 'নেড়া মাথা'},
  ];

  final List<Map<String, String>> _eyeOptions = [
    {'id': 'default', 'name': 'স্বাভাবিক'},
    {'id': 'happy', 'name': 'খুশি'},
    {'id': 'wink', 'name': 'চোখ টেপা'},
    {'id': 'eyeRoll', 'name': 'বিরক্ত'},
    {'id': 'closed', 'name': 'বন্ধ'},
    {'id': 'squint', 'name': 'তাকানো'},
    {'id': 'surprised', 'name': 'অবাক'},
    {'id': 'cry', 'name': 'কান্না'},
    {'id': 'hearts', 'name': 'ভালোবাসা'},
    {'id': 'side', 'name': 'পাশে তাকানো'},
    {'id': 'winkWacky', 'name': 'উদ্ভট চোখ টেপা'},
    {'id': 'xDizzy', 'name': 'ক্লান্ত'},
  ];

  final List<Map<String, String>> _eyebrowOptions = [
    {'id': 'default', 'name': 'স্বাভাবিক'},
    {'id': 'defaultNatural', 'name': 'স্বাভাবিক প্রাকৃত'},
    {'id': 'angry', 'name': 'রাগী'},
    {'id': 'angryNatural', 'name': 'রাগী প্রাকৃত'},
    {'id': 'flatNatural', 'name': 'সোজা প্রাকৃত'},
    {'id': 'frownNatural', 'name': 'কুঁচকানো প্রাকৃত'},
    {'id': 'raisedExcited', 'name': 'উত্তেজিত উঁচানো'},
    {'id': 'raisedExcitedNatural', 'name': 'উত্তেজিত প্রাকৃত'},
    {'id': 'sadConcerned', 'name': 'চিন্তিত'},
    {'id': 'sadConcernedNatural', 'name': 'চিন্তিত প্রাকৃত'},
    {'id': 'unibrowNatural', 'name': 'জোড়া ভ্রু'},
    {'id': 'upDown', 'name': 'উপরে নিচে'},
    {'id': 'upDownNatural', 'name': 'উপরে নিচে প্রাকৃত'},
  ];

  final List<Map<String, String>> _mouthOptions = [
    {'id': 'smile', 'name': 'হাসি'},
    {'id': 'default', 'name': 'স্বাভাবিক'},
    {'id': 'concerned', 'name': 'চিন্তিত'},
    {'id': 'disbelief', 'name': 'অবিশ্বাস'},
    {'id': 'eating', 'name': 'খাচ্ছে'},
    {'id': 'grimace', 'name': 'বিরক্তি'},
    {'id': 'sad', 'name': 'দুঃখী'},
    {'id': 'screamOpen', 'name': 'চিৎকার'},
    {'id': 'serious', 'name': 'গম্ভীর'},
    {'id': 'tongue', 'name': 'জিভ বের করা'},
    {'id': 'twinkle', 'name': 'ঝিলিক'},
    {'id': 'vomit', 'name': 'বমি'},
  ];

  final List<Map<String, String>> _clothingOptions = [
    {'id': 'shirtCrewNeck', 'name': 'গোল গলা টিশার্ট'},
    {'id': 'shirtVNeck', 'name': 'ভি-নেক টিশার্ট'},
    {'id': 'shirtScoopNeck', 'name': 'স্কুপ গলা টিশার্ট'},
    {'id': 'hoodie', 'name': 'হুডি'},
    {'id': 'blazerAndShirt', 'name': 'ব্লেজার ও শার্ট'},
    {'id': 'blazerAndSweater', 'name': 'ব্লেজার ও সোয়েটার'},
    {'id': 'collarAndSweater', 'name': 'কলার ও সোয়েটার'},
    {'id': 'graphicShirt', 'name': 'গ্রাফিক শার্ট'},
    {'id': 'overall', 'name': 'ওভারঅল পোশাক'},
  ];

  final List<Map<String, String>> _accessoriesOptions = [
    {'id': 'none', 'name': 'চশমা ছাড়া'},
    {'id': 'prescription01', 'name': 'পাওয়ার চশমা ১'},
    {'id': 'prescription02', 'name': 'পাওয়ার চশমা ২'},
    {'id': 'round', 'name': 'গোল চশমা'},
    {'id': 'sunglasses', 'name': 'সানগ্লাস'},
    {'id': 'wayfarers', 'name': 'ওয়েফেয়ারার'},
    {'id': 'kurt', 'name': 'কুর্ট চশমা'},
    {'id': 'eyepatch', 'name': 'এক চোখের পট্টি'},
  ];

  final List<Map<String, String>> _facialHairOptions = [
    {'id': 'none', 'name': 'দাড়ি ছাড়া'},
    {'id': 'beardLight', 'name': 'হালকা দাড়ি'},
    {'id': 'beardMedium', 'name': 'মাঝারি দাড়ি'},
    {'id': 'beardMajestic', 'name': 'ঘন দাড়ি'},
    {'id': 'moustacheFancy', 'name': 'স্টাইলিশ গোঁফ'},
    {'id': 'moustacheMagnum', 'name': 'ভারী গোঁফ'},
  ];

  // Hex Colors
  final List<String> _hairColors = [
    '2c1b18', '4a312c', '724133', 'a55728', 'b58143', 'd6b370', 'ecdcbf', 'f59797', 'c93305', 'e8e1e1'
  ];

  final List<String> _skinColors = [
    'ffdbb4', 'edb98a', 'f8d25c', 'fd9841', 'd08b5b', 'ae5d29', '614335'
  ];

  final List<String> _clothingColors = [
    '25557c', '3c4f5c', '5199e4', '65c9ff', 'b1e2ff', 'a7ffc4', 'ffdeb5', 'ffafb9', 'ffffb1', 'ff488e', 'ff5c5c', '262e33', 'e6e6e6', '929598', 'ffffff'
  ];

  final List<String> _bgColors = [
    'b1c9ef', 'c4efb1', 'efb1e4', 'efd9b1', 'e3edf7', 'd6d6d6', '1a1a1a', 'ffffff'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 6, vsync: this);
    
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
        if (avatarUrl != null && avatarUrl.contains('api.dicebear.com')) {
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
    const targetY = 345.0; // The threshold near the top of vertical options view

    for (int i = 0; i < 6; i++) {
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
        alignment: 0.0, // Scroll to top of viewport
      );
    }

    await Future.delayed(const Duration(milliseconds: 150));
    _isAutoScrolling = false;
  }

  void _parseAvatarUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      setState(() {
        if (params.containsKey('topProbability') && params['topProbability'] == '0') {
          _selectedHair = 'bald';
        } else if (params.containsKey('top')) {
          _selectedHair = params['top']!;
        }

        if (params.containsKey('hairColor')) {
          _selectedHairColor = params['hairColor']!;
        }
        if (params.containsKey('hatColor')) {
          _selectedHatColor = params['hatColor']!;
        }
        if (params.containsKey('eyes')) {
          _selectedEyes = params['eyes']!;
        }
        if (params.containsKey('eyebrows')) {
          _selectedEyebrows = params['eyebrows']!;
        }
        if (params.containsKey('mouth')) {
          _selectedMouth = params['mouth']!;
        }
        if (params.containsKey('skinColor')) {
          _selectedSkinColor = params['skinColor']!;
        }
        if (params.containsKey('clothing')) {
          _selectedClothing = params['clothing']!;
        }
        if (params.containsKey('clothesColor')) {
          _selectedClothingColor = params['clothesColor']!;
        }
        
        if (params.containsKey('accessoriesProbability') && params['accessoriesProbability'] == '0') {
          _selectedAccessories = 'none';
        } else if (params.containsKey('accessories')) {
          _selectedAccessories = params['accessories']!;
        }
        if (params.containsKey('accessoriesColor')) {
          _selectedAccessoriesColor = params['accessoriesColor']!;
        }

        if (params.containsKey('facialHairProbability') && params['facialHairProbability'] == '0') {
          _selectedFacialHair = 'none';
        } else if (params.containsKey('facialHair')) {
          _selectedFacialHair = params['facialHair']!;
        }
        if (params.containsKey('facialHairColor')) {
          _selectedFacialHairColor = params['facialHairColor']!;
        }

        if (params.containsKey('backgroundColor')) {
          _selectedBgColor = params['backgroundColor']!;
        }
      });
    } catch (_) {}
  }

  String get _avatarUrl {
    final params = <String, String>{};

    // Hair / Hats
    if (_selectedHair == 'bald') {
      params['topProbability'] = '0';
    } else {
      params['top'] = _selectedHair;
      params['topProbability'] = '100';
      params['hairColor'] = _selectedHairColor;
      params['hatColor'] = _selectedHatColor;
    }

    // Face elements
    params['eyes'] = _selectedEyes;
    params['eyebrows'] = _selectedEyebrows;
    params['mouth'] = _selectedMouth;
    params['skinColor'] = _selectedSkinColor;

    // Clothes
    params['clothing'] = _selectedClothing;
    params['clothesColor'] = _selectedClothingColor;

    // Accessories
    if (_selectedAccessories != 'none') {
      params['accessories'] = _selectedAccessories;
      params['accessoriesProbability'] = '100';
      params['accessoriesColor'] = _selectedAccessoriesColor;
    } else {
      params['accessoriesProbability'] = '0';
    }

    // Facial Hair
    if (_selectedFacialHair != 'none') {
      params['facialHair'] = _selectedFacialHair;
      params['facialHairProbability'] = '100';
      params['facialHairColor'] = _selectedFacialHairColor;
    } else {
      params['facialHairProbability'] = '0';
    }

    // Background
    params['backgroundColor'] = _selectedBgColor;

    final queryString = Uri(queryParameters: params).query;
    return 'https://api.dicebear.com/9.x/avataaars/svg?$queryString';
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
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('অ্যাভাটার সফলভাবে সংরক্ষণ করা হয়েছে!'),
            backgroundColor: Color(0xFF017A47),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('অ্যাভাটার সংরক্ষণ করা যায়নি: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'অ্যাভাটার এডিট করো',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: CustomBackButton(
          color: isDark ? Colors.white : Colors.black,
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. Sticky Live Preview Panel (Always on top)
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E272C), const Color(0xFF0F1518)]
                    : [const Color(0xFFE3EDF7), const Color(0xFFF5F7FA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: 'user_avatar_hero',
                  child: CustomAvatar(
                    avatarUrl: _avatarUrl,
                    radius: 80,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                if (_isSaving)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Sticky Tab Horizontal Menu (Automatically syncs on scrolling using native TabBar)
          Container(
            height: 54,
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
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                _buildTab('চুল ও টুপি', Icons.face_retouching_natural),
                _buildTab('চোখ ও ভ্রু', Icons.visibility_rounded),
                _buildTab('মুখ ও দাড়ি', Icons.sentiment_satisfied_alt_rounded),
                _buildTab('পোশাক', Icons.checkroom_rounded),
                _buildTab('চশমা', Icons.face_unlock_rounded),
                _buildTab('গায়ের রঙ ও ব্যাকগ্রাউন্ড', Icons.palette_rounded),
              ],
            ),
          ),

          // 3. Vertically Scrollable Content Panel with all options together
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 0: Hair and Hats
                  _buildSectionHeader(0, 'চুল ও টুপি (Hair & Hats)'),
                  const SizedBox(height: 12),
                  _buildHairGrid(),
                  const SizedBox(height: 32),

                  // Section 1: Eyes & Brows
                  _buildSectionHeader(1, 'চোখ ও ভ্রু (Eyes & Brows)'),
                  const SizedBox(height: 12),
                  _buildSubTitle('চোখের ভঙ্গি (Eyes)'),
                  const SizedBox(height: 8),
                  _buildEyesGrid(),
                  const SizedBox(height: 20),
                  _buildSubTitle('ভ্রু-র ডিজাইন (Eyebrows)'),
                  const SizedBox(height: 8),
                  _buildEyebrowsGrid(),
                  const SizedBox(height: 32),

                  // Section 2: Mouth & Beard
                  _buildSectionHeader(2, 'মুখ ও দাড়ি (Mouth & Facial Hair)'),
                  const SizedBox(height: 12),
                  _buildSubTitle('মুখের অভিব্যক্তি (Mouth)'),
                  const SizedBox(height: 8),
                  _buildMouthGrid(),
                  const SizedBox(height: 20),
                  _buildSubTitle('দাড়ি ও গোঁফ (Facial Hair)'),
                  const SizedBox(height: 8),
                  _buildFacialHairGrid(),
                  const SizedBox(height: 32),

                  // Section 3: Clothing
                  _buildSectionHeader(3, 'পোশাক (Clothing Style)'),
                  const SizedBox(height: 12),
                  _buildClothingGrid(),
                  const SizedBox(height: 32),

                  // Section 4: Accessories
                  _buildSectionHeader(4, 'চশমা (Eyewear & Accessories)'),
                  const SizedBox(height: 12),
                  _buildAccessoriesGrid(),
                  const SizedBox(height: 32),

                  // Section 5: Colors
                  _buildSectionHeader(5, 'রঙের প্যালেট (Color Options)'),
                  const SizedBox(height: 16),
                  _buildColorsPanel(),
                  const SizedBox(height: 80), // Extra bottom padding for floating button
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
              elevation: 4, // Slightly higher elevation for floating look
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : brandTealColor,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  // Segmented Grid components
  Widget _buildHairGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _hairOptions.length,
      itemBuilder: (context, index) {
        final option = _hairOptions[index];
        final isSelected = _selectedHair == option['id'];

        final topProb = option['id'] == 'bald' ? '0' : '100';
        final topOption = option['id'] == 'bald' ? 'shortFlat' : option['id'];

        final previewUrl = 'https://api.dicebear.com/9.x/avataaars/svg?'
            'top=$topOption&'
            'topProbability=$topProb&'
            'hairColor=$_selectedHairColor&'
            'hatColor=$_selectedHatColor&'
            'eyes=default&'
            'mouth=default&'
            'skinColor=$_selectedSkinColor&'
            'clothesColor=$_selectedClothingColor';

        return Column(
          children: [
            Expanded(
              child: _buildOptionButton(
                previewUrl: previewUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedHair = option['id']!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option['id']!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEyesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _eyeOptions.length,
      itemBuilder: (context, index) {
        final option = _eyeOptions[index];
        final isSelected = _selectedEyes == option['id'];
        final previewUrl = 'https://api.dicebear.com/9.x/avataaars/svg?'
            'topProbability=0&'
            'eyes=${option['id']}&'
            'eyebrows=default&'
            'mouth=default&'
            'skinColor=$_selectedSkinColor';

        return Column(
          children: [
            Expanded(
              child: _buildOptionButton(
                previewUrl: previewUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedEyes = option['id']!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option['id']!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEyebrowsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _eyebrowOptions.length,
      itemBuilder: (context, index) {
        final option = _eyebrowOptions[index];
        final isSelected = _selectedEyebrows == option['id'];
        final previewUrl = 'https://api.dicebear.com/9.x/avataaars/svg?'
            'topProbability=0&'
            'eyes=default&'
            'eyebrows=${option['id']}&'
            'mouth=default&'
            'skinColor=$_selectedSkinColor';

        return Column(
          children: [
            Expanded(
              child: _buildOptionButton(
                previewUrl: previewUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedEyebrows = option['id']!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option['id']!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMouthGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _mouthOptions.length,
      itemBuilder: (context, index) {
        final option = _mouthOptions[index];
        final isSelected = _selectedMouth == option['id'];
        final previewUrl = 'https://api.dicebear.com/9.x/avataaars/svg?'
            'topProbability=0&'
            'eyes=default&'
            'mouth=${option['id']}&'
            'skinColor=$_selectedSkinColor';

        return Column(
          children: [
            Expanded(
              child: _buildOptionButton(
                previewUrl: previewUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedMouth = option['id']!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option['id']!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFacialHairGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _facialHairOptions.length,
      itemBuilder: (context, index) {
        final option = _facialHairOptions[index];
        final isSelected = _selectedFacialHair == option['id'];

        final previewUrl = option['id'] == 'none'
            ? 'https://api.dicebear.com/9.x/avataaars/svg?topProbability=0&eyes=default&mouth=default&skinColor=$_selectedSkinColor&facialHairProbability=0'
            : 'https://api.dicebear.com/9.x/avataaars/svg?topProbability=0&eyes=default&mouth=default&skinColor=$_selectedSkinColor&facialHair=${option['id']}&facialHairProbability=100&facialHairColor=$_selectedFacialHairColor';

        return Column(
          children: [
            Expanded(
              child: _buildOptionButton(
                previewUrl: previewUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedFacialHair = option['id']!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option['id']!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildClothingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _clothingOptions.length,
      itemBuilder: (context, index) {
        final option = _clothingOptions[index];
        final isSelected = _selectedClothing == option['id'];

        final previewUrl = 'https://api.dicebear.com/9.x/avataaars/svg?'
            'topProbability=0&'
            'eyes=default&'
            'mouth=default&'
            'skinColor=$_selectedSkinColor&'
            'clothing=${option['id']}&'
            'clothesColor=$_selectedClothingColor';

        return Column(
          children: [
            Expanded(
              child: _buildOptionButton(
                previewUrl: previewUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedClothing = option['id']!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option['id']!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _accessoriesOptions.length,
      itemBuilder: (context, index) {
        final option = _accessoriesOptions[index];
        final isSelected = _selectedAccessories == option['id'];

        final previewUrl = option['id'] == 'none'
            ? 'https://api.dicebear.com/9.x/avataaars/svg?topProbability=0&eyes=default&mouth=default&skinColor=transparent&accessoriesProbability=0'
            : 'https://api.dicebear.com/9.x/avataaars/svg?topProbability=0&eyes=default&mouth=default&skinColor=transparent&accessories=${option['id']}&accessoriesProbability=100&accessoriesColor=$_selectedAccessoriesColor';

        return Column(
          children: [
            Expanded(
              child: _buildOptionButton(
                previewUrl: previewUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedAccessories = option['id']!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option['id']!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColorRowTitle('গায়ের রঙ (Skin Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_skinColors, _selectedSkinColor, (color) {
          setState(() => _selectedSkinColor = color);
        }),
        const Divider(height: 24),
        _buildColorRowTitle('চুলের রঙ (Hair Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_hairColors, _selectedHairColor, (color) {
          setState(() => _selectedHairColor = color);
        }),
        const Divider(height: 24),
        _buildColorRowTitle('টুপির রঙ (Hat Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_clothingColors, _selectedHatColor, (color) {
          setState(() => _selectedHatColor = color);
        }),
        const Divider(height: 24),
        _buildColorRowTitle('দাড়ির রঙ (Beard Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_hairColors, _selectedFacialHairColor, (color) {
          setState(() => _selectedFacialHairColor = color);
        }),
        const Divider(height: 24),
        _buildColorRowTitle('পোশাকের রঙ (Clothes Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_clothingColors, _selectedClothingColor, (color) {
          setState(() => _selectedClothingColor = color);
        }),
        const Divider(height: 24),
        _buildColorRowTitle('চশমার রঙ (Glasses Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_clothingColors, _selectedAccessoriesColor, (color) {
          setState(() => _selectedAccessoriesColor = color);
        }),
        const Divider(height: 24),
        _buildColorRowTitle('ব্যাকগ্রাউন্ডের রঙ (Background Color)'),
        const SizedBox(height: 8),
        _buildColorRow(_bgColors, _selectedBgColor, (color) {
          setState(() => _selectedBgColor = color);
        }),
      ],
    );
  }

  Widget _buildOptionButton({
    required String previewUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const brandTealColor = Color(0xFF086057);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? brandTealColor.withValues(alpha: 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FA)),
          border: Border.all(
            color: isSelected
                ? brandTealColor
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: CheckerboardPainter(
                  checkColor: isDark 
                      ? Colors.white.withValues(alpha: 0.04) 
                      : Colors.black.withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Center(
                child: CustomAvatar(
                  avatarUrl: previewUrl,
                  radius: 32,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRowTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
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
                          color: const Color(0xFF086057).withOpacity(0.3),
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

class CheckerboardPainter extends CustomPainter {
  final Color checkColor;

  CheckerboardPainter({required this.checkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = checkColor;
    const double squareSize = 6.0;

    for (double y = 0; y < size.height; y += squareSize) {
      final bool offset = (y ~/ squareSize) % 2 == 1;
      for (double x = 0; x < size.width; x += squareSize) {
        if (((x ~/ squareSize) % 2 == 1) != offset) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, squareSize, squareSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
