/// Mirrors the shape of one entry in config/teresa_rizal_citizens.php's
/// `accounts` array — the Web Admin's mock "log in as this resident" data.
/// The mobile app's registration/profile screens produce and consume this
/// same shape so a future backend integration maps cleanly onto a
/// `residents` table + `users` row (see Section 8 of the alignment doc:
/// the Web Admin currently has no such table at all).
class CitizenAccount {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String barangay;
  final String purok;
  final String address;
  final String birthdate;
  final String sex;
  final String civilStatus;
  final String occupation;
  final int profileCompleteness;
  final String status;

  CitizenAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.barangay,
    required this.purok,
    required this.address,
    required this.birthdate,
    required this.sex,
    required this.civilStatus,
    required this.occupation,
    required this.profileCompleteness,
    required this.status,
  });

  String get fullName => '$firstName $lastName';
  String get initials => ((firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobile': mobile,
        'barangay': barangay,
        'purok': purok,
        'address': address,
        'birthdate': birthdate,
        'sex': sex,
        'civilStatus': civilStatus,
        'occupation': occupation,
        'profileCompleteness': profileCompleteness,
        'status': status,
      };

  factory CitizenAccount.fromJson(Map<String, dynamic> json) => CitizenAccount(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        mobile: json['mobile'],
        barangay: json['barangay'],
        purok: json['purok'],
        address: json['address'],
        birthdate: json['birthdate'],
        sex: json['sex'],
        civilStatus: json['civilStatus'],
        occupation: json['occupation'],
        profileCompleteness: json['profileCompleteness'],
        status: json['status'],
      );
}
