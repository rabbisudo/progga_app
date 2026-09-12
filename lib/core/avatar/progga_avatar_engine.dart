import 'dart:math';

/// Immutable model representing the customization options of a Progga Avatar.
class ProggaAvatarConfig {
  final String hair;
  final String hairColor;
  final String hat; // 'none', 'cap', 'snapback', 'helmetMoto', 'helmetSkate', 'beanie', 'beaniePom', 'bucketHat', 'fedora', 'beret', 'hijab', 'turban', 'headband', 'bandana', 'kufi', 'cowboy'
  final String hatColor;
  final String skinColor;
  final String eyes;
  final String eyebrows;
  final String mouth;
  final String clothing;
  final String clothingColor;
  final String glasses; // 'none', 'roundWire', 'wayfarers', 'clubmaster', 'aviator', 'catEye', 'rectOptical', 'rectShades', 'hexagonal', 'roundShades', 'cyberVisor', 'halfRim'
  final String glassesColor;
  final String accessories; // 'none', 'headphones', 'hoopEarrings', 'studEarrings', 'bindi'
  final String accessoriesColor;
  final String beard; // 'none', 'stubble', 'chinStrap', 'goatee', 'beardMedium', 'beardMajestic', 'anchor'
  final String beardColor;
  final String moustache; // 'none', 'pencil', 'classic', 'handlebar', 'chevron', 'horseshoe'
  final String moustacheColor;
  final String faceShape; // 'chiseledSquare', 'slenderOval', 'softRound', 'diamondSharp'
  final String bgColor;
  final String bgStyle; // 'cloud', 'circle', 'squircle', 'none'

  /// Backward compatibility getter for legacy facialHair callers
  String get facialHair => beard != 'none' ? beard : (moustache != 'none' ? moustache : 'none');

  /// Backward compatibility getter for legacy facialHairColor callers
  String get facialHairColor => beard != 'none' ? beardColor : moustacheColor;

  const ProggaAvatarConfig({
    this.faceShape = 'chiseledSquare',
    this.hair = 'modernQuiff',
    this.hairColor = '1b203a',
    this.hat = 'none',
    this.hatColor = '262e33',
    this.skinColor = 'ffdbb4',
    this.eyes = 'confident',
    this.eyebrows = 'default',
    this.mouth = 'smirk',
    this.clothing = 'shirtCrewNeck',
    this.clothingColor = '86198f',
    this.glasses = 'rectShades',
    this.glassesColor = '18181b',
    this.accessories = 'none',
    this.accessoriesColor = '18181b',
    this.beard = 'none',
    this.beardColor = '1b203a',
    this.moustache = 'none',
    this.moustacheColor = '1b203a',
    this.bgColor = 'd8b4fe',
    this.bgStyle = 'cloud',
  });

  ProggaAvatarConfig copyWith({
    String? faceShape,
    String? hair,
    String? hairColor,
    String? hat,
    String? hatColor,
    String? skinColor,
    String? eyes,
    String? eyebrows,
    String? mouth,
    String? clothing,
    String? clothingColor,
    String? glasses,
    String? glassesColor,
    String? accessories,
    String? accessoriesColor,
    String? beard,
    String? beardColor,
    String? moustache,
    String? moustacheColor,
    @Deprecated('Use beard or moustache instead') String? facialHair,
    @Deprecated('Use beardColor or moustacheColor instead') String? facialHairColor,
    String? bgColor,
    String? bgStyle,
  }) {
    var resolvedBeard = beard;
    var resolvedBeardColor = beardColor;
    var resolvedMoustache = moustache;
    var resolvedMoustacheColor = moustacheColor;

    if (facialHair != null) {
      if (facialHair == 'moustacheFancy' || facialHair.contains('moustache')) {
        resolvedMoustache ??= 'handlebar';
        resolvedMoustacheColor ??= facialHairColor ?? this.moustacheColor;
      } else {
        resolvedBeard ??= facialHair;
        resolvedBeardColor ??= facialHairColor ?? this.beardColor;
      }
    }

    return ProggaAvatarConfig(
      faceShape: faceShape ?? this.faceShape,
      hair: hair ?? this.hair,
      hairColor: hairColor ?? this.hairColor,
      hat: hat ?? this.hat,
      hatColor: hatColor ?? this.hatColor,
      skinColor: skinColor ?? this.skinColor,
      eyes: eyes ?? this.eyes,
      eyebrows: eyebrows ?? this.eyebrows,
      mouth: mouth ?? this.mouth,
      clothing: clothing ?? this.clothing,
      clothingColor: clothingColor ?? this.clothingColor,
      glasses: glasses ?? this.glasses,
      glassesColor: glassesColor ?? this.glassesColor,
      accessories: accessories ?? this.accessories,
      accessoriesColor: accessoriesColor ?? this.accessoriesColor,
      beard: resolvedBeard ?? this.beard,
      beardColor: resolvedBeardColor ?? this.beardColor,
      moustache: resolvedMoustache ?? this.moustache,
      moustacheColor: resolvedMoustacheColor ?? this.moustacheColor,
      bgColor: bgColor ?? this.bgColor,
      bgStyle: bgStyle ?? this.bgStyle,
    );
  }

  /// Encodes this configuration into an in-house compact URI key
  String toProggaKey() {
    final params = <String, String>{
      'bg': bgColor,
      if (bgStyle != 'cloud') 'bgStyle': bgStyle,
      if (faceShape != 'chiseledSquare') 'face': faceShape,
      'skin': skinColor,
      'hair': hair,
      'hairColor': hairColor,
      if (hat != 'none') 'hat': hat,
      if (hat != 'none') 'hatColor': hatColor,
      'eyes': eyes,
      'eyebrows': eyebrows,
      'mouth': mouth,
      'clothing': clothing,
      'clothingColor': clothingColor,
      if (glasses != 'none') 'glasses': glasses,
      if (glasses != 'none') 'glassesColor': glassesColor,
      if (accessories != 'none') 'acc': accessories,
      if (accessories != 'none') 'accColor': accessoriesColor,
      if (beard != 'none') 'beard': beard,
      if (beard != 'none') 'beardColor': beardColor,
      if (moustache != 'none') 'moustache': moustache,
      if (moustache != 'none') 'moustacheColor': moustacheColor,
    };
    return 'progga:${Uri(queryParameters: params).query}';
  }

  /// Parses an avatar string.
  factory ProggaAvatarConfig.fromKey(String? key) {
    if (key == null || key.trim().isEmpty) {
      return const ProggaAvatarConfig();
    }

    final trimmed = key.trim();

    // 1. In-House Progga format
    if (trimmed.startsWith('progga:')) {
      try {
        final query = trimmed.substring('progga:'.length);
        final uri = Uri.parse('http://dummy?$query');
        final p = uri.queryParameters;

        var rawHair = p['hair'] ?? 'modernQuiff';
        var rawHat = p['hat'] ?? 'none';
        var rawHatColor = p['hatColor'] ?? '262e33';

        if (rawHair == 'hat') {
          rawHat = 'cap';
          rawHair = 'shortFlat';
        } else if (rawHair == 'winterHat1') {
          rawHat = 'beanie';
          rawHair = 'shortFlat';
        } else if (rawHair == 'hijab') {
          rawHat = 'hijab';
          rawHair = 'shortFlat';
        } else if (rawHair == 'turban') {
          rawHat = 'turban';
          rawHair = 'shortFlat';
        }

        var rawGlasses = p['glasses'];
        var rawGlassesColor = p['glassesColor'];
        var rawAcc = p['acc'] ?? 'none';
        var rawAccColor = p['accColor'] ?? '18181b';

        // Auto-migration from legacy combined acc if glasses is not explicitly present:
        if (rawGlasses == null) {
          const legacyGlasses = {
            'rectShades', 'catEye', 'round', 'roundWire', 'wayfarers',
            'sunglasses', 'prescription01', 'prescription02', 'clubmaster',
            'aviator', 'rectOptical', 'hexagonal', 'roundShades', 'cyberVisor', 'halfRim'
          };
          if (legacyGlasses.contains(rawAcc)) {
            if (rawAcc == 'round') {
              rawGlasses = 'roundWire';
            } else if (rawAcc == 'sunglasses') {
              rawGlasses = 'wayfarers';
            } else if (rawAcc == 'prescription01' || rawAcc == 'prescription02') {
              rawGlasses = 'rectOptical';
            } else {
              rawGlasses = rawAcc;
            }
            rawGlassesColor = rawAccColor;
            rawAcc = 'none';
          } else {
            rawGlasses = 'none';
            rawGlassesColor = '18181b';
          }
        }

        var rawBeard = p['beard'] ?? 'none';
        var rawBeardColor = p['beardColor'] ?? '1b203a';
        var rawMoustache = p['moustache'] ?? 'none';
        var rawMoustacheColor = p['moustacheColor'] ?? '1b203a';

        // Auto-migration for legacy keys where facialHair or beard had moustache:
        if (rawBeard == 'moustacheFancy' || rawBeard == 'moustache') {
          rawMoustache = 'handlebar';
          rawMoustacheColor = rawBeardColor;
          rawBeard = 'none';
        }
        final legacyFacial = p['facialHair'];
        if (legacyFacial != null && legacyFacial != 'none') {
          if (legacyFacial == 'moustacheFancy' || legacyFacial.contains('moustache')) {
            rawMoustache = 'handlebar';
            rawMoustacheColor = p['facialHairColor'] ?? rawBeardColor;
          } else {
            rawBeard = legacyFacial;
            rawBeardColor = p['facialHairColor'] ?? rawBeardColor;
          }
        }

        return ProggaAvatarConfig(
          bgColor: p['bg'] ?? 'd8b4fe',
          bgStyle: p['bgStyle'] ?? 'cloud',
          faceShape: p['face'] ?? 'chiseledSquare',
          skinColor: p['skin'] ?? 'ffdbb4',
          hair: rawHair,
          hairColor: p['hairColor'] ?? '1b203a',
          hat: rawHat,
          hatColor: rawHatColor,
          eyes: p['eyes'] ?? 'confident',
          eyebrows: p['eyebrows'] ?? 'default',
          mouth: p['mouth'] ?? 'smirk',
          clothing: p['clothing'] ?? 'shirtCrewNeck',
          clothingColor: p['clothingColor'] ?? '86198f',
          glasses: rawGlasses,
          glassesColor: rawGlassesColor ?? '18181b',
          accessories: rawAcc,
          accessoriesColor: rawAccColor,
          beard: rawBeard,
          beardColor: rawBeardColor,
          moustache: rawMoustache,
          moustacheColor: rawMoustacheColor,
        );
      } catch (_) {
        return const ProggaAvatarConfig();
      }
    }

    // 2. Legacy DiceBear URL backward-compatibility
    if (trimmed.contains('dicebear.com')) {
      try {
        final uri = Uri.parse(trimmed);
        final p = uri.queryParameters;
        var hair = (p['topProbability'] == '0') ? 'bald' : (p['top'] ?? 'shortFlat');
        var hat = 'none';
        if (hair == 'hat') {
          hat = 'cap';
          hair = 'shortFlat';
        } else if (hair == 'winterHat1') {
          hat = 'beanie';
          hair = 'shortFlat';
        } else if (hair == 'hijab') {
          hat = 'hijab';
          hair = 'shortFlat';
        } else if (hair == 'turban') {
          hat = 'turban';
          hair = 'shortFlat';
        }

        var acc = (p['accessoriesProbability'] == '0') ? 'none' : (p['accessories'] ?? 'none');
        final accColor = p['accessoriesColor'] ?? '262e33';
        var glasses = 'none';
        var glassesColor = '18181b';

        if (acc == 'round' || acc == 'prescription01' || acc == 'prescription02' || acc == 'sunglasses' || acc == 'wayfarers') {
          if (acc == 'round') {
            glasses = 'roundWire';
          } else if (acc == 'sunglasses') {
            glasses = 'wayfarers';
          } else if (acc == 'prescription01' || acc == 'prescription02') {
            glasses = 'rectOptical';
          } else {
            glasses = acc;
          }
          glassesColor = accColor;
          acc = 'none';
        }

        final rawFacial = (p['facialHairProbability'] == '0') ? 'none' : (p['facialHair'] ?? 'none');
        var beard = 'none';
        var moustache = 'none';
        if (rawFacial.contains('moustache')) {
          moustache = 'classic';
        } else if (rawFacial != 'none') {
          beard = rawFacial;
        }

        return ProggaAvatarConfig(
          faceShape: 'chiseledSquare',
          hair: hair,
          hairColor: p['hairColor'] ?? '2c1b18',
          hat: hat,
          hatColor: p['hatColor'] ?? '262e33',
          skinColor: p['skinColor'] ?? 'ffdbb4',
          eyes: p['eyes'] ?? 'default',
          eyebrows: p['eyebrows'] ?? 'default',
          mouth: p['mouth'] ?? 'smile',
          clothing: p['clothing'] ?? 'shirtCrewNeck',
          clothingColor: p['clothesColor'] ?? '086057',
          glasses: glasses,
          glassesColor: glassesColor,
          accessories: acc,
          accessoriesColor: accColor,
          beard: beard,
          beardColor: p['facialHairColor'] ?? '2c1b18',
          moustache: moustache,
          moustacheColor: p['facialHairColor'] ?? '2c1b18',
          bgColor: p['backgroundColor'] ?? '086057',
          bgStyle: 'circle',
        );
      } catch (_) {
        return const ProggaAvatarConfig();
      }
    }

    return const ProggaAvatarConfig();
  }

  /// Popular pre-crafted Progga student character presets matching the reference art
  static final List<Map<String, dynamic>> presets = [
    {
      'title': 'কুল বস',
      'subtitle': 'স্মার্ট লিডার ও টেক প্রডিজি',
      'config': const ProggaAvatarConfig(
        faceShape: 'chiseledSquare',
        hair: 'modernQuiff',
        hairColor: '1b203a',
        hat: 'none',
        skinColor: 'ffdbb4',
        eyes: 'confident',
        eyebrows: 'default',
        mouth: 'smirk',
        clothing: 'shirtCrewNeck',
        clothingColor: '86198f',
        glasses: 'rectShades',
        glassesColor: '18181b',
        accessories: 'none',
        accessoriesColor: '18181b',
        bgColor: 'd8b4fe',
        bgStyle: 'cloud',
      ),
    },
    {
      'title': 'ফ্যাশন ডিভা',
      'subtitle': 'ক্রিয়েটিভ ও আত্মবিশ্বাসী লার্নার',
      'config': const ProggaAvatarConfig(
        faceShape: 'slenderOval',
        hair: 'sideChignon',
        hairColor: '6d381c',
        hat: 'none',
        skinColor: 'fde047',
        eyes: 'happy',
        eyebrows: 'default',
        mouth: 'smileTeeth',
        clothing: 'shirtCrewNeck',
        clothingColor: '1d4ed8',
        glasses: 'catEye',
        glassesColor: 'c026d3',
        accessories: 'studEarrings',
        accessoriesColor: 'ffffff',
        bgColor: 'fdba74',
        bgStyle: 'cloud',
      ),
    },
    {
      'title': 'ডিটারমাইন্ড লিডার',
      'subtitle': 'লক্ষ্যভেদী ও ফোকাসড চ্যাম্পিয়ন',
      'config': const ProggaAvatarConfig(
        faceShape: 'slenderOval',
        hair: 'sideChignon',
        hairColor: '5c2f17',
        hat: 'none',
        skinColor: 'ffedd5',
        eyes: 'intense',
        eyebrows: 'angryFierce',
        mouth: 'grit',
        clothing: 'shirtScoopNeck',
        clothingColor: '1d4ed8',
        glasses: 'none',
        glassesColor: '18181b',
        accessories: 'hoopEarrings',
        accessoriesColor: 'f59e0b',
        bgColor: '2dd4bf',
        bgStyle: 'cloud',
      ),
    },
    {
      'title': 'ফায়ার ফাইটার',
      'subtitle': 'অদম্য শক্তি ও লড়াকু মনোভাব',
      'config': const ProggaAvatarConfig(
        faceShape: 'chiseledSquare',
        hair: 'modernQuiff',
        hairColor: '0f172a',
        hat: 'none',
        skinColor: 'fed7aa',
        eyes: 'intense',
        eyebrows: 'angryFierce',
        mouth: 'grit',
        clothing: 'shirtCrewNeck',
        clothingColor: '9333ea',
        glasses: 'aviator',
        glassesColor: '18181b',
        accessories: 'none',
        accessoriesColor: '18181b',
        bgColor: '7dd3fc',
        bgStyle: 'cloud',
      ),
    },
    {
      'title': 'হিজাবি স্কলার',
      'subtitle': 'পরিশ্রমী, শান্ত ও মেধাবী',
      'config': const ProggaAvatarConfig(
        faceShape: 'slenderOval',
        hair: 'shortFlat',
        hairColor: '2c1b18',
        hat: 'hijab',
        hatColor: '2c1b18',
        skinColor: 'ffdbb4',
        eyes: 'happy',
        eyebrows: 'default',
        mouth: 'smile',
        clothing: 'shirtCrewNeck',
        clothingColor: '3c4f76',
        glasses: 'roundWire',
        glassesColor: 'd4af37',
        accessories: 'none',
        accessoriesColor: 'b58143',
        bgColor: 'f472b6',
        bgStyle: 'cloud',
      ),
    },
    {
      'title': 'ক্যাপ বয়',
      'subtitle': 'স্পোর্টি ও ক্যাজুয়াল শিক্ষার্থী',
      'config': const ProggaAvatarConfig(
        faceShape: 'softRound',
        hair: 'theCaesar',
        hairColor: '1a1a1a',
        hat: 'cap',
        hatColor: '25557c',
        skinColor: 'edb98a',
        eyes: 'default',
        eyebrows: 'default',
        mouth: 'smile',
        clothing: 'hoodie',
        clothingColor: '086057',
        glasses: 'wayfarers',
        glassesColor: '18181b',
        accessories: 'headphones',
        accessoriesColor: '086057',
        bgColor: '34d399',
        bgStyle: 'cloud',
      ),
    },
  ];

