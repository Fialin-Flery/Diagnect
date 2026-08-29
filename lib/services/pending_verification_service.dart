class PendingVerificationService {
  PendingVerificationService._privateConstructor();

  static final PendingVerificationService instance =
  PendingVerificationService._privateConstructor();

  String? _aadhaarNumber;

  // =========================================================
  // SAVE AADHAAR
  // =========================================================

  void saveAadhaar(String aadhaarNumber) {
    _aadhaarNumber = aadhaarNumber;
  }

  // =========================================================
  // GET AADHAAR
  // =========================================================

  String? get aadhaarNumber {
    return _aadhaarNumber;
  }

  // =========================================================
  // CLEAR
  // =========================================================

  void clear() {
    _aadhaarNumber = null;
  }
}