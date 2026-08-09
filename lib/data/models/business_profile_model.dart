class BusinessProfileModel {
  const BusinessProfileModel({
    this.id,
    required this.businessName,
    this.ownerName,
    this.logoPath,
    this.mobile,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.gstRegistered = false,
    this.gstin,
    this.pan,
    this.invoicePrefix = 'INV',
    this.startingInvoiceNumber = 1,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ifsc,
    this.upiId,
    this.paymentQrPath,
    this.signaturePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String businessName;
  final String? ownerName;
  final String? logoPath;
  final String? mobile;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final bool gstRegistered;
  final String? gstin;
  final String? pan;
  final String invoicePrefix;
  final int startingInvoiceNumber;
  final String currencyCode;
  final String currencySymbol;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifsc;
  final String? upiId;
  final String? paymentQrPath;
  final String? signaturePath;
  final DateTime createdAt;
  final DateTime updatedAt;
}