  /// Generates a completely random fun avatar
  static ProggaAvatarConfig random() {
    final rand = Random();
    final faceShapes = ['chiseledSquare', 'slenderOval', 'softRound', 'diamondSharp'];
    final hairs = ['modernQuiff', 'sideChignon', 'shortFlat', 'shortRound', 'shortCurly', 'theCaesar', 'curly', 'bun'];
    final hairColors = ['1b203a', '6d381c', '2c1b18', '4a312c', '724133', '1a1a1a'];
    final hats = ['none', 'none', 'none', 'cap', 'beanie', 'hijab'];
    final hatColors = ['262e33', '25557c', '86198f', '086057', '1b203a'];
    final skinColors = ['ffdbb4', 'edb98a', 'fde047', 'ffedd5', 'fed7aa', 'd08b5b'];
    final eyesList = ['confident', 'intense', 'happy', 'wink', 'surprised', 'eyeRoll', 'sparkle', 'cool', 'sleepy', 'cryingJoy', 'default'];
    final eyebrowsList = ['default', 'angryFierce', 'determined'];
    final mouths = ['smirk', 'grit', 'smileTeeth', 'smile', 'twinkle'];
    final clothes = ['shirtCrewNeck', 'shirtScoopNeck', 'hoodie', 'blazerAndShirt', 'collarAndSweater'];
    final clothColors = ['86198f', '1d4ed8', '9333ea', '086057', '25557c', 'ff5c5c'];
    final glassesList = ['none', 'none', 'roundWire', 'wayfarers', 'clubmaster', 'aviator', 'catEye', 'rectOptical', 'rectShades', 'hexagonal', 'roundShades', 'cyberVisor', 'halfRim'];
    final glassColors = ['18181b', 'd4af37', 'a8a29e', 'b58143', 'ef4444', '2563eb', '10b981', '7c3aed', 'ffffff'];
    final accs = ['none', 'none', 'headphones', 'hoopEarrings', 'studEarrings', 'bindi'];
    final beards = ['none', 'none', 'none', 'stubble', 'chinStrap', 'goatee', 'beardMedium', 'beardMajestic', 'anchor'];
    final moustaches = ['none', 'none', 'none', 'pencil', 'classic', 'handlebar', 'chevron', 'horseshoe'];
    final bgs = ['d8b4fe', 'fdba74', '2dd4bf', '7dd3fc', 'f472b6', '34d399', '086057'];

    return ProggaAvatarConfig(
      faceShape: faceShapes[rand.nextInt(faceShapes.length)],
      hair: hairs[rand.nextInt(hairs.length)],
      hairColor: hairColors[rand.nextInt(hairColors.length)],
      hat: hats[rand.nextInt(hats.length)],
      hatColor: hatColors[rand.nextInt(hatColors.length)],
      skinColor: skinColors[rand.nextInt(skinColors.length)],
      eyes: eyesList[rand.nextInt(eyesList.length)],
      eyebrows: eyebrowsList[rand.nextInt(eyebrowsList.length)],
      mouth: mouths[rand.nextInt(mouths.length)],
      clothing: clothes[rand.nextInt(clothes.length)],
      clothingColor: clothColors[rand.nextInt(clothColors.length)],
      glasses: glassesList[rand.nextInt(glassesList.length)],
      glassesColor: glassColors[rand.nextInt(glassColors.length)],
      accessories: accs[rand.nextInt(accs.length)],
      beard: beards[rand.nextInt(beards.length)],
      beardColor: hairColors[rand.nextInt(hairColors.length)],
      moustache: moustaches[rand.nextInt(moustaches.length)],
      moustacheColor: hairColors[rand.nextInt(hairColors.length)],
      bgColor: bgs[rand.nextInt(bgs.length)],
      bgStyle: 'cloud',
    );
  }
}

/// Pure vector SVG builder producing crisp, self-contained SVG strings locally in RAM.
class ProggaAvatarSvgBuilder {
  static String _c(String hex) => hex.startsWith('#') ? hex : '#$hex';

  /// Generates a complete SVG string representing the customized avatar.
  static String buildSvg(
    ProggaAvatarConfig config, {
    bool isBlinking = false,
    bool isCircle = false,
    bool hasBg = true,
    double borderRadius = 32,
  }) {
    final bg = _c(config.bgColor);
    final skin = _c(config.skinColor);
    final hair = _c(config.hairColor);
    final hat = _c(config.hatColor);
    final cloth = _c(config.clothingColor);
    final glass = _c(config.glassesColor);
    final acc = _c(config.accessoriesColor);
    final beard = _c(config.beardColor);
    final moustache = _c(config.moustacheColor);

    final effectiveBgStyle = isCircle ? 'circle' : config.bgStyle;

    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 260 260" width="100%" height="100%">');

    // 1. Defs: Gradients & ClipPaths
    sb.writeln('''
      <defs>
        <radialGradient id="bgGrad" cx="45%" cy="35%" r="65%">
          <stop offset="0%" stop-color="$bg" stop-opacity="0.95" />
          <stop offset="100%" stop-color="$bg" stop-opacity="1.0" />
        </radialGradient>
        <clipPath id="avatarClip">
          ${effectiveBgStyle == 'circle' ? '<circle cx="130" cy="130" r="124" />' : (effectiveBgStyle == 'squircle' ? '<rect x="0" y="0" width="260" height="260" rx="$borderRadius" />' : '<rect x="0" y="0" width="260" height="260" />')}
        </clipPath>
        <clipPath id="hairUnderHatClip">
          <rect x="0" y="88" width="260" height="172" />
        </clipPath>
      </defs>
    ''');

    // 2. Background Framing (Cloud Badge with Echo Contour, Circle, or Squircle)
    if (hasBg) {
      if (effectiveBgStyle == 'cloud') {
        sb.writeln('<path d="M 44 210 C 18 190 14 135 34 105 C 16 72 48 34 88 44 C 104 18 156 18 172 44 C 212 34 244 72 226 105 C 246 135 242 190 216 210 L 216 260 L 44 260 Z" fill="url(#bgGrad)" />');
        sb.writeln('<path d="M 22 100 C 10 65 40 26 80 36" stroke="$bg" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.8" />');
        sb.writeln('<path d="M 180 36 C 220 26 250 65 238 100" stroke="$bg" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.8" />');
      } else if (effectiveBgStyle == 'circle') {
        sb.writeln('<circle cx="130" cy="130" r="124" fill="url(#bgGrad)" />');
      } else if (effectiveBgStyle == 'squircle') {
        sb.writeln('<rect x="0" y="0" width="260" height="260" rx="$borderRadius" fill="url(#bgGrad)" />');
      }
    }

    // Clip inner character content for smooth boundary
    sb.writeln('<g clip-path="url(#avatarClip)">');

    final hasCrownHat = config.hat != 'none' && config.hat != 'headband' && config.hat != 'hijab' && config.hat != 'turban' && config.hat != 'helmetMoto';

    // Behind-head Hair Layer (e.g. buns, cascading curls, bob, long waves)
    if (config.hat != 'hijab' && config.hat != 'turban' && config.hat != 'helmetMoto') {
      if (config.hat == 'none' || config.hat == 'headband' || config.hair != 'bun') {
        _appendBackHair(sb, config.hair, hair);
      }
    }

    // 3. Proportional Slender Neck & Cast Shadow
    sb.writeln('<path d="M 109 154 L 109 202 C 109 202 119 206 130 206 C 141 206 151 202 151 202 L 151 154 Z" fill="$skin" />');
    // Adaptive curved chin drop-shadow matching face shape
    _appendNeckShadow(sb, config.faceShape);

    // 4. Slender & Athletic Shoulders & Torso
    _appendClothing(sb, config.clothing, cloth);

    // 5. Ears (Seamlessly anchored deep inside skull with zero gaps)
    // Left ear: anchored deep inside skull at x=90, curves out to x=62, soft lobe at y=127, anchors back to x=90
    sb.writeln('<path d="M 90 100 C 76 98 62 103 62 113 C 62 122 70 127 80 127 C 86 127 88 128 90 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 72 109 C 66 112 66 119 72 121" stroke="#000000" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.10" />');

    // Right ear: mirrored geometry anchored deep inside skull at x=170
    sb.writeln('<path d="M 170 100 C 184 98 198 103 198 113 C 198 122 190 127 180 127 C 174 127 172 128 170 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 188 109 C 194 112 194 119 188 121" stroke="#000000" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.10" />');

    // Earring accessories attached accurately to lobes
    if (config.accessories == 'hoopEarrings') {
      sb.writeln('<circle cx="69" cy="130" r="8" stroke="$acc" stroke-width="2.8" fill="none" />');
      sb.writeln('<circle cx="191" cy="130" r="8" stroke="$acc" stroke-width="2.8" fill="none" />');
    } else if (config.accessories == 'studEarrings') {
      sb.writeln('<circle cx="71" cy="125" r="3.2" fill="$acc" />');
      sb.writeln('<circle cx="71.8" cy="124.2" r="1.0" fill="#ffffff" opacity="0.8" />');
      sb.writeln('<circle cx="189" cy="125" r="3.2" fill="$acc" />');
      sb.writeln('<circle cx="189.8" cy="124.2" r="1.0" fill="#ffffff" opacity="0.8" />');
    }

    // 6. Sculpted Head Silhouette (Dynamic Face Structure Type)
    _appendHead(sb, config.faceShape, skin);

    // Forehead Bindi / Teep (Calibrated between eyebrows)
    if (config.accessories == 'bindi') {
      sb.writeln('<circle cx="130" cy="99" r="2.8" fill="#b91c1c" />');
      sb.writeln('<circle cx="130" cy="99" r="3.4" stroke="#f97316" stroke-width="0.6" fill="none" opacity="0.6" />');
    }

    // 7. Refined Vector Nose (Clean bridge-to-tip, no disconnected hook)
    _appendNose(sb, config.eyebrows);

    // 8. Beard (Sculpted along lower jaw and chin)
    if (config.beard != 'none') {
      _appendBeard(sb, config.beard, beard, config.faceShape);
    }

    // 9. Mouth & Expression
    _appendMouth(sb, config.mouth);

    // 10. Moustache (Layered crisply over upper lip above mouth)
    if (config.moustache != 'none') {
      _appendMoustache(sb, config.moustache, moustache);
    }

    // 11. Eyebrows
    _appendEyebrows(sb, config.eyebrows, hair);

    // 11. Eyes (Defined almond eyelids with focused irises)
    if (isBlinking) {
      sb.writeln('<path d="M 88 116 C 94 123 115 123 121 116" stroke="#18181b" stroke-width="3.2" fill="none" stroke-linecap="round" />');
      sb.writeln('<path d="M 139 116 C 145 123 166 123 172 116" stroke="#18181b" stroke-width="3.2" fill="none" stroke-linecap="round" />');
    } else {
      _appendEyes(sb, config.eyes);
    }

    // 12. Base Hair
    if (config.hat != 'hijab' && config.hat != 'turban' && config.hat != 'helmetMoto') {
      if (hasCrownHat) {
        sb.writeln('<g clip-path="url(#hairUnderHatClip)">');
        _appendHair(sb, config.hair, hair, cloth, skin);
        sb.writeln('</g>');
      } else {
        _appendHair(sb, config.hair, hair, cloth, skin);
      }
    }

    // 13. Hat / Headwear
    if (config.hat != 'none') {
      _appendHat(sb, config.hat, hat, cloth, skin);
    }

    // 14. Glasses / Eyewear (Rendered crisply on face & eyes)
    if (config.glasses != 'none') {
      _appendGlasses(sb, config.glasses, glass);
    }

    // 15. Outer Over-Ear Accessories (Headphones)
    if (config.accessories == 'headphones') {
      _appendHeadphones(sb, acc);
    }

    sb.writeln('</g>'); // close clip-path
    sb.writeln('</svg>');

    return sb.toString();
  }

  static void _appendNeckShadow(StringBuffer sb, String faceShape) {
    switch (faceShape) {
      case 'slenderOval':
        sb.writeln('<path d="M 109 166 C 121 182 139 182 151 166 L 151 176 C 139 191 121 191 109 176 Z" fill="#000000" opacity="0.12" />');
        break;
      case 'softRound':
        sb.writeln('<path d="M 109 166 C 117 180 143 180 151 166 L 151 176 C 143 189 117 189 109 176 Z" fill="#000000" opacity="0.12" />');
        break;
      case 'diamondSharp':
        sb.writeln('<path d="M 109 166 C 122 182 138 182 151 166 L 151 176 C 138 192 122 192 109 176 Z" fill="#000000" opacity="0.12" />');
        break;
      case 'chiseledSquare':
      default:
        sb.writeln('<path d="M 109 166 C 119 181 141 181 151 166 L 151 176 C 141 190 119 190 109 176 Z" fill="#000000" opacity="0.12" />');
        break;
    }
  }

  static void _appendHead(StringBuffer sb, String faceShape, String skin) {
    switch (faceShape) {
      case 'slenderOval':
        sb.writeln('<path d="M 77 100 C 77 38 183 38 183 100 C 183 126 175 150 165 164 C 153 176 140 181 130 181 C 120 181 107 176 95 164 C 85 150 77 126 77 100 Z" fill="$skin" />');
        break;
      case 'softRound':
        sb.writeln('<path d="M 75 100 C 75 36 185 36 185 100 C 185 130 174 170 146 179 C 138 180 122 180 114 179 C 86 170 75 130 75 100 Z" fill="$skin" />');
        break;
      case 'diamondSharp':
        sb.writeln('<path d="M 78 100 C 78 38 182 38 182 100 C 182 122 174 146 160 162 C 146 176 138 182 130 182 C 122 182 114 176 100 162 C 86 146 78 122 78 100 Z" fill="$skin" />');
        break;
      case 'chiseledSquare':
      default:
        sb.writeln('<path d="M 75 100 C 75 36 185 36 185 100 C 185 126 181 144 176 151 C 170 162 154 179 140 180 L 120 180 C 106 179 90 162 84 151 C 79 144 75 126 75 100 Z" fill="$skin" />');
        break;
    }
  }

  static void _appendNose(StringBuffer sb, String eyebrows) {
    final isAngry = eyebrows.contains('angry') || eyebrows.contains('determined');
    if (isAngry) {
      sb.writeln('<path d="M 120 106 Q 125 111 127 114" stroke="#26262a" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.60" />');
      sb.writeln('<path d="M 140 106 Q 133 111 128 114" stroke="#26262a" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.60" />');
    }
    // High-definition centered bridge-to-tip contour with left nostril wing accent
    sb.writeln('<path d="M 127 110 L 127 129 C 127 134 133 135 136 130" stroke="#4a4a4f" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" fill="none" />');
    sb.writeln('<path d="M 121 131 C 123 133 125 132 126 130" stroke="#4a4a4f" stroke-width="2.0" stroke-linecap="round" fill="none" opacity="0.45" />');
  }

  static void _appendClothing(StringBuffer sb, String clothing, String clothColor) {
    switch (clothing) {
      case 'shirtScoopNeck':
        sb.writeln('<path d="M 36 260 C 52 210 84 196 109 192 C 114 192 116 212 130 212 C 144 212 146 192 151 192 C 176 196 208 210 224 260 Z" fill="$clothColor" />');
        sb.writeln('<path d="M 109 192 C 114 192 116 212 130 212 C 144 212 146 192 151 192" stroke="#000000" stroke-width="2.6" fill="none" opacity="0.18" />');
        sb.writeln('<path d="M 120 204 Q 130 207 140 204" stroke="#000000" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.14" />');
        break;

      case 'hoodie':
        sb.writeln('<path d="M 36 260 C 52 210 84 196 109 192 C 119 202 141 202 151 192 C 176 196 208 210 224 260 Z" fill="$clothColor" />');
        sb.writeln('<path d="M 103 192 C 101 212 117 224 130 224 C 143 224 159 212 157 192 C 147 202 113 202 103 192 Z" fill="$clothColor" />');
        sb.writeln('<path d="M 111 192 C 117 202 143 202 149 192 C 141 198 119 198 111 192 Z" fill="#000000" opacity="0.22" />');
        sb.writeln('<line x1="123" y1="216" x2="123" y2="240" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" opacity="0.85" />');
        sb.writeln('<circle cx="123" cy="241" r="2.2" fill="#d0d0d0" />');
        sb.writeln('<line x1="137" y1="216" x2="137" y2="240" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" opacity="0.85" />');
        sb.writeln('<circle cx="137" cy="241" r="2.2" fill="#d0d0d0" />');
        break;

      case 'blazerAndShirt':
        sb.writeln('<path d="M 36 260 C 52 210 84 196 109 192 C 119 202 141 202 151 192 C 176 196 208 210 224 260 Z" fill="#ffffff" />');
        sb.writeln('<polygon points="128,196 132,196 135,232 130,238 125,232" fill="#086057" />');
        sb.writeln('<path d="M 36 260 C 52 210 84 196 109 192 L 128 250 L 70 260 Z" fill="$clothColor" />');
        sb.writeln('<path d="M 224 260 C 208 210 176 196 151 192 L 132 250 L 190 260 Z" fill="$clothColor" />');
        break;

      case 'collarAndSweater':
        sb.writeln('<path d="M 36 260 C 52 210 84 196 109 192 C 119 202 141 202 151 192 C 176 196 208 210 224 260 Z" fill="$clothColor" />');
        sb.writeln('<polygon points="115,192 130,212 145,192" fill="#ffffff" />');
        sb.writeln('<polygon points="110,190 128,210 130,192" fill="#ffffff" />');
        sb.writeln('<polygon points="150,190 132,210 130,192" fill="#f2f2f2" />');
        break;

      case 'graphicShirt':
        sb.writeln('<path d="M 36 260 C 52 210 84 196 109 192 C 119 202 141 202 151 192 C 176 196 208 210 224 260 Z" fill="$clothColor" />');
        sb.writeln('<circle cx="130" cy="232" r="14" fill="#ffffff" opacity="0.25" />');
        sb.writeln('<polygon points="130,222 124,233 129,233 127,242 135,230 130,230" fill="#ffffff" opacity="0.9" />');
        break;

      case 'shirtCrewNeck':
      default:
        sb.writeln('<path d="M 36 260 C 52 210 84 196 109 192 C 119 202 141 202 151 192 C 176 196 208 210 224 260 Z" fill="$clothColor" />');
        sb.writeln('<path d="M 109 192 C 117 206 143 206 151 192" stroke="#000000" stroke-width="3.0" fill="none" opacity="0.18" />');
        break;
    }
  }

