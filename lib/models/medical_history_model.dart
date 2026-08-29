class MedicalHistoryModel {
  final int? id;

  final String? userId;

  final double? heightCm;

  final double? weightKg;

  final String? sex;

  final List<String> allergies;

  final String? chronicConditions;

  final String? currentMedications;

  final bool? hivAids;

  final bool? smoking;

  final bool? alcohol;

  final String? emergencyContact;

  final String? additionalNotes;

  final bool completed;

  final String? updatedAt;

  const MedicalHistoryModel({
    this.id,
    this.userId,
    this.heightCm,
    this.weightKg,
    this.sex,
    this.allergies = const [],
    this.chronicConditions,
    this.currentMedications,
    this.hivAids,
    this.smoking,
    this.alcohol,
    this.emergencyContact,
    this.additionalNotes,
    this.completed = false,
    this.updatedAt,
  });

// =========================================================
// FROM JSON
// =========================================================

  factory MedicalHistoryModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawAllergies =
    json['allergies'];

    final allergies = <String>[];

    if (rawAllergies is List) {
      for (final item in rawAllergies) {
        final value = item.toString().trim();

        if (value.isNotEmpty) {
          allergies.add(value);
        }
      }
    }

    return MedicalHistoryModel(
      id: _toInt(json['id']),

      userId:
      json['user_id']?.toString(),

      heightCm:
      _toDouble(json['height_cm']),

      weightKg:
      _toDouble(json['weight_kg']),

      sex:
      json['sex']?.toString(),

      allergies:
      List.unmodifiable(allergies),

      chronicConditions:
      json['chronic_conditions']
          ?.toString(),

      currentMedications:
      json['current_medications']
          ?.toString(),

      hivAids:
      _toNullableBool(
        json['hiv_aids'],
      ),

      smoking:
      _toNullableBool(
        json['smoking'],
      ),

      alcohol:
      _toNullableBool(
        json['alcohol'],
      ),

      emergencyContact:
      json['emergency_contact']
          ?.toString(),

      additionalNotes:
      json['additional_notes']
          ?.toString(),

      completed:
      json['completed'] == true,

      updatedAt:
      json['updated_at']
          ?.toString(),
    );
  }

// =========================================================
// TO JSON
// =========================================================

  Map<String, dynamic> toJson() {
    return {
      'height_cm': heightCm,

      'weight_kg': weightKg,

      'sex': sex,

      'allergies':
      List<String>.from(allergies),

      'chronic_conditions':
      chronicConditions,

      'current_medications':
      currentMedications,

      'hiv_aids':
      hivAids,

      'smoking':
      smoking,

      'alcohol':
      alcohol,

      'emergency_contact':
      emergencyContact,

      'additional_notes':
      additionalNotes,
    };
  }

// =========================================================
// HELPERS
// =========================================================

  static double? _toDouble(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static int? _toInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static bool? _toNullableBool(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value != 0;
    }

    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }

      if (value.toLowerCase() == 'false') {
        return false;
      }
    }

    return null;
  }
}

