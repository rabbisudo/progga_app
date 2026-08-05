import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../exam/data/exam_repository.dart';
import '../../../core/widgets/custom_back_button.dart';

class ExamHistoryScreen extends ConsumerStatefulWidget {
  const ExamHistoryScreen({super.key});

  @override
  ConsumerState<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends ConsumerState<ExamHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _historyList = [];
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(1);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadPage(_currentPage);
      }
    }
  }

  Future<void> _loadPage(int page, {bool isRefresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _isFirstLoad = true;
      }
    });

    try {
      final repo = ref.read(examRepositoryProvider);
      final list = await repo.fetchExamHistory(page: page, limit: 30);
      
      setState(() {
        if (isRefresh) {
          _historyList.clear();
        }
        _historyList.addAll(list);
        _errorMessage = null;
        _isFirstLoad = false;
        
        if (list.length < 30) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isFirstLoad = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadPage(1, isRefresh: true);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = [
        'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
        'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
      ];
      final String day = _toBengaliNumber(date.day);
      final String year = _toBengaliNumber(date.year);
      final String month = months[date.month - 1];
      final String hour = _toBengaliNumber(date.hour.toString().padLeft(2, '0'));
      final String minute = _toBengaliNumber(date.minute.toString().padLeft(2, '0'));
      
      return '$day $month, $year - $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '০ সেকেন্ড';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${_toBengaliNumber(minutes)} মিনিট ${_toBengaliNumber(seconds)} সেকেন্ড';
    }
    return '${_toBengaliNumber(seconds)} সেকেন্ড';
  }

  static String _toBengaliNumber(dynamic input) {
    final Map<String, String> numbers = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    final String str = input.toString();
    var output = '';
    for (var i = 0; i < str.length; i++) {
      output += numbers[str[i]] ?? str[i];
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'পরীক্ষার History',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A202C),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: CustomBackButton(
          color: isDark ? Colors.white : const Color(0xFF1A202C),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF017A47),
        onRefresh: _onRefresh,
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isFirstLoad) {
      return const _SkeletonHistoryLoader();
    }

    if (_errorMessage != null && _historyList.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'History লোড করতে সমস্যা হয়েছে!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _onRefresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017A47),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('পুনরায় চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_historyList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE6F4EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_toggle_off, size: 48, color: Color(0xFF017A47)),
                ),
                const SizedBox(height: 20),
                Text(
                  'কোনো পরীক্ষার History পাওয়া যায়নি!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'পরীক্ষা শেষ করার পর এখানে History দেখতে পারবেন।',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white30 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _historyList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _historyList.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF017A47),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final session = _historyList[index];
        final String sessionId = session['id'] ?? '';
        final exam = session['exam'] ?? {};
        final String title = exam['title'] ?? 'কাস্টম পরীক্ষা';
        final String endedAtStr = session['endedAt'] ?? '';
        
        final double score = (session['score'] as num?)?.toDouble() ?? 0.0;
        final double totalMarks = (exam['totalMarks'] as num?)?.toDouble() ?? 0.0;
        final double accuracy = (session['accuracy'] as num?)?.toDouble() ?? 0.0;
        final int timeTaken = (session['timeTaken'] as num?)?.toInt() ?? 0;

        final questions = exam['questions'] as List<dynamic>? ?? [];
        String? subjectName;
        String? chapterName;
        if (questions.isNotEmpty) {
          final qItem = questions[0]['question'] ?? {};
          subjectName = qItem['subject']?['name'] as String?;
          chapterName = qItem['chapter']?['name'] as String?;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/result/$sessionId'),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A202C),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF00381C) : const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '${_toBengaliNumber(accuracy.toStringAsFixed(0))}% Accuracy',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF017A47),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (subjectName != null && subjectName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$subjectName${chapterName != null && chapterName.isNotEmpty ? " • $chapterName" : ""}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.green.shade300 : const Color(0xFF017A47),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),
                    Text(
                      _formatDate(endedAtStr),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey : const Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'প্রাপ্ত মার্কস',
                            '${_toBengaliNumber(score)} / ${_toBengaliNumber(totalMarks)}',
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            'সময় লেগেছে',
                            _formatTime(timeTaken),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFEDF2F7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF718096),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonHistoryLoader extends StatefulWidget {
  const _SkeletonHistoryLoader();

  @override
  State<_SkeletonHistoryLoader> createState() => _SkeletonHistoryLoaderState();
}

class _SkeletonHistoryLoaderState extends State<_SkeletonHistoryLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Opacity(
          opacity: opacity,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 16,
                          width: index % 2 == 0 ? 160 : 200,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          height: 22,
                          width: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8E6C9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 140,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade800 : const Color(0xFFEDF2F7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade800 : const Color(0xFFEDF2F7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
