abstract class ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final int userId;
  final String name;
  final String sname;
  final String pname;
  final String phone;
  final String? email;
  final String? login;
  final String? role;
  final String? image;
  UpdateProfile({
    required this.userId,
    required this.name,
    required this.sname,
    required this.pname,
    required this.phone,
    this.email,
    this.login,
    this.role,
    this.image,
  });
}
