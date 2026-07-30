class EmergencySession {
  final int? id;
  final DateTime createdAt;
  String emergencyDescription;
  List<String> imagePaths;
  String audioPath;
  String emergencyType;
  String aiAssessment;
  List<String> immediateActions;
  List<String> thingsToAvoid;
  List<String> monitor;
  String whenToSeekCare;
  List<String> followUpQuestions;
  List<String> followUpAnswers;
  String summary;
  bool isCompleted;

  EmergencySession({
    this.id,
    DateTime? createdAt,
    this.emergencyDescription = '',
    this.imagePaths = const [],
    this.audioPath = '',
    this.emergencyType = '',
    this.aiAssessment = '',
    this.immediateActions = const [],
    this.thingsToAvoid = const [],
    this.monitor = const [],
    this.whenToSeekCare = '',
    this.followUpQuestions = const [],
    this.followUpAnswers = const [],
    this.summary = '',
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory EmergencySession.fromJson(Map<String, dynamic> json) {
    return EmergencySession(
      id: json['id'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      emergencyDescription: json['emergencyDescription'] as String? ?? '',
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      audioPath: json['audioPath'] as String? ?? '',
      emergencyType: json['emergencyType'] as String? ?? '',
      aiAssessment: json['aiAssessment'] as String? ?? '',
      immediateActions: List<String>.from(json['immediateActions'] ?? []),
      thingsToAvoid: List<String>.from(json['thingsToAvoid'] ?? []),
      monitor: List<String>.from(json['monitor'] ?? []),
      whenToSeekCare: json['whenToSeekCare'] as String? ?? '',
      followUpQuestions: List<String>.from(json['followUpQuestions'] ?? []),
      followUpAnswers: List<String>.from(json['followUpAnswers'] ?? []),
      summary: json['summary'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'createdAt': createdAt.toIso8601String(),
      'emergencyDescription': emergencyDescription,
      'imagePaths': imagePaths,
      'audioPath': audioPath,
      'emergencyType': emergencyType,
      'aiAssessment': aiAssessment,
      'immediateActions': immediateActions,
      'thingsToAvoid': thingsToAvoid,
      'monitor': monitor,
      'whenToSeekCare': whenToSeekCare,
      'followUpQuestions': followUpQuestions,
      'followUpAnswers': followUpAnswers,
      'summary': summary,
      'isCompleted': isCompleted,
    };
  }

  EmergencySession copyWith({
    int? id,
    DateTime? createdAt,
    String? emergencyDescription,
    List<String>? imagePaths,
    String? audioPath,
    String? emergencyType,
    String? aiAssessment,
    List<String>? immediateActions,
    List<String>? thingsToAvoid,
    List<String>? monitor,
    String? whenToSeekCare,
    List<String>? followUpQuestions,
    List<String>? followUpAnswers,
    String? summary,
    bool? isCompleted,
  }) {
    return EmergencySession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      emergencyDescription: emergencyDescription ?? this.emergencyDescription,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPath: audioPath ?? this.audioPath,
      emergencyType: emergencyType ?? this.emergencyType,
      aiAssessment: aiAssessment ?? this.aiAssessment,
      immediateActions: immediateActions ?? this.immediateActions,
      thingsToAvoid: thingsToAvoid ?? this.thingsToAvoid,
      monitor: monitor ?? this.monitor,
      whenToSeekCare: whenToSeekCare ?? this.whenToSeekCare,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
      followUpAnswers: followUpAnswers ?? this.followUpAnswers,
      summary: summary ?? this.summary,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