  static void _appendBeard(StringBuffer sb, String beard, String beardColor, String faceShape) {
    switch (beard) {
      case 'stubble':
        // Modern 5 o'clock shadow gradient + organic micro-stippling along jaw, chin, and lower lip
        sb.writeln('<path d="M 82 144 C 82 170 94 180 120 181 L 140 181 C 166 180 178 170 178 144 C 172 156 160 174 130 174 C 100 174 88 156 82 144 Z" fill="$beardColor" opacity="0.35" />');
        sb.writeln('<g fill="$beardColor" opacity="0.45">');
        // Left jaw & cheek stipples
        sb.writeln('<circle cx="92" cy="152" r="0.9" /><circle cx="98" cy="156" r="0.9" /><circle cx="104" cy="162" r="0.9" />');
        sb.writeln('<circle cx="96" cy="148" r="0.8" /><circle cx="102" cy="154" r="0.8" /><circle cx="108" cy="168" r="0.9" />');
        // Chin & soul patch area stipples
        sb.writeln('<circle cx="122" cy="168" r="1.0" /><circle cx="128" cy="170" r="1.1" /><circle cx="134" cy="170" r="1.1" /><circle cx="138" cy="168" r="1.0" />');
        sb.writeln('<circle cx="120" cy="174" r="0.9" /><circle cx="126" cy="176" r="1.0" /><circle cx="132" cy="176" r="1.0" /><circle cx="138" cy="174" r="0.9" />');
        sb.writeln('<circle cx="130" cy="163" r="0.9" />');
        // Right jaw & cheek stipples
        sb.writeln('<circle cx="168" cy="152" r="0.9" /><circle cx="162" cy="156" r="0.9" /><circle cx="156" cy="162" r="0.9" />');
        sb.writeln('<circle cx="164" cy="148" r="0.8" /><circle cx="158" cy="154" r="0.8" /><circle cx="152" cy="168" r="0.9" />');
        sb.writeln('</g>');
        break;

      case 'chinStrap':
        // Crisp sculpted strap running from sideburns down the jaw edge, hugging the chin
        sb.writeln('<path d="M 80 134 C 81 154 90 176 120 180.5 L 140 180.5 C 170 176 179 154 180 134 C 176 150 166 170 138 174 L 122 174 C 94 170 84 150 80 134 Z" fill="$beardColor" opacity="0.95" />');
        sb.writeln('<path d="M 84 136 C 88 152 98 171 122 174.5 L 138 174.5 C 162 171 172 152 176 136" stroke="#ffffff" stroke-width="0.7" fill="none" opacity="0.18" />');
        break;

      case 'goatee':
        // Clean chin puff with soul patch beneath the lower lip; cheeks shaved clean
        sb.writeln('<path d="M 127 158 Q 130 157 133 158 L 131 164 Q 130 165 129 164 Z" fill="$beardColor" />');
        sb.writeln('<path d="M 118 165 C 118 165 122 179 130 181 C 138 179 142 165 142 165 C 138 169 135 171 130 171 C 125 171 122 169 118 165 Z" fill="$beardColor" />');
        sb.writeln('<path d="M 125 172 Q 130 178 135 172" stroke="#ffffff" stroke-width="0.8" fill="none" opacity="0.22" />');
        break;

      case 'beard':
      case 'beardMedium':
        // Boxed medium beard with sculpted jaw silhouette, trimmed cheek curves, and soul patch
        sb.writeln('<path d="M 80 132 C 82 165 92 181 120 182 L 140 182 C 168 181 178 165 180 132 C 174 148 160 158 148 162 C 146 168 142 172 130 172 C 118 172 114 168 112 162 C 100 158 86 148 80 132 Z" fill="$beardColor" opacity="0.94" />');
        sb.writeln('<path d="M 127 158 Q 130 157 133 158 L 132 166 L 128 166 Z" fill="$beardColor" />');
        sb.writeln('<path d="M 83 134 Q 96 150 112 162" stroke="#ffffff" stroke-width="0.8" fill="none" opacity="0.18" />');
        sb.writeln('<path d="M 177 134 Q 164 150 148 162" stroke="#ffffff" stroke-width="0.8" fill="none" opacity="0.18" />');
        break;

      case 'beardMajestic':
        // Lush full majestic beard extending beyond chin with layered volumetric shading
        sb.writeln('<path d="M 78 130 C 80 172 90 188 118 188 L 142 188 C 170 188 180 172 182 130 C 175 146 162 155 148 160 C 144 167 140 170 130 170 C 120 170 116 167 112 160 C 98 155 85 146 78 130 Z" fill="$beardColor" opacity="0.96" />');
        sb.writeln('<path d="M 112 184 Q 130 193 148 184 Q 130 187 112 184 Z" fill="$beardColor" opacity="0.96" />');
        sb.writeln('<polygon points="126,158 134,158 132,166 128,166" fill="$beardColor" />');
        sb.writeln('<path d="M 118 172 Q 124 182 126 186" stroke="#ffffff" stroke-width="1.0" stroke-linecap="round" fill="none" opacity="0.22" />');
        sb.writeln('<path d="M 130 171 Q 130 182 130 187" stroke="#ffffff" stroke-width="1.1" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 142 172 Q 136 182 134 186" stroke="#ffffff" stroke-width="1.0" stroke-linecap="round" fill="none" opacity="0.22" />');
        break;

      case 'anchor':
        // Balbo / Anchor beard hugging lower jaw and chin tip with pointed soul patch
        sb.writeln('<path d="M 127 157 Q 130 156 133 157 L 131 165 L 129 165 Z" fill="$beardColor" />');
        sb.writeln('<path d="M 104 168 C 114 175 124 179 130 182 C 136 179 146 175 156 168 C 153 173 144 179 130 180 C 116 179 107 173 104 168 Z" fill="$beardColor" />');
        sb.writeln('<path d="M 125 168 Q 130 167 135 168 L 133 181 L 127 181 Z" fill="$beardColor" />');
        break;

      case 'none':
      default:
        break;
    }
  }

  static void _appendMoustache(StringBuffer sb, String moustache, String moustacheColor) {
    switch (moustache) {
      case 'pencil':
        // Ultra-sharp vintage dapper pencil line above upper lip
        sb.writeln('<path d="M 114 144 Q 121 143 128.5 144" stroke="$moustacheColor" stroke-width="2.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 131.5 144 Q 139 143 146 144" stroke="$moustacheColor" stroke-width="2.2" stroke-linecap="round" fill="none" />');
        break;

      case 'moustache':
      case 'classic':
        // Natural trimmed moustache sitting cleanly over upper lip
        sb.writeln('<path d="M 112 145 C 118 141 126 141 129.5 143 C 129.8 143.2 130.2 143.2 130.5 143 C 134 141 142 141 148 145 C 142 147 136 146.5 130 144.5 C 124 146.5 118 147 112 145 Z" fill="$moustacheColor" />');
        sb.writeln('<path d="M 117 143 Q 123 142 128 143" stroke="#ffffff" stroke-width="0.8" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 132 143 Q 137 142 143 143" stroke="#ffffff" stroke-width="0.8" stroke-linecap="round" fill="none" opacity="0.25" />');
        break;

      case 'moustacheFancy':
      case 'handlebar':
        // Iconic Royal Bengali Handlebar with upward flared wax curled tips
        sb.writeln('<path d="M 130 144 C 126 141 116 139 107 142 C 103 143 102 139 105 137 C 109 135 116 137 122 141 C 126 142.5 128.5 143.5 130 144 Z" fill="$moustacheColor" />');
        sb.writeln('<path d="M 130 144 C 134 141 144 139 153 142 C 157 143 158 139 155 137 C 151 135 144 137 138 141 C 134 142.5 131.5 143.5 130 144 Z" fill="$moustacheColor" />');
        sb.writeln('<path d="M 111 145 Q 130 141.5 149 145 Q 130 147 111 145 Z" fill="$moustacheColor" />');
        sb.writeln('<path d="M 105 137 Q 103 134 107 134" stroke="$moustacheColor" stroke-width="1.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 155 137 Q 157 134 153 134" stroke="$moustacheColor" stroke-width="1.8" stroke-linecap="round" fill="none" />');
        break;

      case 'chevron':
        // Dense, thick, angled chevron moustache covering the upper lip crest
        sb.writeln('<path d="M 111 147 C 114 140 125 139 130 142 C 135 139 146 140 149 147 C 143 148 137 147.5 130 146 C 123 147.5 117 148 111 147 Z" fill="$moustacheColor" />');
        sb.writeln('<line x1="130" y1="142" x2="130" y2="146" stroke="#000000" stroke-width="1.2" opacity="0.3" />');
        sb.writeln('<path d="M 116 144 L 118 146 M 122 143 L 124 145 M 138 143 L 136 145 M 144 144 L 142 146" stroke="#ffffff" stroke-width="0.7" opacity="0.2" />');
        break;

      case 'horseshoe':
        // Biker horseshoe moustache with downward vertical bars past mouth corners
        sb.writeln('<path d="M 112 146 Q 130 140 148 146 Q 130 144 112 146 Z" fill="$moustacheColor" />');
        sb.writeln('<path d="M 112 145 L 111 164 Q 115 164.5 117 163 L 117.5 146.5 Z" fill="$moustacheColor" />');
        sb.writeln('<path d="M 148 145 L 149 164 Q 145 164.5 143 163 L 142.5 146.5 Z" fill="$moustacheColor" />');
        break;

      case 'none':
      default:
        break;
    }
  }

  static void _appendMouth(StringBuffer sb, String mouth) {
    switch (mouth) {
      case 'grit':
        sb.writeln('<path d="M 114 147 Q 130 144 146 147 C 146 157 114 157 114 147 Z" fill="#ffffff" stroke="#18181b" stroke-width="2.4" stroke-linejoin="round" />');
        sb.writeln('<line x1="121" y1="147" x2="121" y2="155" stroke="#18181b" stroke-width="1.6" />');
        sb.writeln('<line x1="127" y1="146" x2="127" y2="156" stroke="#18181b" stroke-width="1.6" />');
        sb.writeln('<line x1="133" y1="146" x2="133" y2="156" stroke="#18181b" stroke-width="1.6" />');
        sb.writeln('<line x1="139" y1="147" x2="139" y2="155" stroke="#18181b" stroke-width="1.6" />');
        sb.writeln('<path d="M 122 161 Q 130 163 138 161" stroke="#18181b" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.5" />');
        break;

      case 'smirk':
        sb.writeln('<path d="M 116 150 Q 126 153 145 145" stroke="#18181b" stroke-width="2.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 144 143 Q 146 146 144 149" stroke="#18181b" stroke-width="2.0" stroke-linecap="round" fill="none" opacity="0.7" />');
        sb.writeln('<path d="M 124 156 Q 131 157 138 154" stroke="#18181b" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.20" />');
        break;

      case 'smileTeeth':
        sb.writeln('<path d="M 114 146 Q 130 162 146 146 Z" fill="#ffffff" stroke="#18181b" stroke-width="2.4" stroke-linejoin="round" />');
        sb.writeln('<path d="M 115 146 Q 130 148 145 146" stroke="#18181b" stroke-width="1.8" fill="none" />');
        sb.writeln('<line x1="130" y1="147" x2="130" y2="153" stroke="#18181b" stroke-width="1.4" opacity="0.5" />');
        break;

      case 'smile':
        sb.writeln('<path d="M 116 148 Q 130 158 144 148" stroke="#18181b" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 115 147 Q 116 149 115 151" stroke="#18181b" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.5" />');
        sb.writeln('<path d="M 145 147 Q 144 149 145 151" stroke="#18181b" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.5" />');
        sb.writeln('<path d="M 124 157 Q 130 159 136 157" stroke="#8c6239" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.25" />');
        break;

      case 'twinkle':
        sb.writeln('<path d="M 114 146 Q 130 164 146 146 Z" fill="#ffffff" stroke="#18181b" stroke-width="2.4" stroke-linejoin="round" />');
        sb.writeln('<path d="M 120 155 Q 130 164 140 155 Z" fill="#ff5252" />');
        break;

      case 'eating':
      case 'open':
        sb.writeln('<circle cx="130" cy="150" r="6.0" fill="#18181b" />');
        break;

      case 'concerned':
      case 'sad':
        sb.writeln('<path d="M 118 154 Q 130 146 142 154" stroke="#18181b" stroke-width="2.6" stroke-linecap="round" fill="none" />');
        break;

      case 'default':
      default:
        sb.writeln('<path d="M 120 149 L 140 149" stroke="#18181b" stroke-width="2.6" stroke-linecap="round" />');
        break;
    }
  }

