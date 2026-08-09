class CustomerModel {
  const CustomerModel({
    this.id,
    required this.name,
    this.companyName,
    this.mobile,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.gstin,
    this.notes,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? companyName;
  final String? mobile;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? gstin;
  final String? notes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
}
