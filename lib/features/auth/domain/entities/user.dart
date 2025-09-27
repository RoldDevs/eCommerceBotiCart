class UserEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String contact;
  final String address;
  final List<String> addresses;
  final String? defaultAddress;
  final DateTime createdAt;
  final bool isVerified;
  final String status;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.contact,
    required this.address,
    this.addresses = const [],
    this.defaultAddress,
    required this.createdAt,
    required this.isVerified,
    required this.status,
    required this.updatedAt,
  });
}