class UserProfile {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Cycle tracking preferences
  final int? averageCycleLength;
  final int? averagePeriodLength;
  final int? averageLutealPhase;
  final DateTime? lastPeriodStart;
  final bool notificationsEnabled;
  final bool partnerSharingEnabled;
  final String? partnerId;
  
  // Privacy settings
  final bool dataSharingEnabled;
  final bool analyticsEnabled;
  final bool marketingEmailsEnabled;
  
  // Wellness preferences
  final List<String> wellnessGoals;
  final List<String> healthConditions;
  final List<String> medications;
  final bool lifestyleTrackingEnabled;

  UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.averageCycleLength,
    this.averagePeriodLength,
    this.averageLutealPhase,
    this.lastPeriodStart,
    this.notificationsEnabled = true,
    this.partnerSharingEnabled = false,
    this.partnerId,
    this.dataSharingEnabled = false,
    this.analyticsEnabled = true,
    this.marketingEmailsEnabled = false,
    this.wellnessGoals = const [],
    this.healthConditions = const [],
    this.medications = const [],
    this.lifestyleTrackingEnabled = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      averageCycleLength: json['average_cycle_length'],
      averagePeriodLength: json['average_period_length'],
      averageLutealPhase: json['average_luteal_phase'],
      lastPeriodStart: json['last_period_start'] != null 
          ? DateTime.parse(json['last_period_start']) 
          : null,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      partnerSharingEnabled: json['partner_sharing_enabled'] ?? false,
      partnerId: json['partner_id'],
      dataSharingEnabled: json['data_sharing_enabled'] ?? false,
      analyticsEnabled: json['analytics_enabled'] ?? true,
      marketingEmailsEnabled: json['marketing_emails_enabled'] ?? false,
      wellnessGoals: List<String>.from(json['wellness_goals'] ?? []),
      healthConditions: List<String>.from(json['health_conditions'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      lifestyleTrackingEnabled: json['lifestyle_tracking_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'average_cycle_length': averageCycleLength,
      'average_period_length': averagePeriodLength,
      'average_luteal_phase': averageLutealPhase,
      'last_period_start': lastPeriodStart?.toIso8601String(),
      'notifications_enabled': notificationsEnabled,
      'partner_sharing_enabled': partnerSharingEnabled,
      'partner_id': partnerId,
      'data_sharing_enabled': dataSharingEnabled,
      'analytics_enabled': analyticsEnabled,
      'marketing_emails_enabled': marketingEmailsEnabled,
      'wellness_goals': wellnessGoals,
      'health_conditions': healthConditions,
      'medications': medications,
      'lifestyle_tracking_enabled': lifestyleTrackingEnabled,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? averageCycleLength,
    int? averagePeriodLength,
    int? averageLutealPhase,
    DateTime? lastPeriodStart,
    bool? notificationsEnabled,
    bool? partnerSharingEnabled,
    String? partnerId,
    bool? dataSharingEnabled,
    bool? analyticsEnabled,
    bool? marketingEmailsEnabled,
    List<String>? wellnessGoals,
    List<String>? healthConditions,
    List<String>? medications,
    bool? lifestyleTrackingEnabled,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      averageLutealPhase: averageLutealPhase ?? this.averageLutealPhase,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      partnerSharingEnabled: partnerSharingEnabled ?? this.partnerSharingEnabled,
      partnerId: partnerId ?? this.partnerId,
      dataSharingEnabled: dataSharingEnabled ?? this.dataSharingEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      marketingEmailsEnabled: marketingEmailsEnabled ?? this.marketingEmailsEnabled,
      wellnessGoals: wellnessGoals ?? this.wellnessGoals,
      healthConditions: healthConditions ?? this.healthConditions,
      medications: medications ?? this.medications,
      lifestyleTrackingEnabled: lifestyleTrackingEnabled ?? this.lifestyleTrackingEnabled,
    );
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email.split('@').first;
  }

  int? get age {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int age = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month || 
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        age--;
      }
      return age;
    }
    return null;
  }
}

