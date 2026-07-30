class AcademicBatchModel {
  final String id;
  final String name;
  final String classId;
  final String? groupId;
  final bool isActive;

  AcademicBatchModel({
    required this.id,
    required this.name,
    required this.classId,
    this.groupId,
    required this.isActive,
  });

  factory AcademicBatchModel.fromJson(Map<String, dynamic> json) {
    return AcademicBatchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      classId: json['classId'] as String,
      groupId: json['groupId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SubjectGroupModel {
  final String id;
  final String name;
  final String classId;
  final bool isActive;
  final List<AcademicBatchModel> batches;

  SubjectGroupModel({
    required this.id,
    required this.name,
    required this.classId,
    required this.isActive,
    required this.batches,
  });

  factory SubjectGroupModel.fromJson(Map<String, dynamic> json) {
    var rawBatches = json['batches'] as List<dynamic>? ?? [];
    return SubjectGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      classId: json['classId'] as String,
      isActive: json['isActive'] as bool? ?? true,
      batches: rawBatches.map((b) => AcademicBatchModel.fromJson(b)).toList(),
    );
  }
}

class AcademicClassModel {
  final String id;
  final String name;
  final bool hasGroup;
  final bool hasBatch;
  final bool isActive;
  final List<SubjectGroupModel> groups;
  final List<AcademicBatchModel> batches;

  AcademicClassModel({
    required this.id,
    required this.name,
    required this.hasGroup,
    required this.hasBatch,
    required this.isActive,
    required this.groups,
    required this.batches,
  });

  factory AcademicClassModel.fromJson(Map<String, dynamic> json) {
    var rawGroups = json['groups'] as List<dynamic>? ?? [];
    var rawBatches = json['batches'] as List<dynamic>? ?? [];
    return AcademicClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hasGroup: json['hasGroup'] as bool? ?? false,
      hasBatch: json['hasBatch'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      groups: rawGroups.map((g) => SubjectGroupModel.fromJson(g)).toList(),
      batches: rawBatches.map((b) => AcademicBatchModel.fromJson(b)).toList(),
    );
  }
}
