enum Role { admin, user }

class User {
  String username;
  String email;
  String password;
  Role role;
  String? imagePath;
  String? dateOfBirth;
  String? phone;
  String? address;

  User({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.imagePath,
    this.dateOfBirth,
    this.phone,
    this.address,
  });
}
