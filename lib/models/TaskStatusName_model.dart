// role_model.dart
class StatusName {
  final int id;
  final String name;
  final String needspermission;
  

  StatusName({
    required this.id,
    required this.name,
    required this.needspermission,
   
  });

  factory StatusName.fromJson(Map<String, dynamic> json) {
    return StatusName(
      id: json['id'],
      name: json['name'],
      needspermission: json['needs_permission'],
      
    );
  }
}
