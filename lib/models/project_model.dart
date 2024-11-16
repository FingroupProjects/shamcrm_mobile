  class Project {
    final int id;
    final String name;
    final String? startDate;
    final String? endDate;


    Project({
      required this.id,
      required this.name,
      this.endDate,
      this.startDate,
    });

    factory Project.fromJson(Map<String, dynamic> json) {
      return Project(
        id: json['id'],
        name: json['name'],
        startDate: json['start_date'],
        endDate: json['end_date']
      );
    }
  }
