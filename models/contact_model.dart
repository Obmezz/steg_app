class ContactModel {
  final String name;
  final String publicKey;
  final String fingerprint;
  bool isVerified;

  ContactModel({
    required this.name,
    required this.publicKey,
    required this.fingerprint,
    this.isVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'publicKey': publicKey,
      'fingerprint': fingerprint,
      'isVerified': isVerified ? 1 : 0,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      name: map['name'],
      publicKey: map['publicKey'],
      fingerprint: map['fingerprint'],
      isVerified: map['isVerified'] == 1,
    );
  }
}
