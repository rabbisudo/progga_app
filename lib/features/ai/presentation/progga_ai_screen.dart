import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../data/ai_repository.dart';

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String? imagePath;
  final String? subject;
  final DateTime timestamp;

  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.imagePath,
    this.subject,
    required this.timestamp,
  });
}

class ProggaAiScreen extends ConsumerStatefulWidget {
  const ProggaAiScreen({super.key});

  @override
  ConsumerState<ProggaAiScreen> createState() => _ProggaAiScreenState();
}

class _ProggaAiScreenState extends ConsumerState<ProggaAiScreen> {
  final List<String> _subjects = [
    'পদার্থবিজ্ঞান',
    'রসায়ন',
    'উচ্চতর গণিত',
    'জীববিজ্ঞান',
    'বাংলা',
    'ইংরেজি',
    'সাধারণ',
  ];

  late String _selectedSubject;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<AiChatMessage> _messages = [];
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _attachedImagePath;
  bool _isLoading = false;
  int _remainingTokens = 5;
  int _totalTokens = 5;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedSubject = _subjects.first;
    _loadTokenStatus();

    // Initial welcome message from Progga AI
    _messages.add(
      AiChatMessage(
        id: 'welcome_msg',
        text: 'আসসালামু আলাইকুম! আমি **Progga AI** 🤖\n\nপদার্থবিজ্ঞান, রসায়ন, উচ্চতর গণিত বা যেকোনো বিষয়ের ডাউট লিখে পাঠাও অথবা বইয়ের অংকের ছবি আপলোড করো। আমি ধাপে ধাপে বুঝিয়ে দেবো!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenStatus() async {
    try {
      final status = await ref.read(aiRepositoryProvider).fetchTokenStatus();
      if (mounted) {
        setState(() {
          _remainingTokens = (status['remainingTokens'] as num?)?.toInt() ?? 5;
          _totalTokens = (status['totalTokens'] as num?)?.toInt() ?? 5;
        });
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (photo != null) {
        setState(() {
          _attachedImagePath = photo.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি নির্বাচন করতে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ছবি যুক্ত করুন',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Color(0xFF017A47), size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text('ক্যামেরা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library, color: Color(0xFF017A47), size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text('গ্যালারি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTokenLimitModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.bolt, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('ফ্রি টোকেন শেষ!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'আজকের জন্য আপনার ৫টি ফ্রি AI ডাউট সলভ টোকেন শেষ হয়েছে।\n\nআগামীকাল রাত ১২টায় নতুন ৫টি টোকেন রিফ্রেশ হবে!',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF017A47),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ঠিক আছে', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _promptController.text.trim();
    if (text.isEmpty && _attachedImagePath == null) return;

    final String? currentImagePath = _attachedImagePath;
    final String currentSubject = _selectedSubject;

    setState(() {
      _messages.add(
        AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text.isNotEmpty ? text : 'ছবিটির সমাধান দিন',
          isUser: true,
          imagePath: currentImagePath,
          subject: currentSubject,
          timestamp: DateTime.now(),
        ),
      );

      _promptController.clear();
      _attachedImagePath = null;
      _isLoading = true;
    });

    _scrollToBottom();

    final historyList = _messages
        .where((m) => m.id != 'welcome_msg')
        .map((m) => {'isUser': m.isUser, 'text': m.text})
        .toList();
    final String historyJson = jsonEncode(historyList);

    try {
      final res = await ref.read(aiRepositoryProvider).solveDoubt(
            subject: currentSubject,
            prompt: text,
            imagePath: currentImagePath,
            historyJson: historyJson,
          );

      final String aiAnswer = res['answer'] ?? 'কোনো সমাধান পাওয়া যায়নি।';
      final int newTokens = (res['remainingTokens'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          _remainingTokens = newTokens;
          _isLoading = false;
          _messages.add(
            AiChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: aiAnswer,
              isUser: false,
              subject: currentSubject,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(
            AiChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: _getFriendlyErrorMessage(e),
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  String _getFriendlyErrorMessage(dynamic e) {
    final str = e.toString().toLowerCase();

    if (str.contains('quota exceeded') || str.contains('429') || str.contains('কোটা লিমিট')) {
      return '⚠️ এআই সার্ভিস বর্তমানে কোটা ইস্যু দেখাচ্ছে। অনুগ্রহ করে কিছু সময় পর আবার চেষ্টা করুন।';
    } else if (str.contains('connection timeout') || str.contains('network') || str.contains('socket') || str.contains('timeout')) {
      return '⚠️ ইন্টারনেট সংযোগের সমস্যা হচ্ছে বা সার্ভার সাময়িক সাড়া দিচ্ছে না। আপনার কানেকশন চেক করে আবার চেষ্টা করুন।';
    } else if (str.contains('401') || str.contains('unauthorized')) {
      return '⚠️ আপনার সেশন শেষ হয়ে গেছে। অনুগ্রহ করে অ্যাপে পুনরায় লগইন করুন।';
    } else {
      return '⚠️ দুঃখিত! সমাধানটি পেতে সমস্যা হয়েছে। দয়া করে কিছুক্ষণ পর আবার চেষ্টা করুন।';
    }
  }

  String _formatFullDateTime(Map<String, dynamic> item) {
    try {
      final raw = item['createdAt'] ?? item['date'];
      if (raw == null) return item['date']?.toString() ?? '';

      final dt = DateTime.tryParse(raw.toString())?.toLocal();
      if (dt == null) return item['date']?.toString() ?? '';

      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;

      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';

      return '$day $month $year • $hour12:$minute $ampm';
    } catch (_) {
      return item['date']?.toString() ?? '';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupLogsByDate(List<dynamic> logs) {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'আজ (Today)': [],
      'গতকাল (Yesterday)': [],
      'পূর্ববর্তী (Earlier)': [],
    };

    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    for (var log in logs) {
      final map = log as Map<String, dynamic>;
      final dateStr = (map['date'] as String?) ?? (map['createdAt'] as String?)?.split('T')[0] ?? '';

      if (dateStr == todayStr) {
        grouped['আজ (Today)']!.add(map);
      } else if (dateStr == yesterdayStr) {
        grouped['গতকাল (Yesterday)']!.add(map);
      } else {
        grouped['পূর্ববর্তী (Earlier)']!.add(map);
      }
    }

    return grouped;
  }

  Widget _buildHistorySidebar() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF017A47), Color(0xFF015A34)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'চ্যাট হিস্ট্রি',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'সংরক্ষিত ডাউট সলভসমূহ',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: ref.read(aiRepositoryProvider).fetchHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF017A47)));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'কোনো পূর্ববর্তী ইতিহাস পাওয়া যায়নি।',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  final groupedLogs = _groupLogsByDate(snapshot.data!);

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: groupedLogs.entries.map<Widget>((entry) {
                      final groupTitle = entry.key;
                      final items = entry.value;

                      if (items.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Text(
                              groupTitle,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...items.map((item) {
                            final subjectName = item['subject'] ?? 'সাধারণ';
                            final promptStr = item['prompt'] ?? 'প্রশ্ন';
                            final fullTimeStr = _formatFullDateTime(item);

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                title: Text(
                                  promptStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        subjectName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF017A47),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(fullTimeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                                onTap: () {
                                  Navigator.pop(context);

                                  final String promptText = item['prompt'] ?? '';
                                  final String? answerText = item['answer'];
                                  final String subjectName = item['subject'] ?? 'সাধারণ';

                                  setState(() {
                                    _selectedSubject = subjectName;
                                    _messages.clear();

                                    _messages.add(
                                      AiChatMessage(
                                        id: '${DateTime.now().millisecondsSinceEpoch}_u',
                                        text: promptText,
                                        isUser: true,
                                        subject: subjectName,
                                        timestamp: DateTime.now(),
                                      ),
                                    );

                                    if (answerText != null && answerText.isNotEmpty) {
                                      _messages.add(
                                        AiChatMessage(
                                          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
                                          text: answerText,
                                          isUser: false,
                                          subject: subjectName,
                                          timestamp: DateTime.now(),
                                        ),
                                      );
                                    }
                                  });

                                  _scrollToBottom();

                                  if (answerText == null || answerText.isEmpty) {
                                    _sendMessage(promptText);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.50,
          minChildSize: 0.30,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'বিষয় নির্বাচন করুন',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _subjects.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final sub = _subjects[index];
                        final isSelected = sub == _selectedSubject;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSubject = sub;
                            });
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sub,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF017A47) : const Color(0xFF334155),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF017A47),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildHistorySidebar(),
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Progga AI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _showSubjectBottomSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF017A47), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _selectedSubject,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF017A47),
                        height: 1.0,
                      ),
                      strutStyle: const StrutStyle(
                        fontSize: 13,
                        height: 1.0,
                        forceStrutHeight: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF017A47), size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF017A47),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.bolt,
                  size: 13,
                  color: Color(0xFF017A47),
                ),
                SizedBox(width: 2),
                Text(
                  '∞ আনলিমিটেড',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF017A47),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (val) {
              if (val == 'new_chat') {
                setState(() {
                  _messages.clear();
                });
              } else if (val == 'history') {
                _scaffoldKey.currentState?.openEndDrawer();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: const [
                    Icon(Icons.add_comment_outlined, size: 18, color: Color(0xFF017A47)),
                    SizedBox(width: 8),
                    Text('নতুন চ্যাট', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 18, color: Color(0xFF017A47)),
                    SizedBox(width: 8),
                    Text('চ্যাট ইতিহাস', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, idx) {
                if (idx == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }
                final msg = _messages[idx];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // Attached Image Preview Container
          if (_attachedImagePath != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_attachedImagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ছবি সংযুক্ত করা হয়েছে',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _attachedImagePath = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input Dock Container
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF017A47)),
                    onPressed: _showImagePickerModal,
                    tooltip: 'ছবি যুক্ত করুন',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: '$_selectedSubject বিষয়ে ডাউট লিখুন...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0F2F0),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF017A47),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPill(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF017A47))),
        backgroundColor: const Color(0xFFE8F5E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
        onPressed: () => _sendMessage(label),
      ),
    );
  }

  Widget _buildChatBubble(AiChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFF017A47),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(msg.imagePath!),
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _buildAiResponseBody(msg.text, msg.subject),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAiResponseBody(String rawText, String? messageSubject) {
    String thinkingText = '';
    String mainText = rawText;

    final thinkingRegex = RegExp(r'<thinking>([\s\S]*?)</thinking>', caseSensitive: false);
    final match = thinkingRegex.firstMatch(rawText);

    if (match != null) {
      thinkingText = match.group(1)?.trim() ?? '';
      mainText = rawText.replaceAll(thinkingRegex, '').trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thinkingText.isNotEmpty)
          _ThinkingExpandableCard(thinkingText: thinkingText),
        MathMarkdown(data: mainText),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 4),
        _AiMessageActionBar(
          textToCopy: mainText,
          subject: messageSubject,
        ),
      ],
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF017A47)),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Progga AI is Thinking...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Building Context (Analyzing subject & topic)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Analyzing Query (Identifying core equations)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Composing Answer (Formatting step-by-step solution...)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF017A47), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingExpandableCard extends StatefulWidget {
  final String thinkingText;

  const _ThinkingExpandableCard({required this.thinkingText});

  @override
  State<_ThinkingExpandableCard> createState() => _ThinkingExpandableCardState();
}

class _ThinkingExpandableCardState extends State<_ThinkingExpandableCard> {
  bool _isExpanded = true;

  List<Map<String, String>> _parseThinkingSteps(String raw) {
    final List<Map<String, String>> steps = [];
    final lines = raw.split('\n');
    String currentTitle = '';
    String currentDesc = '';

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('Building Context') ||
          trimmed.startsWith('Analyzing Query') ||
          trimmed.startsWith('Gathering Information') ||
          trimmed.startsWith('Composing Answer') ||
          trimmed.startsWith('**')) {
        if (currentTitle.isNotEmpty) {
          steps.add({'title': currentTitle, 'desc': currentDesc.trim()});
          currentDesc = '';
        }
        currentTitle = trimmed.replaceAll('**', '');
      } else {
        if (currentTitle.isEmpty) {
          currentTitle = 'Analyzing Step';
        }
        currentDesc += (currentDesc.isEmpty ? '' : '\n') + trimmed;
      }
    }

    if (currentTitle.isNotEmpty) {
      steps.add({'title': currentTitle, 'desc': currentDesc.trim()});
    }

    if (steps.isEmpty) {
      steps.add({'title': 'Progga AI Thinking Process', 'desc': raw});
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _parseThinkingSteps(widget.thinkingText);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progga AI is Thinking...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps.map((step) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (step['desc']!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            step['desc']!,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiMessageActionBar extends StatefulWidget {
  final String textToCopy;
  final String? subject;

  const _AiMessageActionBar({
    required this.textToCopy,
    this.subject,
  });

  @override
  State<_AiMessageActionBar> createState() => _AiMessageActionBarState();
}

class _AiMessageActionBarState extends State<_AiMessageActionBar> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final displaySubject = (widget.subject != null && widget.subject!.isNotEmpty) ? widget.subject! : 'সাধারণ';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            displaySubject,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF017A47),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.textToCopy));
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.copy_rounded, size: 16, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () {
            setState(() {
              _isLiked = !_isLiked;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
              size: 16,
              color: _isLiked ? const Color(0xFF017A47) : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

class MathMarkdown extends StatelessWidget {
  final String data;
  final TextStyle textStyle;

  const MathMarkdown({
    super.key,
    required this.data,
    this.textStyle = const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
  });

  @override
  Widget build(BuildContext context) {
    final cleanData = data
        .replaceAll(RegExp(r'\\\[|\\\]'), '\$\$')
        .replaceAll(RegExp(r'\\\('), '\$')
        .replaceAll(RegExp(r'\\\)'), '\$');

    final List<Widget> widgets = [];
    final displayParts = cleanData.split('\$\$');

    for (int i = 0; i < displayParts.length; i++) {
      final part = displayParts[i];
      if (part.trim().isEmpty) continue;

      if (i % 2 == 1) {
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                part.trim(),
                textStyle: const TextStyle(fontSize: 16, color: Color(0xFF017A47), fontWeight: FontWeight.bold),
                onErrorFallback: (err) => Text(
                  '\$$part\$',
                  style: const TextStyle(color: Color(0xFF017A47), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      } else {
        widgets.add(_buildInlineMarkdownAndMath(part, context));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInlineMarkdownAndMath(String text, BuildContext context) {
    String processedText = text.replaceAllMapped(RegExp(r'\\text\{([^\}]+)\}'), (m) => m.group(1) ?? '');

    final inlineMathRegex = RegExp(r'\$([^\$\n]+)\$');
    processedText = processedText.replaceAllMapped(inlineMathRegex, (match) {
      String formula = match.group(1)?.trim() ?? '';
      formula = formula
          .replaceAll('^2', '²')
          .replaceAll('^3', '³')
          .replaceAll('_n', 'ₙ')
          .replaceAll('_0', '₀');
      return ' **$formula** ';
    });

    processedText = processedText
        .replaceAll(RegExp(r'\*\*\s+'), '**')
        .replaceAll(RegExp(r'\s+\*\*'), '**')
        .replaceAll('****', '**')
        .replaceAll('---', '');

    return MarkdownBody(
      data: processedText,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: textStyle,
        h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF017A47)),
        h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF017A47)),
        h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        listBullet: const TextStyle(fontSize: 14, color: Color(0xFF017A47), fontWeight: FontWeight.bold),
        code: const TextStyle(backgroundColor: Color(0xFFF0F2F0), fontFamily: 'monospace'),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
        ),
        blockquoteDecoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

