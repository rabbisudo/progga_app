class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String username;
  final String fullName;
  final String? institution;
  final String? avatarKey;
  final int xp;
  final int level;
  final int solvedQuestionsCount;
  final String league;
  final int currentStreak;
  final String? batch;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.username,
    required this.fullName,
    this.institution,
    this.avatarKey,
    required this.xp,
    required this.level,
    required this.solvedQuestionsCount,
    required this.league,
    required this.currentStreak,
    this.batch,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      institution: json['institution'] as String?,
      avatarKey: json['avatarKey'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      solvedQuestionsCount: (json['solvedQuestionsCount'] as num?)?.toInt() ?? 0,
      league: json['league'] as String? ?? 'BRONZE',
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      batch: json['batch'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'institution': institution,
      'avatarKey': avatarKey,
      'xp': xp,
      'level': level,
      'solvedQuestionsCount': solvedQuestionsCount,
      'league': league,
      'currentStreak': currentStreak,
      'batch': batch,
    };
  }
}
