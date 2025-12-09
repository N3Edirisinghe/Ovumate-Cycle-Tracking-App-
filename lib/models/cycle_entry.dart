import 'package:easy_localization/easy_localization.dart';

enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal,
  unknown;

  String get phaseDisplayName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
      case CyclePhase.unknown:
        return 'Unknown';
    }
  }
}

enum SymptomSeverity {
  none,
  mild,
  moderate,
  severe
}

class CycleEntry {
  final String id;
  final String userId;
  final DateTime date;
  final CyclePhase phase;
  final bool isPeriodDay;
  final int? periodFlow; // 1-5 scale
  final List<String> symptoms;
  final Map<String, SymptomSeverity> symptomSeverity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional lifestyle tracking
  final double? sleepHours;
  final int? waterIntake; // in ml
  final int? stressLevel; // 1-10 scale
  final String? mood;
  final List<String> activities;
  final bool tookMedication;
  final String? medicationNotes;

  CycleEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.phase,
    required this.isPeriodDay,
    this.periodFlow,
    this.symptoms = const [],
    this.symptomSeverity = const {},
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.sleepHours,
    this.waterIntake,
    this.stressLevel,
    this.mood,
    this.activities = const [],
    this.tookMedication = false,
    this.medicationNotes,
  });

  factory CycleEntry.fromJson(Map<String, dynamic> json) {
    return CycleEntry(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      phase: CyclePhase.values.firstWhere(
        (e) => e.toString().split('.').last == json['phase'],
        orElse: () => CyclePhase.unknown,
      ),
      isPeriodDay: json['is_period_day'] ?? false,
      periodFlow: json['period_flow'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      symptomSeverity: Map<String, SymptomSeverity>.from(
        (json['symptom_severity'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            SymptomSeverity.values.firstWhere(
              (e) => e.toString().split('.').last == value,
              orElse: () => SymptomSeverity.none,
            ),
          ),
        ) ?? {},
      ),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sleepHours: json['sleep_hours'] != null ? (json['sleep_hours'] as num).toDouble() : null,
      waterIntake: json['water_intake'],
      stressLevel: json['stress_level'],
      mood: json['mood'],
      activities: List<String>.from(json['activities'] ?? []),
      tookMedication: json['took_medication'] ?? false,
      medicationNotes: json['medication_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'phase': phase.toString().split('.').last,
      'is_period_day': isPeriodDay,
      'period_flow': periodFlow,
      'symptoms': symptoms,
      'symptom_severity': symptomSeverity.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sleep_hours': sleepHours,
      'water_intake': waterIntake,
      'stress_level': stressLevel,
      'mood': mood,
      'activities': activities,
      'took_medication': tookMedication,
      'medication_notes': medicationNotes,
    };
  }

  CycleEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    CyclePhase? phase,
    bool? isPeriodDay,
    int? periodFlow,
    List<String>? symptoms,
    Map<String, SymptomSeverity>? symptomSeverity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? sleepHours,
    int? waterIntake,
    int? stressLevel,
    String? mood,
    List<String>? activities,
    bool? tookMedication,
    String? medicationNotes,
  }) {
    return CycleEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      phase: phase ?? this.phase,
      isPeriodDay: isPeriodDay ?? this.isPeriodDay,
      periodFlow: periodFlow ?? this.periodFlow,
      symptoms: symptoms ?? this.symptoms,
      symptomSeverity: symptomSeverity ?? this.symptomSeverity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sleepHours: sleepHours ?? this.sleepHours,
      waterIntake: waterIntake ?? this.waterIntake,
      stressLevel: stressLevel ?? this.stressLevel,
      mood: mood ?? this.mood,
      activities: activities ?? this.activities,
      tookMedication: tookMedication ?? this.tookMedication,
      medicationNotes: medicationNotes ?? this.medicationNotes,
    );
  }

  bool get hasLifestyleData {
    return sleepHours != null || 
           waterIntake != null || 
           stressLevel != null || 
           mood != null || 
           activities.isNotEmpty;
  }

  String get phaseDisplayName {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
      case CyclePhase.unknown:
        return 'Unknown';
    }
  }

  String get periodFlowDescription {
    if (periodFlow == null) return 'cycle_tracking.flow_intensity.not_specified'.tr();
    switch (periodFlow) {
      case 1:
        return 'cycle_tracking.flow_intensity.light'.tr();
      case 2:
        return 'cycle_tracking.flow_intensity.light_to_medium'.tr();
      case 3:
        return 'cycle_tracking.flow_intensity.medium'.tr();
      case 4:
        return 'cycle_tracking.flow_intensity.medium_to_heavy'.tr();
      case 5:
        return 'cycle_tracking.flow_intensity.heavy'.tr();
      default:
        return 'cycle_tracking.flow_intensity.not_specified'.tr();
    }
  }

  String get cyclePhase => phaseDisplayName;

  Map<String, dynamic> get lifestyleData {
    return {
      'sleepHours': sleepHours,
      'waterIntake': waterIntake,
      'stressLevel': stressLevel,
      'mood': mood,
      'activities': activities,
      'tookMedication': tookMedication,
      'medicationNotes': medicationNotes,
    };
  }
}