  static void _appendEyebrows(StringBuffer sb, String eyebrows, String hairColor) {
    if (eyebrows.contains('angry') || eyebrows == 'angryFierce') {
      sb.writeln('<path d="M 91 95 L 122 102" stroke="$hairColor" stroke-width="4.0" stroke-linecap="round" />');
      sb.writeln('<path d="M 138 102 L 169 95" stroke="$hairColor" stroke-width="4.0" stroke-linecap="round" />');
      sb.writeln('<path d="M 119 98 L 121 102" stroke="$hairColor" stroke-width="1.6" stroke-linecap="round" opacity="0.5" />');
      sb.writeln('<path d="M 141 102 L 139 98" stroke="$hairColor" stroke-width="1.6" stroke-linecap="round" opacity="0.5" />');
    } else if (eyebrows.contains('determined')) {
      sb.writeln('<path d="M 91 96 L 122 100" stroke="$hairColor" stroke-width="3.8" stroke-linecap="round" />');
      sb.writeln('<path d="M 138 100 L 169 96" stroke="$hairColor" stroke-width="3.8" stroke-linecap="round" />');
    } else if (eyebrows.contains('raised') || eyebrows.contains('Excited')) {
      sb.writeln('<path d="M 90 93 C 100 86 111 86 120 92" stroke="$hairColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
      sb.writeln('<path d="M 170 93 C 160 86 149 86 140 92" stroke="$hairColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
    } else {
      // Natural, balanced arched eyebrows comfortably seated above eyes
      sb.writeln('<path d="M 119 99 C 111 93 101 93 90 98" stroke="$hairColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
      sb.writeln('<path d="M 141 99 C 149 93 159 93 170 98" stroke="$hairColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
    }
  }

  static void _appendEyes(StringBuffer sb, String eyeType) {
    switch (eyeType) {
      case 'confident':
        // Left Eye - Sharp, charismatic almond with sleek cat-wing liner & dual catchlights
        sb.writeln('<path d="M 89 116 C 94 108 114 108 121 116 C 115 124 94 124 89 116 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 92 106 C 99 103 112 103 118 107" stroke="#18181b" stroke-width="1.2" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<ellipse cx="106" cy="116" rx="5.4" ry="5.8" fill="#0f172a" />');
        sb.writeln('<ellipse cx="106" cy="116" rx="3.4" ry="3.6" fill="#000000" />');
        sb.writeln('<circle cx="108" cy="113.8" r="1.9" fill="#ffffff" />');
        sb.writeln('<circle cx="104" cy="118" r="0.9" fill="#ffffff" opacity="0.85" />');
        sb.writeln('<path d="M 87 114 C 93 107 114 107 121 115" stroke="#18181b" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 87 114 L 85 112.5" stroke="#18181b" stroke-width="1.8" stroke-linecap="round" />');
        sb.writeln('<path d="M 91 118 C 96 123 114 123 119 117" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.55" />');

        // Right Eye - Symmetrical Winged Confident Gaze
        sb.writeln('<path d="M 139 116 C 146 108 166 108 171 116 C 166 124 146 124 139 116 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 142 107 C 148 103 161 103 168 106" stroke="#18181b" stroke-width="1.2" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<ellipse cx="154" cy="116" rx="5.4" ry="5.8" fill="#0f172a" />');
        sb.writeln('<ellipse cx="154" cy="116" rx="3.4" ry="3.6" fill="#000000" />');
        sb.writeln('<circle cx="156" cy="113.8" r="1.9" fill="#ffffff" />');
        sb.writeln('<circle cx="152" cy="118" r="0.9" fill="#ffffff" opacity="0.85" />');
        sb.writeln('<path d="M 139 115 C 146 107 167 107 173 114" stroke="#18181b" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 173 114 L 175 112.5" stroke="#18181b" stroke-width="1.8" stroke-linecap="round" />');
        sb.writeln('<path d="M 141 117 C 146 123 164 123 169 118" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.55" />');
        break;

      case 'intense':
        // Left Eye - Narrowed, razor-sharp exam focus (Piercing Hunter Eyes)
        sb.writeln('<path d="M 89 116 C 97 111 114 111 121 116 C 114 121 96 121 89 116 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 92 108 L 118 110" stroke="#18181b" stroke-width="1.4" stroke-linecap="round" opacity="0.35" />');
        sb.writeln('<ellipse cx="106" cy="116" rx="4.8" ry="4.4" fill="#09090b" />');
        sb.writeln('<circle cx="106" cy="116" r="2.0" fill="#000000" />');
        sb.writeln('<circle cx="107.5" cy="114.8" r="1.2" fill="#ffffff" />');
        sb.writeln('<path d="M 88 116 L 102 112 L 122 116" stroke="#18181b" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round" fill="none" />');
        sb.writeln('<path d="M 90 117 C 96 121 113 121 120 117" stroke="#18181b" stroke-width="1.4" stroke-linecap="round" fill="none" opacity="0.65" />');

        // Right Eye - Laser Focused
        sb.writeln('<path d="M 139 116 C 146 111 163 111 171 116 C 164 121 146 121 139 116 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 142 110 L 168 108" stroke="#18181b" stroke-width="1.4" stroke-linecap="round" opacity="0.35" />');
        sb.writeln('<ellipse cx="154" cy="116" rx="4.8" ry="4.4" fill="#09090b" />');
        sb.writeln('<circle cx="154" cy="116" r="2.0" fill="#000000" />');
        sb.writeln('<circle cx="155.5" cy="114.8" r="1.2" fill="#ffffff" />');
        sb.writeln('<path d="M 138 116 L 158 112 L 172 116" stroke="#18181b" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round" fill="none" />');
        sb.writeln('<path d="M 140 117 C 147 121 164 121 170 117" stroke="#18181b" stroke-width="1.4" stroke-linecap="round" fill="none" opacity="0.65" />');
        sb.writeln('<path d="M 127 114 L 133 114" stroke="#18181b" stroke-width="1.2" stroke-linecap="round" opacity="0.30" />');
        break;

      case 'happy':
        // Cheerful smiling crescent anime arcs with soft lash flicks & rosy cheek blush
        sb.writeln('<path d="M 88 117 C 94 107 115 107 121 117" stroke="#18181b" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 88 117 L 85 114.5" stroke="#18181b" stroke-width="2.0" stroke-linecap="round" />');
        sb.writeln('<ellipse cx="105" cy="125" rx="6.5" ry="3.2" fill="#f43f5e" opacity="0.28" />');
        sb.writeln('<path d="M 101 124 L 103 127" stroke="#f43f5e" stroke-width="1.0" stroke-linecap="round" opacity="0.45" />');
        sb.writeln('<path d="M 106 124 L 108 127" stroke="#f43f5e" stroke-width="1.0" stroke-linecap="round" opacity="0.45" />');

        sb.writeln('<path d="M 139 117 C 145 107 166 107 172 117" stroke="#18181b" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 172 117 L 175 114.5" stroke="#18181b" stroke-width="2.0" stroke-linecap="round" />');
        sb.writeln('<ellipse cx="155" cy="125" rx="6.5" ry="3.2" fill="#f43f5e" opacity="0.28" />');
        sb.writeln('<path d="M 152 124 L 154 127" stroke="#f43f5e" stroke-width="1.0" stroke-linecap="round" opacity="0.45" />');
        sb.writeln('<path d="M 157 124 L 159 127" stroke="#f43f5e" stroke-width="1.0" stroke-linecap="round" opacity="0.45" />');
        break;

      case 'wink':
        // Left Eye Open: Wide, bright & sparkling with twin glints & mini star
        sb.writeln('<path d="M 89 116 C 94 107 114 107 121 116 C 115 124 94 124 89 116 Z" fill="#ffffff" />');
        sb.writeln('<ellipse cx="105.5" cy="116" rx="5.4" ry="5.8" fill="#18181b" />');
        sb.writeln('<circle cx="107.8" cy="113.8" r="2.0" fill="#ffffff" />');
        sb.writeln('<circle cx="103.5" cy="118.2" r="1.0" fill="#ffffff" opacity="0.85" />');
        sb.writeln('<path d="M 107.8 112 L 107.8 115.5 M 106 113.8 L 109.5 113.8" stroke="#ffffff" stroke-width="0.6" stroke-linecap="round" />');
        sb.writeln('<path d="M 88 115 C 94 107 114 107 122 115" stroke="#18181b" stroke-width="3.0" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 90 118 C 95 124 114 124 120 117" stroke="#18181b" stroke-width="1.2" stroke-linecap="round" fill="none" opacity="0.45" />');

        // Right Eye Wink: Playful downward curved arc with cute double lash flick & blush
        sb.writeln('<path d="M 139 115 C 146 123 164 123 171 115" stroke="#18181b" stroke-width="3.6" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 171 115 L 175 113" stroke="#18181b" stroke-width="2.0" stroke-linecap="round" />');
        sb.writeln('<path d="M 170 118 L 174 119" stroke="#18181b" stroke-width="1.5" stroke-linecap="round" opacity="0.75" />');
        sb.writeln('<ellipse cx="155" cy="124" rx="5.5" ry="2.8" fill="#f43f5e" opacity="0.25" />');
        break;

      case 'surprised':
        // Big round shock / anime astonished revelation eyes (O_O)
        sb.writeln('<circle cx="105" cy="116" r="9.0" fill="#ffffff" stroke="#18181b" stroke-width="2.6" />');
        sb.writeln('<circle cx="105" cy="116" r="3.4" fill="#18181b" />');
        sb.writeln('<circle cx="106" cy="115" r="1.1" fill="#ffffff" />');
        sb.writeln('<path d="M 92 105 L 89 102" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" opacity="0.45" />');
        sb.writeln('<path d="M 105 103 L 105 99" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" opacity="0.45" />');

        sb.writeln('<circle cx="155" cy="116" r="9.0" fill="#ffffff" stroke="#18181b" stroke-width="2.6" />');
        sb.writeln('<circle cx="155" cy="116" r="3.4" fill="#18181b" />');
        sb.writeln('<circle cx="156" cy="115" r="1.1" fill="#ffffff" />');
        sb.writeln('<path d="M 168 105 L 171 102" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" opacity="0.45" />');
        sb.writeln('<path d="M 155 103 L 155 99" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" opacity="0.45" />');
        break;

      case 'eyeRoll':
        // Sassy Eye-Roll (looking up and to the corner in disbelief / sarcasm)
        sb.writeln('<path d="M 89 117 Q 105 110 121 117 L 120 119 Q 105 121 90 119 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 88 115 Q 105 109 122 115" stroke="#18181b" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<ellipse cx="110" cy="113" rx="4.2" ry="4.2" fill="#18181b" />');
        sb.writeln('<circle cx="111" cy="112" r="1.1" fill="#ffffff" />');
        sb.writeln('<path d="M 91 119 L 119 119" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" opacity="0.5" />');
        sb.writeln('<path d="M 86 111 L 89 113" stroke="#18181b" stroke-width="1.1" stroke-linecap="round" opacity="0.35" />');

        sb.writeln('<path d="M 139 117 Q 155 110 171 117 L 170 119 Q 155 121 140 119 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 138 115 Q 155 109 172 115" stroke="#18181b" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<ellipse cx="160" cy="113" rx="4.2" ry="4.2" fill="#18181b" />');
        sb.writeln('<circle cx="161" cy="112" r="1.1" fill="#ffffff" />');
        sb.writeln('<path d="M 141 119 L 169 119" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" opacity="0.5" />');
        break;

      case 'sparkle':
        // Dazzling anime starry eyes with 4-point diamond star pupils (perfect proportions, no spiky corners)
        sb.writeln('<path d="M 89 116 C 94 107 114 107 121 116 C 115 125 94 125 89 116 Z" fill="#ffffff" />');
        sb.writeln('<ellipse cx="105.5" cy="116" rx="5.8" ry="6.4" fill="#0f172a" />');
        sb.writeln('<path d="M 105.5 111.5 Q 105.5 116 101 116 Q 105.5 116 105.5 120.5 Q 105.5 116 110 116 Q 105.5 116 105.5 111.5 Z" fill="#38bdf8" />');
        sb.writeln('<circle cx="105.5" cy="116" r="1.6" fill="#ffffff" />');
        sb.writeln('<circle cx="108" cy="113.5" r="1.3" fill="#ffffff" />');
        sb.writeln('<circle cx="103" cy="118.5" r="0.8" fill="#ffffff" opacity="0.8" />');
        sb.writeln('<path d="M 87 115 C 93 106 114 106 122 115" stroke="#18181b" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 90 118 C 95 124 114 124 120 118" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.45" />');

        sb.writeln('<path d="M 139 116 C 146 107 166 107 171 116 C 166 125 146 125 139 116 Z" fill="#ffffff" />');
        sb.writeln('<ellipse cx="154.5" cy="116" rx="5.8" ry="6.4" fill="#0f172a" />');
        sb.writeln('<path d="M 154.5 111.5 Q 154.5 116 150 116 Q 154.5 116 154.5 120.5 Q 154.5 116 159 116 Q 154.5 116 154.5 111.5 Z" fill="#38bdf8" />');
        sb.writeln('<circle cx="154.5" cy="116" r="1.6" fill="#ffffff" />');
        sb.writeln('<circle cx="157" cy="113.5" r="1.3" fill="#ffffff" />');
        sb.writeln('<circle cx="152" cy="118.5" r="0.8" fill="#ffffff" opacity="0.8" />');
        sb.writeln('<path d="M 138 115 C 146 106 167 106 173 115" stroke="#18181b" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 140 118 C 146 124 165 124 170 118" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.45" />');
        break;

      case 'sleepy':
        // Drowsy, chill half-asleep eyes (late-night exam prep)
        sb.writeln('<path d="M 89 117 C 96 114 114 114 121 117 C 117 124 93 124 89 117 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 88 116 C 95 114 115 114 122 116" stroke="#18181b" stroke-width="3.4" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 91 111 C 98 109 112 109 119 111" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.35" />');
        sb.writeln('<path d="M 101 116 C 101 121 111 121 111 116 Z" fill="#18181b" />');
        sb.writeln('<circle cx="106" cy="118" r="0.9" fill="#ffffff" opacity="0.8" />');
        sb.writeln('<path d="M 92 124 C 98 127 112 127 118 124" stroke="#8c6239" stroke-width="1.1" stroke-linecap="round" fill="none" opacity="0.30" />');

        sb.writeln('<path d="M 139 117 C 146 114 164 114 171 117 C 167 124 143 124 139 117 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 138 116 C 145 114 165 114 172 116" stroke="#18181b" stroke-width="3.4" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 141 111 C 148 109 162 109 169 111" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.35" />');
        sb.writeln('<path d="M 151 116 C 151 121 161 121 161 116 Z" fill="#18181b" />');
        sb.writeln('<circle cx="156" cy="118" r="0.9" fill="#ffffff" opacity="0.8" />');
        sb.writeln('<path d="M 142 124 C 148 127 162 127 168 124" stroke="#8c6239" stroke-width="1.1" stroke-linecap="round" fill="none" opacity="0.30" />');
        break;

      case 'cool':
        // Sleek side-glance, confident knowing smirk vibe
        sb.writeln('<path d="M 89 116 C 96 111 114 111 121 116 C 115 121 95 121 89 116 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 88 115 C 95 110 115 110 121 115" stroke="#18181b" stroke-width="3.0" stroke-linecap="round" fill="none" />');
        sb.writeln('<ellipse cx="113" cy="116" rx="4.5" ry="4.8" fill="#18181b" />');
        sb.writeln('<circle cx="114.5" cy="114.5" r="1.4" fill="#ffffff" />');
        sb.writeln('<path d="M 91 117 C 97 121 113 121 119 116" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.45" />');

        sb.writeln('<path d="M 139 116 C 146 111 164 111 171 116 C 165 121 145 121 139 116 Z" fill="#ffffff" />');
        sb.writeln('<path d="M 139 115 C 145 110 165 110 172 115" stroke="#18181b" stroke-width="3.0" stroke-linecap="round" fill="none" />');
        sb.writeln('<ellipse cx="163" cy="116" rx="4.5" ry="4.8" fill="#18181b" />');
        sb.writeln('<circle cx="164.5" cy="114.5" r="1.4" fill="#ffffff" />');
        sb.writeln('<path d="M 141 116 C 147 121 163 121 169 117" stroke="#18181b" stroke-width="1.3" stroke-linecap="round" fill="none" opacity="0.45" />');
        break;

      case 'cryingJoy':
        // Laughing squeezed eyes with tears of joy on outer corners
        sb.writeln('<path d="M 88 117 C 94 108 115 108 121 117" stroke="#18181b" stroke-width="3.6" stroke-linecap="round" fill="none" />');
        sb.writeln('<circle cx="85" cy="120" r="2.2" fill="#38bdf8" />');
        sb.writeln('<circle cx="84.3" cy="119.3" r="0.7" fill="#ffffff" />');
        sb.writeln('<ellipse cx="105" cy="125" rx="5.5" ry="2.8" fill="#f43f5e" opacity="0.25" />');

        sb.writeln('<path d="M 139 117 C 145 108 166 108 172 117" stroke="#18181b" stroke-width="3.6" stroke-linecap="round" fill="none" />');
        sb.writeln('<circle cx="175" cy="120" r="2.2" fill="#38bdf8" />');
        sb.writeln('<circle cx="175.7" cy="119.3" r="0.7" fill="#ffffff" />');
        sb.writeln('<ellipse cx="155" cy="125" rx="5.5" ry="2.8" fill="#f43f5e" opacity="0.25" />');
        break;

      case 'default':
      default:
        // Natural, warm, friendly balanced almond eyes
        sb.writeln('<path d="M 89 116 C 94 109 114 109 121 116 C 115 123 94 123 89 116 Z" fill="#ffffff" />');
        sb.writeln('<circle cx="106" cy="116" r="5.0" fill="#1f2937" />');
        sb.writeln('<circle cx="107.8" cy="114" r="1.7" fill="#ffffff" />');
        sb.writeln('<circle cx="104.2" cy="118" r="0.7" fill="#ffffff" opacity="0.6" />');
        sb.writeln('<path d="M 88 116 C 95 109 115 109 121 116" stroke="#18181b" stroke-width="2.6" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 91 118 C 96 122 114 122 119 118" stroke="#18181b" stroke-width="1.2" stroke-linecap="round" fill="none" opacity="0.35" />');

        sb.writeln('<path d="M 139 116 C 146 109 166 109 171 116 C 166 123 146 123 139 116 Z" fill="#ffffff" />');
        sb.writeln('<circle cx="154" cy="116" r="5.0" fill="#1f2937" />');
        sb.writeln('<circle cx="155.8" cy="114" r="1.7" fill="#ffffff" />');
        sb.writeln('<circle cx="152.2" cy="118" r="0.7" fill="#ffffff" opacity="0.6" />');
        sb.writeln('<path d="M 139 116 C 145 109 165 109 172 116" stroke="#18181b" stroke-width="2.6" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 141 118 C 146 122 164 122 169 118" stroke="#18181b" stroke-width="1.2" stroke-linecap="round" fill="none" opacity="0.35" />');
        break;
    }
  }

  static void _appendBackHair(StringBuffer sb, String hairStyle, String hairColor) {
    switch (hairStyle) {
      case 'sideChignon':
        sb.writeln('<circle cx="198" cy="146" r="25" fill="$hairColor" />');
        sb.writeln('<circle cx="198" cy="146" r="19" fill="#000000" opacity="0.22" />');
        sb.writeln('<path d="M 182 134 Q 200 128 216 142 Q 208 160 186 156" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 188 144 Q 202 138 212 148" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.20" />');
        sb.writeln('<circle cx="184" cy="132" r="3.5" fill="#f59e0b" />');
        break;

      case 'bob':
        sb.writeln('<path d="M 60 100 C 56 130 56 170 80 184 L 180 184 C 204 170 204 130 200 100 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 60 154 C 66 178 100 188 130 188 C 160 188 194 178 200 154 Z" fill="#000000" opacity="0.28" />');
        break;

      case 'bun':
        sb.writeln('<circle cx="130" cy="22" r="23" fill="$hairColor" />');
        sb.writeln('<circle cx="130" cy="22" r="17" fill="#000000" opacity="0.22" />');
        sb.writeln('<path d="M 114 14 Q 130 8 146 14 Q 150 28 130 30" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 120 20 Q 132 14 142 20" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.22" />');
        sb.writeln('<rect x="116" y="36" width="28" height="7" rx="3.5" fill="#ec4899" />');
        sb.writeln('<rect x="120" y="38" width="20" height="2" rx="1" fill="#ffffff" opacity="0.40" />');
        break;

      case 'curly':
        sb.writeln('<path d="M 54 100 C 42 140 44 184 62 212 C 70 224 88 224 92 206 C 96 178 88 144 80 120 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 206 100 C 218 140 216 184 198 212 C 190 224 172 224 168 206 C 164 178 172 144 180 120 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 54 160 C 44 180 50 208 64 222" stroke="#000000" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 206 160 C 216 180 210 208 196 222" stroke="#000000" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.25" />');
        break;

      case 'curvy':
        sb.writeln('<path d="M 52 110 C 42 148 44 192 60 228 C 70 242 90 242 96 222 C 102 180 90 148 80 120 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 208 110 C 218 148 216 192 200 228 C 190 242 170 242 164 222 C 158 180 170 148 180 120 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 56 160 Q 48 190 64 220" stroke="#000000" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 204 160 Q 212 190 196 220" stroke="#000000" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.25" />');
        break;

      default:
        break;
    }
  }

  static void _appendHair(StringBuffer sb, String hairStyle, String hairColor, String clothColor, String skinColor) {
    switch (hairStyle) {
      case 'modernQuiff':
        sb.writeln('<path d="M 78 96 C 88 103 104 105 130 105 C 156 105 172 103 182 96 C 172 90 152 87 130 87 C 104 87 88 90 78 96 Z" fill="#000000" opacity="0.12" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 32 94 14 142 14 C 178 14 190 36 190 70 C 190 94 188 102 186 114 C 182 114 180 104 180 96 C 172 88 152 86 130 86 C 104 86 88 88 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 82 38 C 104 10 158 6 192 26 C 174 16 120 14 90 32 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 94 26 C 122 10 166 10 188 24 C 160 14 118 14 94 26 Z" fill="#000000" opacity="0.25" />');
        sb.writeln('<path d="M 80 96 C 96 90 120 88 138 88 C 120 86 96 88 80 96 Z" fill="#000000" opacity="0.20" />');
        sb.writeln('<path d="M 112 66 C 122 42 150 28 180 32" stroke="#000000" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 92 70 C 102 48 126 36 156 38" stroke="#000000" stroke-width="2.0" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 136 70 C 146 52 166 42 184 46" stroke="#000000" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.20" />');
        sb.writeln('<path d="M 100 28 Q 138 14 178 26" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 110 40 Q 144 28 172 42" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.22" />');
        sb.writeln('<path d="M 76 100 L 76 112" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" opacity="0.25" />');
        break;

      case 'sideChignon':
        sb.writeln('<path d="M 78 100 C 90 104 116 105 142 101 C 166 97 178 92 180 88 C 166 85 140 85 110 87 C 90 89 82 96 78 100 Z" fill="#000000" opacity="0.12" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 32 94 22 144 24 C 188 26 190 54 188 84 C 186 98 184 106 182 114 C 178 114 176 104 174 94 C 166 84 140 84 110 86 C 90 88 82 96 80 102 C 78 108 76 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 78 96 C 100 84 138 82 180 90 C 146 82 106 84 84 96 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 86 92 C 114 82 148 84 178 92" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 94 78 C 122 70 156 74 184 84" stroke="#000000" stroke-width="1.8" fill="none" opacity="0.22" />');
        sb.writeln('<path d="M 98 34 Q 140 22 182 36" stroke="#ffffff" stroke-width="3.2" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 108 46 Q 146 36 174 50" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.20" />');
        break;

      case 'shortRound':
        sb.writeln('<path d="M 78 96 C 88 104 104 105 130 105 C 156 105 172 104 182 96 C 172 92 164 90 156 90 L 130 102 L 104 90 C 96 90 88 92 78 96 Z" fill="#000000" opacity="0.12" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 36 92 24 130 26 C 168 24 190 36 190 70 C 190 94 188 102 186 114 C 182 114 180 104 180 96 C 172 92 164 90 156 90 L 130 102 L 104 90 C 96 90 88 92 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 130 26 L 130 98" stroke="#000000" stroke-width="2.6" stroke-linecap="round" opacity="0.45" />');
        sb.writeln('<path d="M 88 38 Q 116 32 126 56 Q 106 84 82 88 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 84 42 Q 108 36 122 48" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 94 62 Q 112 56 124 70" stroke="#000000" stroke-width="1.8" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 104 84 Q 116 94 128 98" stroke="#000000" stroke-width="2.0" fill="none" opacity="0.35" />');
        sb.writeln('<path d="M 172 38 Q 144 32 134 56 Q 154 84 178 88 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 176 42 Q 152 36 138 48" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 166 62 Q 148 56 136 70" stroke="#000000" stroke-width="1.8" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 156 84 Q 144 94 132 98" stroke="#000000" stroke-width="2.0" fill="none" opacity="0.35" />');
        break;

      case 'theCaesar':
        sb.writeln('<path d="M 76 96 C 90 99 130 100 170 99 C 182 96 182 92 182 90 L 76 90 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 72 70 C 72 34 94 22 130 22 C 166 22 188 34 188 70 C 188 94 186 102 186 114 C 182 114 180 104 180 96 C 174 86 156 84 130 84 C 104 84 86 86 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 76 86 C 84 92 92 88 100 92 C 108 88 116 93 124 88 C 132 93 140 88 148 93 C 156 88 164 92 172 88 C 178 92 182 88 184 86 L 184 80 L 76 80 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 76 86 C 84 92 92 88 100 92 C 108 88 116 93 124 88 C 132 93 140 88 148 93 C 156 88 164 92 172 88 C 178 92 182 88 184 86" stroke="#000000" stroke-width="2.0" fill="none" opacity="0.35" />');
        sb.writeln('<path d="M 90 42 L 96 68" stroke="#000000" stroke-width="1.8" stroke-linecap="round" opacity="0.22" />');
        sb.writeln('<path d="M 112 36 L 116 72" stroke="#000000" stroke-width="2.0" stroke-linecap="round" opacity="0.22" />');
        sb.writeln('<path d="M 130 32 L 130 74" stroke="#000000" stroke-width="2.2" stroke-linecap="round" opacity="0.25" />');
        sb.writeln('<path d="M 148 36 L 144 72" stroke="#000000" stroke-width="2.0" stroke-linecap="round" opacity="0.22" />');
        sb.writeln('<path d="M 170 42 L 164 68" stroke="#000000" stroke-width="1.8" stroke-linecap="round" opacity="0.22" />');
        sb.writeln('<path d="M 100 40 Q 130 30 160 40" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.26" />');
        sb.writeln('<path d="M 110 52 Q 130 44 150 52" stroke="#ffffff" stroke-width="2.0" stroke-linecap="round" fill="none" opacity="0.18" />');
        break;

      case 'shortCurly':
        sb.writeln('<path d="M 78 96 C 90 102 116 104 130 104 C 144 104 170 102 182 96 C 172 88 152 84 130 84 C 108 84 88 88 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 34 94 20 130 20 C 166 20 190 34 190 70 C 190 94 188 102 186 114 C 182 114 180 104 180 96 C 172 88 152 84 130 84 C 108 84 88 88 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 68 54 C 64 38 82 26 94 34 C 104 20 126 14 138 24 C 150 14 172 20 180 34 C 194 28 202 44 196 58 C 204 74 192 90 182 92 C 180 98 174 104 168 96 C 156 104 140 96 134 92 C 124 98 106 98 98 90 C 88 96 74 88 74 76 C 66 68 64 58 68 54 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 86 42 C 96 34 108 42 102 52 C 96 60 84 56 88 48" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 116 28 C 128 20 140 28 134 38 C 128 46 116 42 120 34" stroke="#000000" stroke-width="2.4" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 152 34 C 164 26 176 34 170 44 C 164 52 152 48 156 40" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 96 74 C 106 66 118 72 112 82 C 106 88 94 84 98 76" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 134 72 C 144 64 156 70 150 80 C 144 86 132 84 136 76" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 90 38 Q 102 32 104 42" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.35" />');
        sb.writeln('<path d="M 122 24 Q 134 18 136 28" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.35" />');
        sb.writeln('<path d="M 158 30 Q 170 24 172 34" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.35" />');
        sb.writeln('<path d="M 100 70 Q 112 64 114 74" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 138 68 Q 150 62 152 72" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.28" />');
        break;

      case 'frizzle':
        sb.writeln('<path d="M 78 96 C 88 102 114 104 130 104 C 146 104 172 102 182 96 C 174 86 156 84 130 84 C 104 84 86 86 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 72 70 C 72 44 86 42 118 42 L 130 10 L 142 42 C 174 42 188 44 188 70 C 188 94 186 102 186 114 C 182 114 180 104 180 96 C 174 86 156 84 130 84 C 104 84 86 86 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 104 46 C 108 30 114 14 122 8 C 124 20 126 36 128 44 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 116 42 C 122 22 128 4 130 2 C 134 16 138 32 142 42 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 134 44 C 138 24 144 12 150 10 C 150 24 148 38 146 48 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 84 66 C 90 52 98 42 104 44 C 102 54 98 66 94 74 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 176 66 C 170 52 162 42 156 44 C 158 54 162 66 166 74 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 122 8 L 126 44" stroke="#000000" stroke-width="2.2" stroke-linecap="round" opacity="0.35" />');
        sb.writeln('<path d="M 130 2 L 132 46" stroke="#000000" stroke-width="2.4" stroke-linecap="round" opacity="0.40" />');
        sb.writeln('<path d="M 148 12 L 142 46" stroke="#000000" stroke-width="2.2" stroke-linecap="round" opacity="0.35" />');
        sb.writeln('<path d="M 120 14 L 124 38" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" opacity="0.38" />');
        sb.writeln('<path d="M 129 6 L 130 36" stroke="#ffffff" stroke-width="3.0" stroke-linecap="round" opacity="0.45" />');
        sb.writeln('<path d="M 144 16 L 140 38" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" opacity="0.35" />');
        break;

      case 'shavedSides':
        sb.writeln('<path d="M 74 114 C 74 102 72 94 72 70 C 72 48 84 46 130 46 C 176 46 188 48 188 70 C 188 94 186 102 186 114 C 182 114 180 104 180 96 C 174 86 156 84 130 84 C 104 84 86 86 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" opacity="0.55" />');
        sb.writeln('<path d="M 74 96 C 74 104 78 114 74 114 C 74 102 74 84 80 72 C 82 82 80 92 74 96 Z" fill="$hairColor" opacity="0.40" />');
        sb.writeln('<path d="M 186 96 C 186 104 182 114 186 114 C 186 102 186 84 180 72 C 178 82 180 92 186 96 Z" fill="$hairColor" opacity="0.40" />');
        sb.writeln('<path d="M 80 92 C 104 98 156 98 180 92 C 166 84 140 82 100 82 Z" fill="#000000" opacity="0.15" />');
        sb.writeln('<path d="M 76 52 C 86 14 154 14 186 34 C 164 26 114 24 80 44 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 80 44 C 104 30 156 32 184 46 L 180 82 C 148 76 98 76 78 82 Z" fill="$hairColor" />');
        sb.writeln('<line x1="78" y1="48" x2="108" y2="76" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" opacity="0.95" />');
        sb.writeln('<line x1="78" y1="48" x2="108" y2="76" stroke="#000000" stroke-width="1.0" stroke-linecap="round" opacity="0.25" />');
        sb.writeln('<path d="M 98 26 Q 134 18 170 32" stroke="#ffffff" stroke-width="3.2" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 106 38 Q 138 30 168 42" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.22" />');
        sb.writeln('<path d="M 112 50 Q 140 44 164 54" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.16" />');
        break;

      case 'shaggy':
        sb.writeln('<path d="M 78 96 C 88 102 114 104 130 104 C 146 104 172 102 182 96 C 172 88 152 84 130 84 C 104 84 88 88 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 28 92 10 144 10 C 182 12 190 32 190 70 C 190 94 188 102 186 114 C 182 114 180 104 180 96 C 172 88 152 84 130 84 C 104 84 88 88 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 72 44 C 90 4 168 0 192 26 C 168 10 106 10 78 36 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 82 82 C 102 68 140 68 178 80 C 154 74 112 74 86 86 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 82 28 C 112 8 162 8 186 24" stroke="#000000" stroke-width="2.6" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 86 80 C 110 72 152 74 176 82" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 94 22 Q 134 6 176 22" stroke="#ffffff" stroke-width="3.8" stroke-linecap="round" fill="none" opacity="0.34" />');
        sb.writeln('<path d="M 104 36 Q 138 22 170 36" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.24" />');
        sb.writeln('<path d="M 96 52 Q 130 40 162 52" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.18" />');
        break;

      case 'shortWaved':
        sb.writeln('<path d="M 78 96 C 90 101 116 103 130 103 C 144 103 170 101 182 96 C 172 88 152 84 130 84 C 104 84 88 88 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 34 94 22 136 22 C 178 22 190 34 190 70 C 190 94 188 102 186 114 C 182 114 180 104 180 96 C 172 88 152 84 130 84 C 104 84 88 88 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 88 42 Q 112 30 134 38 Q 154 30 174 42" stroke="$hairColor" stroke-width="9" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 88 44 Q 112 34 134 40 Q 154 34 172 44" stroke="#000000" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.38" />');
        sb.writeln('<path d="M 90 38 Q 112 28 134 36 Q 154 28 170 38" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 80 58 Q 106 44 128 54 Q 150 44 176 58" stroke="$hairColor" stroke-width="10" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 82 60 Q 106 48 128 56 Q 150 48 174 60" stroke="#000000" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.38" />');
        sb.writeln('<path d="M 84 54 Q 106 42 128 50 Q 150 42 172 54" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 84 76 Q 112 62 136 72 Q 158 62 182 76" stroke="$hairColor" stroke-width="9" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 86 78 Q 112 66 136 74 Q 158 66 180 78" stroke="#000000" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.38" />');
        sb.writeln('<path d="M 88 72 Q 112 60 136 68 Q 158 60 178 72" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 80 86 C 104 84 156 84 180 86" stroke="#000000" stroke-width="2.0" fill="none" opacity="0.30" />');
        break;

      case 'theCaesarAndSidePart':
        sb.writeln('<path d="M 78 96 C 88 102 114 104 130 104 C 146 104 172 102 182 96 C 174 86 156 84 130 84 C 104 84 86 86 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 72 70 C 72 36 94 26 130 28 C 172 26 188 36 188 70 C 188 94 186 102 186 114 C 182 114 180 104 180 96 C 174 86 156 84 130 84 C 104 84 86 86 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 76 54 C 80 32 90 14 96 12 C 98 26 100 42 102 50 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 94 46 C 102 24 114 8 122 6 C 122 22 124 38 126 44 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 118 40 C 126 18 138 4 144 4 C 144 20 146 36 148 42 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 142 42 C 150 20 162 10 168 12 C 166 26 166 40 168 48 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 166 50 C 172 30 180 20 186 22 C 184 36 184 48 186 56 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 80 84 C 88 64 96 52 102 54 C 100 68 100 78 106 84 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 104 84 C 112 62 122 48 128 50 C 128 66 128 78 134 86 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 132 86 C 140 64 148 50 154 52 C 154 68 154 78 160 84 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 158 84 C 164 66 170 56 176 58 C 176 70 176 78 180 86 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 96 14 L 100 42" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" opacity="0.32" />');
        sb.writeln('<path d="M 122 8 L 124 36" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" opacity="0.38" />');
        sb.writeln('<path d="M 144 6 L 146 34" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" opacity="0.38" />');
        sb.writeln('<path d="M 166 14 L 166 40" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" opacity="0.30" />');
        break;

      case 'bun':
        sb.writeln('<path d="M 78 96 C 88 102 114 104 130 104 C 146 104 172 102 182 96 C 174 86 156 84 130 84 C 104 84 86 86 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 72 70 C 72 36 94 26 130 26 C 166 26 188 36 188 70 C 188 94 186 102 186 114 C 182 114 180 104 180 96 C 174 86 156 84 130 84 C 104 84 86 86 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 82 86 Q 104 50 124 36" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 178 86 Q 156 50 136 36" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 102 82 Q 116 54 126 38" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.22" />');
        sb.writeln('<path d="M 158 82 Q 144 54 134 38" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.22" />');
        sb.writeln('<path d="M 100 46 C 114 36 146 36 160 46" stroke="#000000" stroke-width="2.0" fill="none" opacity="0.25" />');
        break;

      case 'curly':
        sb.writeln('<path d="M 78 96 C 90 102 116 104 130 104 C 144 104 170 102 182 96 C 172 88 152 84 130 84 C 104 84 88 88 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 34 94 20 130 20 C 166 20 190 34 190 70 C 190 94 188 102 186 114 C 182 114 180 104 180 96 C 172 88 152 84 130 84 C 104 84 88 88 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 70 106 C 54 122 54 146 68 164 C 76 176 64 198 54 210" stroke="$hairColor" stroke-width="12" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 70 106 C 54 122 54 146 68 164 C 76 176 64 198 54 210" stroke="#000000" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 62 124 Q 52 136 60 148" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 190 106 C 206 122 206 146 192 164 C 184 176 196 198 206 210" stroke="$hairColor" stroke-width="12" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 190 106 C 206 122 206 146 192 164 C 184 176 196 198 206 210" stroke="#000000" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 198 124 Q 208 136 200 148" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 94 34 C 104 22 120 22 126 34" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 134 34 C 140 22 156 22 166 34" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 102 30 Q 130 18 158 30" stroke="#ffffff" stroke-width="3.0" stroke-linecap="round" fill="none" opacity="0.26" />');
        break;

      case 'curvy':
        sb.writeln('<path d="M 78 96 C 90 102 116 104 130 104 C 144 104 170 102 182 96 C 172 88 152 84 130 84 C 104 84 88 88 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 70 70 C 70 32 94 18 142 18 C 182 20 190 38 190 70 C 190 94 188 102 186 114 C 182 114 180 104 180 96 C 172 88 152 84 130 84 C 104 84 88 88 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 66 112 C 58 138 74 164 68 194 C 64 214 78 226 86 212 C 92 184 80 158 84 128 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 68 136 Q 60 160 74 182" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 72 170 Q 64 194 78 208" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 78 88 C 108 78 148 80 180 92 C 150 82 112 80 84 90 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 88 86 C 118 78 154 82 178 92" stroke="#000000" stroke-width="2.0" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 94 30 Q 138 18 180 32" stroke="#ffffff" stroke-width="3.6" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 106 42 Q 142 32 172 44" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.22" />');
        break;

      case 'bob':
        sb.writeln('<path d="M 88 94 C 104 100 130 101 156 100 C 172 94 174 88 174 88 L 88 88 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 60 120 C 58 40 84 24 130 24 C 176 24 202 40 200 120 C 200 158 188 172 176 172 C 168 172 164 156 164 142 C 164 104 158 88 130 88 C 102 88 96 104 96 142 C 96 156 92 172 84 172 C 72 172 60 158 60 120 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 90 88 Q 130 82 170 88 Q 130 92 90 88 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 90 88 Q 130 82 170 88" stroke="#000000" stroke-width="2.0" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 90 36 Q 130 24 170 36" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<path d="M 98 48 Q 130 38 162 48" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.20" />');
        sb.writeln('<path d="M 66 118 Q 66 146 76 162" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.26" />');
        sb.writeln('<path d="M 194 118 Q 194 146 184 162" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.26" />');
        break;

      case 'fro':
        sb.writeln('<path d="M 76 96 C 90 101 116 103 130 103 C 144 103 170 101 184 96 C 176 86 154 84 130 84 C 106 84 84 86 76 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 52 130 C 38 64 64 12 130 12 C 196 12 222 64 208 130 C 198 94 182 86 154 84 C 112 84 78 86 52 130 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 50 120 C 40 108 42 90 48 78 C 42 66 50 48 62 40 C 60 28 74 18 90 16 C 102 8 122 8 130 10 C 138 8 158 8 170 16 C 186 18 200 28 198 40 C 210 48 218 66 212 78 C 218 90 220 108 210 120" stroke="$hairColor" stroke-width="14" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 74 68 C 84 58 98 64 92 76" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 112 44 C 124 34 138 40 132 52" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 166 68 C 176 58 190 64 184 76" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 104 84 C 114 74 128 80 122 90" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 144 84 C 154 74 168 80 162 90" stroke="#000000" stroke-width="2.2" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 84 26 Q 130 12 176 26" stroke="#ffffff" stroke-width="3.8" stroke-linecap="round" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 100 38 Q 130 28 160 38" stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.22" />');
        break;

      case 'bald':
        sb.writeln('<path d="M 96 42 Q 130 32 164 42" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.28" />');
        sb.writeln('<path d="M 106 52 Q 130 44 154 52" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.18" />');
        sb.writeln('<path d="M 82 92 C 104 84 156 84 178 92 C 160 88 100 88 82 92 Z" fill="#000000" opacity="0.06" />');
        break;

      case 'shortFlat':
      default:
        sb.writeln('<path d="M 78 96 C 90 102 116 104 130 104 C 146 104 172 102 182 96 C 172 88 152 86 130 86 C 106 86 88 88 78 96 Z" fill="#000000" opacity="0.14" />');
        sb.writeln('<path d="M 74 114 C 74 102 72 94 72 70 C 72 36 94 26 140 26 C 180 26 188 38 188 70 C 188 94 186 102 186 114 C 182 114 180 104 180 96 C 172 88 152 86 130 86 C 106 86 88 88 80 96 C 80 104 78 114 74 114 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 94 34 L 98 84" stroke="#000000" stroke-width="2.6" stroke-linecap="round" opacity="0.48" />');
        sb.writeln('<path d="M 98 34 C 122 26 166 28 190 42 C 168 32 124 30 98 38 Z" fill="$hairColor" />');
        sb.writeln('<path d="M 108 48 C 130 40 156 44 180 54" stroke="#000000" stroke-width="1.8" fill="none" opacity="0.25" />');
        sb.writeln('<path d="M 112 62 C 132 56 156 60 178 70" stroke="#000000" stroke-width="1.8" fill="none" opacity="0.22" />');
        sb.writeln('<path d="M 108 38 Q 142 32 176 44" stroke="#ffffff" stroke-width="3.2" stroke-linecap="round" fill="none" opacity="0.30" />');
        sb.writeln('<path d="M 114 50 Q 144 44 170 54" stroke="#ffffff" stroke-width="2.0" stroke-linecap="round" fill="none" opacity="0.20" />');
        sb.writeln('<path d="M 76 94 L 92 84 L 94 90 L 76 102 Z" fill="$hairColor" />');
        break;

    }
  }

  static void _appendHat(StringBuffer sb, String hat, String hatColor, String clothColor, String skinColor) {
    switch (hat) {
      case 'cap':
        // Classic baseball cap with smooth anatomical crown dome, button, eyelets & curved visor
        sb.writeln('<path d="M 64 92 C 64 48 92 28 130 28 C 168 28 196 48 196 92 Z" fill="$hatColor" />');
        sb.writeln('<line x1="130" y1="28" x2="130" y2="88" stroke="#000000" stroke-width="1.5" opacity="0.22" />');
        sb.writeln('<path d="M 130 28 Q 94 54 78 92" stroke="#000000" stroke-width="1.3" opacity="0.18" fill="none" />');
        sb.writeln('<path d="M 130 28 Q 166 54 182 92" stroke="#000000" stroke-width="1.3" opacity="0.18" fill="none" />');
        sb.writeln('<circle cx="130" cy="28" r="4.5" fill="$hatColor" />');
        sb.writeln('<circle cx="128.8" cy="26.8" r="1.5" fill="#ffffff" opacity="0.5" />');
        sb.writeln('<circle cx="102" cy="56" r="2.2" stroke="#000000" stroke-width="0.8" opacity="0.3" fill="none" />');
        sb.writeln('<circle cx="158" cy="56" r="2.2" stroke="#000000" stroke-width="0.8" opacity="0.3" fill="none" />');
        sb.writeln('<path d="M 58 92 C 58 86 106 82 156 84 C 200 88 208 96 198 102 C 160 105 106 102 58 92 Z" fill="#000000" opacity="0.26" />');
        sb.writeln('<path d="M 54 90 C 54 84 104 80 156 82 C 202 86 210 94 200 100 C 160 103 104 100 54 90 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 64 90 C 106 97 158 99 194 97" stroke="#ffffff" stroke-width="1.2" opacity="0.4" fill="none" />');
        sb.writeln('<path d="M 125 58 L 135 58 L 135 68 L 130 73 L 125 68 Z" fill="#ffffff" opacity="0.45" />');
        break;

      case 'snapback':
        // Urban flat-brim snapback with gold metallic authenticity foil sticker
        sb.writeln('<path d="M 62 92 C 60 40 92 26 130 26 C 168 26 200 40 198 92 Z" fill="$hatColor" />');
        sb.writeln('<line x1="130" y1="26" x2="130" y2="88" stroke="#000000" stroke-width="1.6" opacity="0.22" />');
        sb.writeln('<line x1="130" y1="26" x2="84" y2="90" stroke="#000000" stroke-width="1.2" opacity="0.18" />');
        sb.writeln('<line x1="130" y1="26" x2="176" y2="90" stroke="#000000" stroke-width="1.2" opacity="0.18" />');
        sb.writeln('<circle cx="130" cy="26" r="4.5" fill="$hatColor" />');
        sb.writeln('<circle cx="129" cy="25" r="1.5" fill="#ffffff" opacity="0.5" />');
        sb.writeln('<rect x="50" y="92" width="160" height="10" rx="4" fill="#000000" opacity="0.26" />');
        sb.writeln('<rect x="48" y="89" width="164" height="9.5" rx="3.5" fill="$hatColor" />');
        sb.writeln('<line x1="50" y1="90" x2="210" y2="90" stroke="#ffffff" stroke-width="1.2" opacity="0.45" />');
        sb.writeln('<circle cx="178" cy="93.5" r="4.5" fill="#d4af37" />');
        sb.writeln('<circle cx="178" cy="93.5" r="3.2" stroke="#18181b" stroke-width="0.6" fill="none" />');
        sb.writeln('<circle cx="176.8" cy="92.2" r="1.0" fill="#ffffff" opacity="0.85" />');
        break;

      case 'helmetMoto':
        // Full-face aerodynamic sports motorcycle racing helmet with tinted visor
        sb.writeln('<path d="M 58 98 C 54 40 88 22 130 22 C 172 22 206 40 202 98 C 200 126 186 148 174 154 L 154 156 L 154 146 L 106 146 L 106 156 L 86 154 C 74 148 60 126 58 98 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 104 34 L 118 30 L 122 36 L 108 40 Z" fill="#18181b" />');
        sb.writeln('<path d="M 156 34 L 142 30 L 138 36 L 152 40 Z" fill="#18181b" />');
        sb.writeln('<line x1="126" y1="24" x2="126" y2="70" stroke="#ffffff" stroke-width="2.5" opacity="0.7" />');
        sb.writeln('<line x1="134" y1="24" x2="134" y2="70" stroke="#ffffff" stroke-width="2.5" opacity="0.7" />');
        sb.writeln('<path d="M 72 74 C 90 68 170 68 188 74 C 194 96 190 122 184 130 C 160 134 100 134 76 130 C 70 122 66 96 72 74 Z" fill="#0f172a" stroke="#334155" stroke-width="2.2" />');
        sb.writeln('<polygon points="90,72 108,71 84,130 68,130" fill="#ffffff" opacity="0.25" />');
        sb.writeln('<polygon points="120,70 134,70 112,132 100,132" fill="#ffffff" opacity="0.15" />');
        sb.writeln('<rect x="116" y="138" width="28" height="6" rx="2" fill="#18181b" />');
        sb.writeln('<line x1="122" y1="141" x2="138" y2="141" stroke="#475569" stroke-width="1.2" />');
        break;

      case 'helmetSkate':
        // Urban skate / bicycle helmet with air cooling slots, EPS liner and chin straps
        sb.writeln('<path d="M 60 92 C 58 42 90 26 130 26 C 170 26 202 42 200 92 C 198 100 190 102 180 102 C 160 96 100 96 80 102 C 70 102 62 100 60 92 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 64 92 C 86 86 174 86 196 92 L 194 97 C 172 92 88 92 66 97 Z" fill="#1e293b" />');
        sb.writeln('<rect x="94" y="44" width="10" height="26" rx="4" transform="rotate(-15 99 57)" fill="#0f172a" />');
        sb.writeln('<rect x="125" y="38" width="10" height="28" rx="4" fill="#0f172a" />');
        sb.writeln('<rect x="156" y="44" width="10" height="26" rx="4" transform="rotate(15 161 57)" fill="#0f172a" />');
        sb.writeln('<path d="M 88 36 Q 130 28 172 36" stroke="#ffffff" stroke-width="3.0" stroke-linecap="round" fill="none" opacity="0.32" />');
        sb.writeln('<line x1="74" y1="94" x2="108" y2="152" stroke="#334155" stroke-width="2.5" stroke-linecap="round" />');
        sb.writeln('<line x1="186" y1="94" x2="152" y2="152" stroke="#334155" stroke-width="2.5" stroke-linecap="round" />');
        sb.writeln('<rect x="123" y="150" width="14" height="6" rx="1.5" fill="#0f172a" />');
        break;

      case 'beanie':
        // Cozy ribbed knit winter beanie with folded cuff and leather brand patch
        sb.writeln('<path d="M 64 88 C 62 36 92 26 130 26 C 168 26 198 36 196 88 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 88 38 Q 130 28 172 38" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<rect x="58" y="80" width="144" height="22" rx="7" fill="$hatColor" />');
        sb.writeln('<line x1="58" y1="80" x2="202" y2="80" stroke="#000000" stroke-width="2.0" opacity="0.22" />');
        for (double x = 70; x <= 190; x += 12) {
          sb.writeln('<line x1="$x" y1="82" x2="$x" y2="100" stroke="#000000" stroke-width="1.1" opacity="0.15" />');
        }
        sb.writeln('<rect x="158" y="85" width="11" height="13" rx="2" fill="#b45309" />');
        sb.writeln('<line x1="160" y1="91" x2="167" y2="91" stroke="#fef3c7" stroke-width="1.0" />');
        break;

      case 'beaniePom':
        // Beanie with prominent fluffy top pom-pom
        sb.writeln('<circle cx="130" cy="18" r="14.5" fill="$hatColor" />');
        sb.writeln('<circle cx="130" cy="18" r="15.5" stroke="#ffffff" stroke-width="2.2" stroke-dasharray="3,3" opacity="0.45" fill="none" />');
        sb.writeln('<circle cx="127" cy="15" r="5" fill="#ffffff" opacity="0.35" />');
        sb.writeln('<path d="M 64 88 C 62 36 92 26 130 26 C 168 26 198 36 196 88 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 88 38 Q 130 28 172 38" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.25" />');
        sb.writeln('<rect x="58" y="80" width="144" height="22" rx="7" fill="$hatColor" />');
        sb.writeln('<line x1="58" y1="80" x2="202" y2="80" stroke="#000000" stroke-width="2.0" opacity="0.22" />');
        for (double x = 70; x <= 190; x += 12) {
          sb.writeln('<line x1="$x" y1="82" x2="$x" y2="100" stroke="#000000" stroke-width="1.1" opacity="0.15" />');
        }
        break;

      case 'bucketHat':
        // Trendy streetwear 360-degree flared bucket hat with quilted stitch rings
        sb.writeln('<ellipse cx="130" cy="38" rx="46" ry="12" fill="$hatColor" />');
        sb.writeln('<ellipse cx="127" cy="36" rx="36" ry="8" stroke="#ffffff" stroke-width="1.6" opacity="0.28" fill="none" />');
        sb.writeln('<path d="M 84 38 L 70 82 C 102 88 158 88 190 82 L 176 38 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 70 82 C 102 88 158 88 190 82" stroke="#000000" stroke-width="2.0" opacity="0.2" fill="none" />');
        sb.writeln('<path d="M 48 94 C 76 110 184 110 212 94 L 190 82 C 158 88 102 88 70 82 Z" fill="#000000" opacity="0.25" />');
        sb.writeln('<path d="M 46 92 C 74 108 186 108 214 92 L 190 80 C 158 86 102 86 70 80 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 54 90 C 80 102 180 102 206 90" stroke="#ffffff" stroke-width="1.0" opacity="0.32" fill="none" />');
        sb.writeln('<path d="M 60 88 C 84 98 176 98 200 88" stroke="#ffffff" stroke-width="1.0" opacity="0.32" fill="none" />');
        break;

      case 'fedora':
        // Classic creased teardrop Fedora with satin ribbon band and feather pin
        sb.writeln('<path d="M 74 80 C 72 38 94 26 116 32 C 124 34 136 34 144 32 C 166 26 188 38 186 80 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 120 34 Q 130 46 140 34" stroke="#000000" stroke-width="3.2" stroke-linecap="round" opacity="0.3" fill="none" />');
        sb.writeln('<path d="M 86 54 Q 94 64 94 74" stroke="#000000" stroke-width="2.2" stroke-linecap="round" opacity="0.2" fill="none" />');
        sb.writeln('<path d="M 174 54 Q 166 64 166 74" stroke="#000000" stroke-width="2.2" stroke-linecap="round" opacity="0.2" fill="none" />');
        sb.writeln('<path d="M 73 74 C 105 79 155 79 187 74 L 187 82 C 155 87 105 87 73 82 Z" fill="#18181b" />');
        sb.writeln('<line x1="75" y1="75" x2="185" y2="75" stroke="#ffffff" stroke-width="0.8" opacity="0.35" />');
        sb.writeln('<polygon points="78,72 72,78 78,84 82,78" fill="#d4af37" />');
        sb.writeln('<path d="M 40 82 C 40 98 90 102 130 102 C 170 102 220 98 220 82 C 220 76 160 70 130 70 C 100 70 40 76 40 82 Z" fill="#000000" opacity="0.25" />');
        sb.writeln('<path d="M 42 80 C 42 96 90 100 130 100 C 170 100 218 96 218 80 C 218 74 160 68 130 68 C 100 68 42 74 42 80 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 44 80 C 60 94 100 98 130 98 C 160 98 200 94 216 80" stroke="#ffffff" stroke-width="1.4" opacity="0.3" fill="none" />');
        break;

      case 'beret':
        // French artist wool beret with side slouch and top antoinette stem
        sb.writeln('<path d="M 62 82 C 48 54 90 32 144 30 C 198 28 218 52 208 72 C 200 84 170 90 130 90 C 90 90 70 88 62 82 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 120 42 Q 168 46 196 62" stroke="#000000" stroke-width="2.5" stroke-linecap="round" opacity="0.2" fill="none" />');
        sb.writeln('<path d="M 94 38 Q 138 32 174 38" stroke="#ffffff" stroke-width="2.8" stroke-linecap="round" opacity="0.3" fill="none" />');
        sb.writeln('<line x1="144" y1="30" x2="146" y2="22" stroke="$hatColor" stroke-width="3.2" stroke-linecap="round" />');
        sb.writeln('<line x1="144" y1="30" x2="146" y2="22" stroke="#ffffff" stroke-width="1.0" opacity="0.4" />');
        sb.writeln('<path d="M 74 84 C 96 90 164 90 186 84" stroke="#000000" stroke-width="2.8" stroke-linecap="round" opacity="0.25" fill="none" />');
        break;

      case 'hijab':
        // Elegant flowing headscarf framing face with inner underscarf
        sb.writeln('<path d="M 56 120 C 54 44 206 44 204 120 C 204 180 194 218 214 260 L 46 260 C 66 218 56 180 56 120 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 80 114 C 80 64 180 64 180 114 C 180 160 158 180 130 180 C 102 180 80 160 80 114 Z" fill="$skinColor" />');
        sb.writeln('<path d="M 84 84 C 104 78 156 78 176 84" stroke="#ffffff" stroke-width="4.0" opacity="0.4" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 85 84 C 104 79 155 79 175 84" stroke="$hatColor" stroke-width="2.5" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 82 168 Q 130 204 178 168" stroke="#000000" stroke-width="2.2" opacity="0.16" fill="none" />');
        sb.writeln('<path d="M 130 68 Q 140 88 152 106" stroke="#000000" stroke-width="2.2" opacity="0.14" fill="none" />');
        sb.writeln('<path d="M 70 190 Q 110 220 150 260" stroke="#000000" stroke-width="2.0" opacity="0.15" fill="none" />');
        break;

      case 'turban':
        // Regal spiral-wrapped Pagri with central jeweled brooch
        sb.writeln('<path d="M 72 72 C 72 28 188 28 188 72 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 124 34 C 122 14 138 14 136 34 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 126 18 L 134 18" stroke="#ffffff" stroke-width="1.2" opacity="0.4" />');
        sb.writeln('<path d="M 62 94 C 80 68 144 66 198 80 L 196 90 C 142 76 80 78 64 100 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 62 94 C 80 68 144 66 198 80" stroke="#ffffff" stroke-width="1.6" opacity="0.35" fill="none" />');
        sb.writeln('<path d="M 198 94 C 180 68 116 66 62 80 L 64 90 C 118 76 180 78 196 100 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 198 94 C 180 68 116 66 62 80" stroke="#ffffff" stroke-width="1.6" opacity="0.35" fill="none" />');
        sb.writeln('<path d="M 80 92 Q 130 82 180 92" stroke="#000000" stroke-width="2.4" opacity="0.25" fill="none" />');
        sb.writeln('<circle cx="130" cy="74" r="5.5" fill="#d4af37" />');
        sb.writeln('<circle cx="130" cy="74" r="3.2" fill="#dc2626" />');
        sb.writeln('<circle cx="129" cy="73" r="1.0" fill="#ffffff" opacity="0.8" />');
        break;

      case 'headband':
        // Athletic tennis/gym terrycloth sweatband (open crown shows hair)
        sb.writeln('<path d="M 68 80 C 90 86 170 86 192 80 L 190 98 C 170 104 90 104 70 98 Z" fill="#000000" opacity="0.22" />');
        sb.writeln('<path d="M 68 78 C 90 84 170 84 192 78 L 190 96 C 170 102 90 102 70 96 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 70 84 C 90 90 170 90 190 84" stroke="#ffffff" stroke-width="1.4" opacity="0.4" fill="none" />');
        sb.writeln('<path d="M 71 89 C 90 95 170 95 189 89" stroke="#000000" stroke-width="1.2" opacity="0.18" fill="none" />');
        sb.writeln('<line x1="124" y1="86.5" x2="136" y2="86.5" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" />');
        break;

      case 'bandana':
        // Hip-hop / biker folded bandana with paisley micro-studs and side knot
        sb.writeln('<path d="M 64 84 C 62 34 198 34 196 84 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 64 80 C 90 86 170 86 196 80 L 194 98 C 170 104 90 104 66 98 Z" fill="#000000" opacity="0.25" />');
        sb.writeln('<path d="M 64 78 C 90 84 170 84 196 78 L 194 96 C 170 102 90 102 66 96 Z" fill="$hatColor" />');
        for (double x = 84; x <= 176; x += 18) {
          sb.writeln('<circle cx="$x" cy="87" r="1.3" fill="#ffffff" opacity="0.75" />');
        }
        sb.writeln('<circle cx="64" cy="92" r="5" fill="$hatColor" />');
        sb.writeln('<path d="M 64 94 L 50 108 L 54 120 L 66 100 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 62 96 L 54 112 L 60 122 L 67 102 Z" fill="$hatColor" opacity="0.8" />');
        break;

      case 'kufi':
        // Islamic prayer skullcap (Kufi / Topi) with delicate geometric rim embroidery
        sb.writeln('<path d="M 68 88 C 66 42 194 42 192 88 Z" fill="$hatColor" />');
        sb.writeln('<ellipse cx="130" cy="52" rx="34" ry="8" stroke="#ffffff" stroke-width="1.2" opacity="0.35" fill="none" />');
        sb.writeln('<path d="M 67 83 C 90 89 170 89 193 83 L 193 92 C 170 98 90 98 67 92 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 67 83 C 90 89 170 89 193 83" stroke="#ffffff" stroke-width="1.4" opacity="0.4" fill="none" />');
        sb.writeln('<path d="M 67 92 C 90 98 170 98 193 92" stroke="#ffffff" stroke-width="1.4" opacity="0.4" fill="none" />');
        for (double x = 82; x <= 178; x += 16) {
          sb.writeln('<polygon points="$x,85.5 ${x + 2},87.5 $x,89.5 ${x - 2},87.5" fill="#ffffff" opacity="0.7" />');
        }
        break;

      case 'cowboy':
        // Western cowboy hat with curled upturned brim and leather hatband
        sb.writeln('<path d="M 82 78 C 80 38 94 24 118 28 C 124 30 136 30 142 28 C 166 24 180 38 178 78 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 122 30 Q 130 42 138 30" stroke="#000000" stroke-width="3.0" opacity="0.3" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 94 52 Q 100 62 100 70" stroke="#000000" stroke-width="2.0" opacity="0.25" fill="none" />');
        sb.writeln('<path d="M 166 52 Q 160 62 160 70" stroke="#000000" stroke-width="2.0" opacity="0.25" fill="none" />');
        sb.writeln('<path d="M 81 74 C 104 79 156 79 179 74 L 179 80 C 156 85 104 85 81 80 Z" fill="#78350f" />');
        sb.writeln('<circle cx="130" cy="79.5" r="2.8" fill="#e2e8f0" />');
        sb.writeln('<path d="M 36 74 C 54 90 80 92 130 92 C 180 92 206 90 224 74 C 228 82 212 102 130 102 C 48 102 32 82 36 74 Z" fill="#000000" opacity="0.28" />');
        sb.writeln('<path d="M 38 72 C 56 88 80 90 130 90 C 180 90 204 88 222 72 C 226 80 210 100 130 100 C 50 100 34 80 38 72 Z" fill="$hatColor" />');
        sb.writeln('<path d="M 40 72 C 58 86 82 88 130 88 C 178 88 202 86 220 72" stroke="#ffffff" stroke-width="1.6" opacity="0.35" fill="none" />');
        break;

      case 'none':
      default:
        break;
    }
  }

  static void _appendGlasses(StringBuffer sb, String glasses, String gColor) {
    switch (glasses) {
      case 'roundWire':
        // Modern minimalist circular wireframe (Steve Jobs / Harry Potter)
        sb.writeln('<circle cx="106" cy="116" r="16.5" stroke="$gColor" stroke-width="2.6" fill="#ffffff" fill-opacity="0.05" />');
        sb.writeln('<circle cx="154" cy="116" r="16.5" stroke="$gColor" stroke-width="2.6" fill="#ffffff" fill-opacity="0.05" />');
        sb.writeln('<path d="M 94 103 C 102 100.5 110 100.5 118 103" stroke="#ffffff" stroke-width="1.0" opacity="0.65" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 142 103 C 150 100.5 158 100.5 166 103" stroke="#ffffff" stroke-width="1.0" opacity="0.65" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 122.5 114 Q 130 110 137.5 114" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="89.5" y1="116" x2="82" y2="114" stroke="$gColor" stroke-width="2.4" stroke-linecap="round" />');
        sb.writeln('<line x1="170.5" y1="116" x2="178" y2="114" stroke="$gColor" stroke-width="2.4" stroke-linecap="round" />');
        sb.writeln('<path d="M 96 111 A 12 12 0 0 1 113 106" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.5" />');
        sb.writeln('<path d="M 144 111 A 12 12 0 0 1 161 106" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.5" />');
        sb.writeln('<circle cx="124" cy="117" r="1.0" fill="$gColor" opacity="0.8" />');
        sb.writeln('<circle cx="136" cy="117" r="1.0" fill="$gColor" opacity="0.8" />');
        break;

      case 'wayfarers':
      case 'sunglasses':
        // Iconic Wayfarer thick acetate frames with silver corner studs
        sb.writeln('<path d="M 87 105 C 97 104 121 104 124 107 L 122 128 C 117 131 95 131 90 124 Z" fill="#121214" fill-opacity="0.88" stroke="$gColor" stroke-width="3.2" stroke-linejoin="round" />');
        sb.writeln('<path d="M 173 105 C 163 104 139 104 136 107 L 138 128 C 143 131 165 131 170 124 Z" fill="#121214" fill-opacity="0.88" stroke="$gColor" stroke-width="3.2" stroke-linejoin="round" />');
        sb.writeln('<path d="M 88 105 C 98 104 121 104 123 106" stroke="#ffffff" stroke-width="1.2" opacity="0.45" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 172 105 C 162 104 139 104 137 106" stroke="#ffffff" stroke-width="1.2" opacity="0.45" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 124 107 C 127 106 133 106 136 107 L 136 111 C 131 110 129 110 124 111 Z" fill="$gColor" />');
        sb.writeln('<line x1="87" y1="106" x2="81" y2="108" stroke="$gColor" stroke-width="3.0" stroke-linecap="round" />');
        sb.writeln('<line x1="173" y1="106" x2="179" y2="108" stroke="$gColor" stroke-width="3.0" stroke-linecap="round" />');
        sb.writeln('<rect x="88.5" y="106.2" width="3.4" height="1.4" rx="0.7" fill="#ffffff" opacity="0.9" />');
        sb.writeln('<rect x="168.1" y="106.2" width="3.4" height="1.4" rx="0.7" fill="#ffffff" opacity="0.9" />');
        sb.writeln('<polygon points="94,107 100,107 91,126 86,124" fill="#ffffff" opacity="0.22" />');
        sb.writeln('<polygon points="142,107 148,107 139,126 134,124" fill="#ffffff" opacity="0.22" />');
        break;

      case 'clubmaster':
        // Retro brow-line frames: bold acetate upper brow + thin metallic bottom rim
        sb.writeln('<path d="M 87 104 C 98 102 122 103 125 108 L 124 112 C 118 108 97 107 88 109 Z" fill="$gColor" />');
        sb.writeln('<path d="M 173 104 C 162 102 138 103 135 108 L 136 112 C 142 108 163 107 172 109 Z" fill="$gColor" />');
        sb.writeln('<path d="M 89 104.5 C 98 103.5 120 104 123 107" stroke="#ffffff" stroke-width="1.0" opacity="0.4" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 171 104.5 C 162 103.5 140 104 137 107" stroke="#ffffff" stroke-width="1.0" opacity="0.4" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 88 109 C 88 126 118 129 124 112" stroke="#d4af37" stroke-width="2.2" fill="#ffffff" fill-opacity="0.05" />');
        sb.writeln('<path d="M 172 109 C 172 126 142 129 136 112" stroke="#d4af37" stroke-width="2.2" fill="#ffffff" fill-opacity="0.05" />');
        sb.writeln('<path d="M 125 109 Q 130 106 135 109" stroke="#d4af37" stroke-width="2.4" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="87" y1="105" x2="81" y2="107" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" />');
        sb.writeln('<line x1="173" y1="105" x2="179" y2="107" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" />');
        sb.writeln('<circle cx="89.5" cy="106" r="1.0" fill="#d4af37" />');
        sb.writeln('<circle cx="170.5" cy="106" r="1.0" fill="#d4af37" />');
        sb.writeln('<circle cx="124" cy="116" r="1.2" fill="#d4af37" />');
        sb.writeln('<circle cx="136" cy="116" r="1.2" fill="#d4af37" />');
        sb.writeln('<path d="M 94 112 L 102 122" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" opacity="0.4" />');
        sb.writeln('<path d="M 142 112 L 150 122" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" opacity="0.4" />');
        break;

      case 'aviator':
        // Classic teardrop pilot aviators with double bridge
        sb.writeln('<path d="M 89 107 C 103 105 122 105 124 108 C 126 117 122 128 110 129 C 95 130 87 122 89 107 Z" fill="#0b0f19" fill-opacity="0.75" stroke="$gColor" stroke-width="2.2" stroke-linejoin="round" />');
        sb.writeln('<path d="M 171 107 C 157 105 138 105 136 108 C 134 117 138 128 150 129 C 165 130 173 122 171 107 Z" fill="#0b0f19" fill-opacity="0.75" stroke="$gColor" stroke-width="2.2" stroke-linejoin="round" />');
        sb.writeln('<line x1="102" y1="104" x2="158" y2="104" stroke="$gColor" stroke-width="2.0" stroke-linecap="round" />');
        sb.writeln('<line x1="104" y1="103.5" x2="156" y2="103.5" stroke="#ffffff" stroke-width="0.8" opacity="0.5" stroke-linecap="round" />');
        sb.writeln('<path d="M 124 109 Q 130 106 136 109" stroke="$gColor" stroke-width="2.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="89" y1="107" x2="81" y2="109" stroke="$gColor" stroke-width="2.0" stroke-linecap="round" />');
        sb.writeln('<line x1="171" y1="107" x2="179" y2="109" stroke="$gColor" stroke-width="2.0" stroke-linecap="round" />');
        sb.writeln('<polygon points="95,108 101,108 92,126 88,124" fill="#ffffff" opacity="0.25" />');
        sb.writeln('<polygon points="143,108 149,108 140,126 136,124" fill="#ffffff" opacity="0.25" />');
        break;

      case 'catEye':
        // Vintage glam cat-eye frames with flared wingtips
        sb.writeln('<path d="M 84 103 C 89 97 126 101 126 112 C 126 126 94 127 86 111 Z" fill="#18181b" stroke="$gColor" stroke-width="3.2" stroke-linejoin="round" />');
        sb.writeln('<path d="M 176 103 C 171 97 134 101 134 112 C 134 126 166 127 174 111 Z" fill="#18181b" stroke="$gColor" stroke-width="3.2" stroke-linejoin="round" />');
        sb.writeln('<path d="M 85 103.5 C 90 98 124 102 124 110" stroke="#ffffff" stroke-width="1.0" opacity="0.45" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 175 103.5 C 170 98 136 102 136 110" stroke="#ffffff" stroke-width="1.0" opacity="0.45" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 126 110 Q 130 108 134 110" stroke="$gColor" stroke-width="3.2" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="84" y1="103" x2="79" y2="106" stroke="$gColor" stroke-width="2.8" stroke-linecap="round" />');
        sb.writeln('<line x1="176" y1="103" x2="181" y2="106" stroke="$gColor" stroke-width="2.8" stroke-linecap="round" />');
        sb.writeln('<circle cx="85.5" cy="103.5" r="1.3" fill="#fbbf24" />');
        sb.writeln('<circle cx="85.5" cy="103.5" r="0.6" fill="#ffffff" />');
        sb.writeln('<circle cx="174.5" cy="103.5" r="1.3" fill="#fbbf24" />');
        sb.writeln('<circle cx="174.5" cy="103.5" r="0.6" fill="#ffffff" />');
        sb.writeln('<polygon points="92,106 98,106 90,120 86,118" fill="#ffffff" opacity="0.25" />');
        sb.writeln('<polygon points="140,106 146,106 138,120 134,118" fill="#ffffff" opacity="0.25" />');
        break;

      case 'rectOptical':
      case 'prescription01':
      case 'prescription02':
        // Modern crisp rectangular spectacles
        sb.writeln('<rect x="90" y="104" width="33" height="23" rx="4" fill="#ffffff" fill-opacity="0.06" stroke="$gColor" stroke-width="2.8" />');
        sb.writeln('<rect x="137" y="104" width="33" height="23" rx="4" fill="#ffffff" fill-opacity="0.06" stroke="$gColor" stroke-width="2.8" />');
        sb.writeln('<line x1="92" y1="104" x2="121" y2="104" stroke="#ffffff" stroke-width="0.9" opacity="0.6" stroke-linecap="round" />');
        sb.writeln('<line x1="139" y1="104" x2="168" y2="104" stroke="#ffffff" stroke-width="0.9" opacity="0.6" stroke-linecap="round" />');
        sb.writeln('<path d="M 123 113 Q 130 110 137 113" stroke="$gColor" stroke-width="2.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="90" y1="108" x2="82" y2="108" stroke="$gColor" stroke-width="2.8" stroke-linecap="round" />');
        sb.writeln('<line x1="170" y1="108" x2="178" y2="108" stroke="$gColor" stroke-width="2.8" stroke-linecap="round" />');
        sb.writeln('<path d="M 94 122 L 104 109" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" opacity="0.5" />');
        sb.writeln('<path d="M 141 122 L 151 109" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" opacity="0.5" />');
        break;

      case 'rectShades':
        // VIP dark sunglasses with sleek edge lines
        sb.writeln('<rect x="88" y="105" width="36" height="19" rx="2.5" fill="#0d0d11" stroke="$gColor" stroke-width="2.5" />');
        sb.writeln('<rect x="136" y="105" width="36" height="19" rx="2.5" fill="#0d0d11" stroke="$gColor" stroke-width="2.5" />');
        sb.writeln('<line x1="90" y1="105" x2="122" y2="105" stroke="#ffffff" stroke-width="0.9" opacity="0.4" stroke-linecap="round" />');
        sb.writeln('<line x1="138" y1="105" x2="170" y2="105" stroke="#ffffff" stroke-width="0.9" opacity="0.4" stroke-linecap="round" />');
        sb.writeln('<rect x="124" y="109" width="12" height="4" fill="$gColor" />');
        sb.writeln('<line x1="88" y1="108" x2="81" y2="110" stroke="$gColor" stroke-width="2.8" stroke-linecap="round" />');
        sb.writeln('<line x1="172" y1="108" x2="179" y2="110" stroke="$gColor" stroke-width="2.8" stroke-linecap="round" />');
        sb.writeln('<polygon points="95,106 102,106 92,123 87,123" fill="#ffffff" opacity="0.28" />');
        sb.writeln('<polygon points="143,106 150,106 140,123 135,123" fill="#ffffff" opacity="0.28" />');
        break;

      case 'hexagonal':
        // Modern geometric hexagonal wireframe (6-sided)
        sb.writeln('<polygon points="93,107 119,107 125,116 119,125 93,125 87,116" stroke="$gColor" stroke-width="2.4" fill="#ffffff" fill-opacity="0.05" stroke-linejoin="round" />');
        sb.writeln('<polygon points="141,107 167,107 173,116 167,125 141,125 135,116" stroke="$gColor" stroke-width="2.4" fill="#ffffff" fill-opacity="0.05" stroke-linejoin="round" />');
        sb.writeln('<path d="M 125 114 Q 130 110 135 114" stroke="$gColor" stroke-width="2.4" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="87" y1="116" x2="81" y2="114" stroke="$gColor" stroke-width="2.4" stroke-linecap="round" />');
        sb.writeln('<line x1="173" y1="116" x2="179" y2="114" stroke="$gColor" stroke-width="2.4" stroke-linecap="round" />');
        sb.writeln('<path d="M 94 110 L 105 110" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" opacity="0.55" />');
        sb.writeln('<path d="M 142 110 L 153 110" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" opacity="0.55" />');
        break;

      case 'roundShades':
      case 'round':
        // Dark retro round shades (rockstar style)
        sb.writeln('<circle cx="106" cy="116" r="16.5" fill="#141416" stroke="$gColor" stroke-width="2.8" />');
        sb.writeln('<circle cx="154" cy="116" r="16.5" fill="#141416" stroke="$gColor" stroke-width="2.8" />');
        sb.writeln('<path d="M 122.5 114 Q 130 110 137.5 114" stroke="$gColor" stroke-width="3.0" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="89.5" y1="116" x2="81" y2="113" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" />');
        sb.writeln('<line x1="170.5" y1="116" x2="179" y2="113" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" />');
        sb.writeln('<ellipse cx="102" cy="112" rx="7" ry="4" transform="rotate(-30 102 112)" fill="#ffffff" opacity="0.22" />');
        sb.writeln('<ellipse cx="150" cy="112" rx="7" ry="4" transform="rotate(-30 150 112)" fill="#ffffff" opacity="0.22" />');
        break;

      case 'cyberVisor':
        // Cyberpunk holographic aerodynamic visor
        sb.writeln('<path d="M 82 107 C 104 102 156 102 178 107 L 175 125 C 153 129 107 129 85 125 Z" fill="#0f172a" fill-opacity="0.85" stroke="$gColor" stroke-width="2.6" stroke-linejoin="round" />');
        sb.writeln('<path d="M 85 116 C 106 112 154 112 175 116" stroke="$gColor" stroke-width="1.6" opacity="0.9" />');
        sb.writeln('<rect x="91" y="109" width="4" height="2" rx="0.5" fill="#00ffcc" />');
        sb.writeln('<rect x="165" y="109" width="4" height="2" rx="0.5" fill="#00ffcc" />');
        sb.writeln('<path d="M 86 111 L 84 111 L 84 121 L 86 121" stroke="#00ffff" stroke-width="1.2" fill="none" />');
        sb.writeln('<path d="M 174 111 L 176 111 L 176 121 L 174 121" stroke="#00ffff" stroke-width="1.2" fill="none" />');
        sb.writeln('<line x1="126" y1="113" x2="134" y2="113" stroke="#00ffcc" stroke-width="1.5" />');
        sb.writeln('<path d="M 88 106 C 106 103 154 103 172 106" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" opacity="0.6" />');
        break;

      case 'halfRim':
        // Executive half-rim reading spectacles
        sb.writeln('<path d="M 88 105 C 98 103 121 103 124 107 L 124 112 C 120 108 97 108 89 110 Z" fill="$gColor" />');
        sb.writeln('<path d="M 172 105 C 162 103 139 103 136 107 L 136 112 C 140 108 163 108 171 110 Z" fill="$gColor" />');
        sb.writeln('<path d="M 89 105.5 C 98 104.5 120 104.5 123 107" stroke="#ffffff" stroke-width="1.0" opacity="0.45" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 171 105.5 C 162 104.5 140 104.5 137 107" stroke="#ffffff" stroke-width="1.0" opacity="0.45" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 89 110 C 89 125 118 128 124 112" stroke="#94a3b8" stroke-width="1.4" stroke-dasharray="4,2" fill="none" opacity="0.6" />');
        sb.writeln('<path d="M 171 110 C 171 125 142 128 136 112" stroke="#94a3b8" stroke-width="1.4" stroke-dasharray="4,2" fill="none" opacity="0.6" />');
        sb.writeln('<path d="M 124 107 Q 130 104 136 107" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" fill="none" />');
        sb.writeln('<line x1="88" y1="105" x2="81" y2="107" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" />');
        sb.writeln('<line x1="172" y1="105" x2="179" y2="107" stroke="$gColor" stroke-width="2.6" stroke-linecap="round" />');
        sb.writeln('<path d="M 94 112 L 102 122" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" opacity="0.4" />');
        sb.writeln('<path d="M 142 112 L 150 122" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" opacity="0.4" />');
        break;

      case 'none':
      default:
        break;
    }
  }

  static void _appendHeadphones(StringBuffer sb, String accColor) {
    sb.writeln('<path d="M 66 124 C 64 44 196 44 194 124" stroke="$accColor" stroke-width="7" fill="none" stroke-linecap="round" />');
    sb.writeln('<rect x="58" y="112" width="16" height="32" rx="8" fill="$accColor" />');
    sb.writeln('<circle cx="66" cy="128" r="3" fill="#00ffcc" />');
    sb.writeln('<rect x="186" y="112" width="16" height="32" rx="8" fill="$accColor" />');
    sb.writeln('<circle cx="194" cy="128" r="3" fill="#00ffcc" />');
  }

  /// Generates a standalone thumbnail SVG for face shape selection
  static String buildFaceShapeThumbnailSvg({
    required String faceShape,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="50 30 160 160" width="100%" height="100%">');

    // Ears
    sb.writeln('<path d="M 90 100 C 76 98 62 103 62 113 C 62 122 70 127 80 127 C 86 127 88 128 90 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 170 100 C 184 98 198 103 198 113 C 198 122 190 127 180 127 C 174 127 172 128 170 129 Z" fill="$skin" />');

    // Head path
    _appendHead(sb, faceShape, skin);

    // Subtle facial guide markers (brows, eyes & smile) to provide clear facial context
    sb.writeln('<path d="M 98 102 Q 108 97 118 102" stroke="#18181b" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.45" />');
    sb.writeln('<path d="M 142 102 Q 152 97 162 102" stroke="#18181b" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.45" />');
    sb.writeln('<path d="M 100 115 Q 108 110 116 115" stroke="#18181b" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.35" />');
    sb.writeln('<path d="M 144 115 Q 152 110 160 115" stroke="#18181b" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.35" />');
    sb.writeln('<path d="M 124 148 Q 130 153 136 148" stroke="#18181b" stroke-width="2.0" stroke-linecap="round" fill="none" opacity="0.4" />');

    // Hairline outline showing cranium proportion
    sb.writeln('<path d="M 75 92 C 85 62 120 60 130 66 C 140 60 175 62 185 92" stroke="#18181b" stroke-width="2.0" stroke-linecap="round" fill="none" opacity="0.22" />');

    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for hair selection
  static String buildHairThumbnailSvg({
    required String hairStyle,
    required String hairColor,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final hair = _c(hairColor);

    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="50 30 160 160" width="100%" height="100%">');

    _appendBackHair(sb, hairStyle, hair);

    // Base Head & Ears Silhouette
    sb.writeln('<path d="M 90 100 C 76 98 62 103 62 113 C 62 122 70 127 80 127 C 86 127 88 128 90 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 170 100 C 184 98 198 103 198 113 C 198 122 190 127 180 127 C 174 127 172 128 170 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 75 100 C 75 36 185 36 185 100 C 185 126 181 144 176 151 C 170 162 154 179 140 180 L 120 180 C 106 179 90 162 84 151 C 79 144 75 126 75 100 Z" fill="$skin" />');

    _appendHair(sb, hairStyle, hair, '#086057', skin);

    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for hat/headwear selection
  static String buildHatThumbnailSvg({
    required String hat,
    required String hatColor,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final hatC = _c(hatColor);

    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="35 15 190 170" width="100%" height="100%">');

    // Base head & ears silhouette
    sb.writeln('<path d="M 90 100 C 76 98 62 103 62 113 C 62 122 70 127 80 127 C 86 127 88 128 90 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 170 100 C 184 98 198 103 198 113 C 198 122 190 127 180 127 C 174 127 172 128 170 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 75 100 C 75 36 185 36 185 100 C 185 126 181 144 176 151 C 170 162 154 179 140 180 L 120 180 C 106 179 90 162 84 151 C 79 144 75 126 75 100 Z" fill="$skin" />');

    if (hat == 'none') {
      sb.writeln('<line x1="88" y1="65" x2="172" y2="145" stroke="#ef4444" stroke-width="3.5" stroke-linecap="round" opacity="0.4" />');
    } else {
      _appendHat(sb, hat, hatC, '#086057', skin);
    }

    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Contextual eyebrow styling to complement each eye expression in thumbnails
  static void _appendThumbnailEyebrows(StringBuffer sb, String eyeType) {
    const browColor = '#3a2720';
    switch (eyeType) {
      case 'intense':
        sb.writeln('<path d="M 91 97 L 123 102" stroke="$browColor" stroke-width="4.0" stroke-linecap="round" />');
        sb.writeln('<path d="M 137 102 L 169 97" stroke="$browColor" stroke-width="4.0" stroke-linecap="round" />');
        break;
      case 'surprised':
        sb.writeln('<path d="M 90 90 C 100 83 111 83 120 90" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 170 90 C 160 83 149 83 140 90" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        break;
      case 'eyeRoll':
        sb.writeln('<path d="M 90 98 L 120 98" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" />');
        sb.writeln('<path d="M 140 93 C 149 87 159 87 170 91" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        break;
      case 'happy':
      case 'cryingJoy':
        sb.writeln('<path d="M 89 97 C 99 91 111 91 121 96" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 171 97 C 161 91 149 91 139 96" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        break;
      case 'wink':
        sb.writeln('<path d="M 119 99 C 111 93 101 93 90 98" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 140 93 C 149 87 159 87 170 91" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        break;
      case 'sleepy':
        sb.writeln('<path d="M 91 100 L 121 101" stroke="$browColor" stroke-width="3.6" stroke-linecap="round" />');
        sb.writeln('<path d="M 139 101 L 169 100" stroke="$browColor" stroke-width="3.6" stroke-linecap="round" />');
        break;
      case 'cool':
        sb.writeln('<path d="M 90 98 L 122 100" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" />');
        sb.writeln('<path d="M 138 100 L 170 96" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" />');
        break;
      case 'sparkle':
        sb.writeln('<path d="M 90 94 C 100 87 111 87 120 93" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 170 94 C 160 87 149 87 140 93" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        break;
      case 'confident':
      case 'default':
      default:
        sb.writeln('<path d="M 119 99 C 111 93 101 93 90 98" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        sb.writeln('<path d="M 141 99 C 149 93 159 93 170 98" stroke="$browColor" stroke-width="3.8" stroke-linecap="round" fill="none" />');
        break;
    }
  }

  /// Generates a standalone thumbnail SVG for eye selection
  static String buildEyesThumbnailSvg({
    required String eyeType,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="70 80 120 72" width="100%" height="100%">');
    sb.writeln('<rect x="70" y="80" width="120" height="72" rx="18" fill="$skin" />');
    _appendThumbnailEyebrows(sb, eyeType);
    _appendEyes(sb, eyeType);
    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for eyebrow selection
  static String buildEyebrowThumbnailSvg({
    required String eyebrowType,
    required String hairColor,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final hair = _c(hairColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="75 78 110 46" width="100%" height="100%">');
    sb.writeln('<rect x="75" y="78" width="110" height="46" rx="14" fill="$skin" />');
    _appendEyebrows(sb, eyebrowType, hair);
    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for mouth expression
  static String buildMouthThumbnailSvg({
    required String mouthType,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="85 125 90 50" width="100%" height="100%">');
    sb.writeln('<rect x="85" y="125" width="90" height="50" rx="16" fill="$skin" />');
    _appendMouth(sb, mouthType);
    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for beard selection
  static String buildBeardThumbnailSvg({
    required String beard,
    required String beardColor,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final bColor = _c(beardColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="50 90 160 105" width="100%" height="100%">');
    sb.writeln('<path d="M 90 100 C 76 98 62 103 62 113 C 62 122 70 127 80 127 C 86 127 88 128 90 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 170 100 C 184 98 198 103 198 113 C 198 122 190 127 180 127 C 174 127 172 128 170 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 75 100 C 75 36 185 36 185 100 C 185 126 181 144 176 151 C 170 162 154 179 140 180 L 120 180 C 106 179 90 162 84 151 C 79 144 75 126 75 100 Z" fill="$skin" />');
    _appendBeard(sb, beard, bColor, 'chiseledSquare');
    _appendMouth(sb, 'smile');
    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for moustache selection
  static String buildMoustacheThumbnailSvg({
    required String moustache,
    required String moustacheColor,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final mColor = _c(moustacheColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="96 126 68 44" width="100%" height="100%">');
    sb.writeln('<rect x="96" y="126" width="68" height="44" rx="8" fill="$skin" />');
    // Nose tip outline for anatomical reference
    sb.writeln('<path d="M 127 127 L 127 132 C 127 135 133 136 136 132" stroke="#4a4a4f" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none" opacity="0.4" />');
    _appendMouth(sb, 'smile');
    _appendMoustache(sb, moustache, mColor);
    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for facial hair (backward compatibility)
  static String buildFacialHairThumbnailSvg({
    required String facialHair,
    required String facialHairColor,
    required String skinColor,
  }) {
    if (facialHair == 'moustacheFancy' || facialHair.contains('moustache')) {
      return buildMoustacheThumbnailSvg(
        moustache: facialHair == 'moustacheFancy' ? 'handlebar' : 'classic',
        moustacheColor: facialHairColor,
        skinColor: skinColor,
      );
    }
    return buildBeardThumbnailSvg(
      beard: facialHair,
      beardColor: facialHairColor,
      skinColor: skinColor,
    );
  }

  /// Generates a standalone thumbnail SVG for clothing
  static String buildClothingThumbnailSvg({
    required String clothing,
    required String clothingColor,
  }) {
    final cloth = _c(clothingColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="50 170 160 90" width="100%" height="100%">');
    sb.writeln('<rect x="109" y="160" width="42" height="44" rx="4" fill="#ffdbb4" />');
    _appendClothing(sb, clothing, cloth);
    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for glasses selection
  static String buildGlassesThumbnailSvg({
    required String glasses,
    required String glassesColor,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final gColor = _c(glassesColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="50 80 160 90" width="100%" height="100%">');
    // Base head silhouette & ears
    sb.writeln('<path d="M 90 100 C 76 98 62 103 62 113 C 62 122 70 127 80 127 C 86 127 88 128 90 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 170 100 C 184 98 198 103 198 113 C 198 122 190 127 180 127 C 174 127 172 128 170 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 75 100 C 75 36 185 36 185 100 C 185 126 181 144 176 151 C 170 162 154 179 140 180 L 120 180 C 106 179 90 162 84 151 C 79 144 75 126 75 100 Z" fill="$skin" />');

    _appendEyes(sb, 'confident');

    if (glasses == 'none') {
      sb.writeln('<line x1="88" y1="95" x2="172" y2="155" stroke="#ef4444" stroke-width="3.5" stroke-linecap="round" opacity="0.4" />');
    } else {
      _appendGlasses(sb, glasses, gColor);
    }

    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for jewelry/headphones accessories
  static String buildAccessoriesThumbnailSvg({
    required String accessory,
    required String accessoryColor,
    required String skinColor,
  }) {
    final skin = _c(skinColor);
    final acc = _c(accessoryColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="50 80 160 90" width="100%" height="100%">');
    sb.writeln('<path d="M 90 100 C 76 98 62 103 62 113 C 62 122 70 127 80 127 C 86 127 88 128 90 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 170 100 C 184 98 198 103 198 113 C 198 122 190 127 180 127 C 174 127 172 128 170 129 Z" fill="$skin" />');
    sb.writeln('<path d="M 75 100 C 75 36 185 36 185 100 C 185 126 181 144 176 151 C 170 162 154 179 140 180 L 120 180 C 106 179 90 162 84 151 C 79 144 75 126 75 100 Z" fill="$skin" />');

    if (accessory == 'hoopEarrings') {
      sb.writeln('<circle cx="69" cy="130" r="8" stroke="$acc" stroke-width="2.8" fill="none" />');
      sb.writeln('<circle cx="191" cy="130" r="8" stroke="$acc" stroke-width="2.8" fill="none" />');
    } else if (accessory == 'studEarrings') {
      sb.writeln('<circle cx="71" cy="125" r="3.2" fill="$acc" />');
      sb.writeln('<circle cx="71.8" cy="124.2" r="1.0" fill="#ffffff" opacity="0.8" />');
      sb.writeln('<circle cx="189" cy="125" r="3.2" fill="$acc" />');
      sb.writeln('<circle cx="189.8" cy="124.2" r="1.0" fill="#ffffff" opacity="0.8" />');
    } else if (accessory == 'bindi') {
      sb.writeln('<circle cx="130" cy="98" r="3.5" fill="#dc2626" />');
      sb.writeln('<circle cx="130" cy="98" r="1.3" fill="#fbbf24" />');
    } else if (accessory == 'headphones') {
      _appendHeadphones(sb, acc);
    } else if (accessory == 'none') {
      sb.writeln('<line x1="88" y1="95" x2="172" y2="155" stroke="#ef4444" stroke-width="3.5" stroke-linecap="round" opacity="0.4" />');
    }

    _appendEyes(sb, 'confident');
    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Generates a standalone thumbnail SVG for backdrop style
  static String buildBackdropThumbnailSvg({
    required String bgStyle,
    required String bgColor,
  }) {
    final bg = _c(bgColor);
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100%" height="100%">');
    if (bgStyle == 'cloud') {
      sb.writeln('<path d="M 20 80 C 8 72 6 52 14 40 C 6 28 18 14 34 17 C 40 7 60 7 66 17 C 82 14 94 28 86 40 C 94 52 92 72 80 80 L 80 95 L 20 95 Z" fill="$bg" />');
      sb.writeln('<path d="M 10 38 C 5 24 18 8 32 13" stroke="$bg" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.8" />');
    } else if (bgStyle == 'circle') {
      sb.writeln('<circle cx="50" cy="50" r="42" fill="$bg" />');
    } else if (bgStyle == 'squircle') {
      sb.writeln('<rect x="10" y="10" width="80" height="80" rx="20" fill="$bg" />');
    } else {
      sb.writeln('<rect x="10" y="10" width="80" height="80" rx="16" stroke="#94a3b8" stroke-width="2" stroke-dasharray="6,4" fill="none" />');
    }
    sb.writeln('</svg>');
    return sb.toString();
  }
}
