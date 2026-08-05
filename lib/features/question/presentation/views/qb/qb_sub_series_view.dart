import 'package:flutter/material.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../widgets/bouncing_card.dart';

class QbSubSeriesView extends StatelessWidget {
  final Map<String, dynamic> activeSeries;
  final List<dynamic> seriesList;
  final List<String> seriesStack;
  final ValueChanged<List<String>> onStackChanged;
  final ValueChanged<String?> onActiveExamTabChanged;
  final ValueChanged<String> onExamSearchQueryChanged;

  const QbSubSeriesView({
    super.key,
    required this.activeSeries,
    required this.seriesList,
    required this.seriesStack,
    required this.onStackChanged,
    required this.onActiveExamTabChanged,
    required this.onExamSearchQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subSeriesListIds = (activeSeries['subSeries'] as List<dynamic>?) ?? [];
    final validSubSeries = subSeriesListIds.map((subId) {
      return seriesList.firstWhere(
        (s) => s['id']?.toString() == subId.toString(),
        orElse: () => null,
      );
    }).where((s) => s != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CustomBackButton(
                color: const Color(0xFF017A47),
                onPressed: () {
                  final newStack = List<String>.from(seriesStack)..removeLast();
                  onStackChanged(newStack);
                },
              ),
              Expanded(
                child: Text(
                  activeSeries['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16.0),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: validSubSeries.map<Widget>((subSeriesObj) {
              final subSeriesMap = subSeriesObj as Map<String, dynamic>;
              final subName = subSeriesMap['name']?.toString() ?? '';
              final subIdStr = subSeriesMap['id']?.toString() ?? '';

              Color cardColor = Colors.lightBlue.shade50;
              Color textColor = Colors.lightBlue.shade700;
              String icon = '📝';
              String title = subName;

              if (subName.toLowerCase().contains('mcq')) {
                cardColor = const Color(0xFFE3F2FD);
                textColor = const Color(0xFF1E88E5);
                icon = '📝';
                title = 'MCQ';
              } else if (subName.toLowerCase().contains('cq')) {
                cardColor = const Color(0xFFFFF8E1);
                textColor = const Color(0xFFF57F17);
                icon = '📖';
                title = 'CQ';
              } else if (subName.toLowerCase().contains('kbhandar')) {
                cardColor = const Color(0xFFE8EAF6);
                textColor = const Color(0xFF3F51B5);
                icon = '📚';
                title = 'ক ভাণ্ডার';
              } else if (subName.toLowerCase().contains('khabhandar')) {
                cardColor = const Color(0xFFE8F5E9);
                textColor = const Color(0xFF4CAF50);
                icon = '📚';
                title = 'খ ভাণ্ডার';
              } else if (subName.toLowerCase().contains('short') || subName.toLowerCase().contains('সংক্ষিপ্ত')) {
                cardColor = const Color(0xFFF3E5F5);
                textColor = const Color(0xFF9C27B0);
                icon = '⏱️';
                title = 'সংক্ষিপ্ত প্রশ্ন';
              }

              final subLogo = subSeriesMap['logo']?.toString() ?? subSeriesMap['banner']?.toString() ?? '';

              if (subLogo.isNotEmpty) {
                return BouncingCard(
                  onTap: () {
                    final newStack = List<String>.from(seriesStack)..add(subIdStr);
                    onStackChanged(newStack);
                    onActiveExamTabChanged(null);
                    onExamSearchQueryChanged('');
                  },
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          subLogo,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade50,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF017A47),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, _, __) => Container(
                            color: cardColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(icon, style: const TextStyle(fontSize: 32)),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return BouncingCard(
                onTap: () {
                  final newStack = List<String>.from(seriesStack)..add(subIdStr);
                  onStackChanged(newStack);
                  onActiveExamTabChanged(null);
                },
                child: Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF1E1E1E) : cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.05) : textColor.withOpacity(0.15), 
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
