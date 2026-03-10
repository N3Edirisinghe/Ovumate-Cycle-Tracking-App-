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
    // Handle both snake_case (from Supabase) and camelCase (from old local storage) formats
    final id = json['id'] ?? json['userId'] ?? '';
    final email = json['email'] ?? '';
    
    // Parse dates with error handling for backward compatibility
    DateTime? dateOfBirth;
    try {
      final dobValue = json['date_of_birth'] ?? json['dateOfBirth'];
      if (dobValue != null) {
        dateOfBirth = dobValue is String ? DateTime.parse(dobValue) : dobValue as DateTime?;
      }
    } catch (e) {
      dateOfBirth = null;
    }
    
    DateTime createdAt;
    try {
      final createdValue = json['created_at'] ?? json['createdAt'];
      if (createdValue != null) {
        createdAt = createdValue is String ? DateTime.parse(createdValue) : createdValue as DateTime;
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    DateTime updatedAt;
    try {
      final updatedValue = json['updated_at'] ?? json['updatedAt'];
      if (updatedValue != null) {
        updatedAt = updatedValue is String ? DateTime.parse(updatedValue) : updatedValue as DateTime;
      } else {
        updatedAt = DateTime.now();
      }
    } catch (e) {
      updatedAt = DateTime.now();
    }
    
    DateTime? lastPeriodStart;
    try {
      final lastPeriodValue = json['last_period_start'] ?? json['lastPeriodStart'];
      if (lastPeriodValue != null) {
        lastPeriodStart = lastPeriodValue is String ? DateTime.parse(lastPeriodValue) : lastPeriodValue as DateTime?;
      }
    } catch (e) {
      lastPeriodStart = null;
    }
    
    return UserProfile(
      id: id,
      email: email,
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      dateOfBirth: dateOfBirth,
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      profileImageUrl: json['profile_image_url'] ?? json['profileImageUrl'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      averageCycleLength: json['average_cycle_length'] ?? json['averageCycleLength'],
      averagePeriodLength: json['average_period_length'] ?? json['averagePeriodLength'],
      averageLutealPhase: json['average_luteal_phase'] ?? json['averageLutealPhase'],
      lastPeriodStart: lastPeriodStart,
      notificationsEnabled: json['notifications_enabled'] ?? json['notificationsEnabled'] ?? true,
      partnerSharingEnabled: json['partner_sharing_enabled'] ?? json['partnerSharingEnabled'] ?? false,
      partnerId: json['partner_id'] ?? json['partnerId'],
      dataSharingEnabled: json['data_sharing_enabled'] ?? json['dataSharingEnabled'] ?? false,
      analyticsEnabled: json['analytics_enabled'] ?? json['analyticsEnabled'] ?? true,
      marketingEmailsEnabled: json['marketing_emails_enabled'] ?? json['marketingEmailsEnabled'] ?? false,
      wellnessGoals: List<String>.from(json['wellness_goals'] ?? json['wellnessGoals'] ?? []),
      healthConditions: List<String>.from(json['health_conditions'] ?? json['healthConditions'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      lifestyleTrackingEnabled: json['lifestyle_tracking_enabled'] ?? json['lifestyleTrackingEnabled'] ?? false,
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

