class MedicalProfile {
  String name = '';
  int age = 0;
  String bloodGroup = '';
  List<String> allergies = [];
  List<String> medications = [];
  List<String> conditions = [];
  List<String> emergencyContacts = [];
  String address = '';
  String additionalNotes = '';

  MedicalProfile();

  bool get isComplete =>
      name.isNotEmpty && age > 0 && bloodGroup.isNotEmpty;

  factory MedicalProfile.fromJson(Map<String, dynamic> json) {
    return MedicalProfile()
      ..name = json['name'] as String? ?? ''
      ..age = json['age'] as int? ?? 0
      ..bloodGroup = json['bloodGroup'] as String? ?? ''
      ..allergies = List<String>.from(json['allergies'] ?? [])
      ..medications = List<String>.from(json['medications'] ?? [])
      ..conditions = List<String>.from(json['conditions'] ?? [])
      ..emergencyContacts = List<String>.from(json['emergencyContacts'] ?? [])
      ..address = json['address'] as String? ?? ''
      ..additionalNotes = json['additionalNotes'] as String? ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medications': medications,
      'conditions': conditions,
      'emergencyContacts': emergencyContacts,
      'address': address,
      'additionalNotes': additionalNotes,
    };
  }
}
