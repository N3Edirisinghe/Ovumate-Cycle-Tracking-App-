import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:ovumate/utils/whatsapp_share.dart';
import 'package:ovumate/services/pdf_report_service.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';

class PartnerShareScreen extends StatefulWidget {
  const PartnerShareScreen({super.key});

  @override
  State<PartnerShareScreen> createState() => _PartnerShareScreenState();
}

class _PartnerShareScreenState extends State<PartnerShareScreen> {
  bool _isPartnerConnected = false;
  bool _shareNextPeriod = true;
  bool _shareOvulation = true;
  bool _shareMood = false;
  bool _shareSymptoms = false;
  bool _shareLifestyle = true;
  bool _isGeneratingPdf = false;
  
  final _partnerEmailController = TextEditingController();
  final _partnerCodeController = TextEditingController();

  @override
  void dispose() {
    _partnerEmailController.dispose();
    _partnerCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
      appBar: _buildProfessionalAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional Header Section
            _buildProfessionalHeader(),
            
            const SizedBox(height: 24),
            
            if (_isPartnerConnected) ...[
              // Connected Partner Info
              _buildConnectedPartnerInfo(),
              
              const SizedBox(height: 24),
              
              // Shared Data Preview
              _buildSharedDataPreview(),
              
              const SizedBox(height: 24),
            ],
            
            // PDF Report Section
            _buildPdfReportSection(),
            
            const SizedBox(height: 24),
            
            // Privacy Settings
            _buildPrivacySettings(),
            
            const SizedBox(height: 24),
            
            // Benefits Section
            _buildBenefitsSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPink,
              AppTheme.primaryPink.withOpacity(0.8),
              AppTheme.accentTeal.withOpacity(0.6),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.share,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'partner_share.title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildProfessionalHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [
            AppTheme.surfaceDark,
            AppTheme.primaryPink.withOpacity(0.1),
            AppTheme.accentTeal.withOpacity(0.1),
          ] : [
            Colors.white,
            AppTheme.primaryPink.withOpacity(0.05),
            AppTheme.accentTeal.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryPink,
                      AppTheme.primaryPink.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'partner_share.share_via_whatsapp'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryPink,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'partner_share.share_description'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvitePartnerSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.send,
                  color: AppTheme.primaryPink,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invite Your Partner',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Send an invitation to your partner so they can stay informed about your cycle.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _partnerEmailController,
              decoration: InputDecoration(
                labelText: 'Partner\'s Email',
                hintText: 'partner@example.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _sendPartnerInvite();
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Invitation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinWithCodeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: AppTheme.secondaryPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Join with Code',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Already have an invitation code? Enter it here to connect.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _partnerCodeController,
              decoration: InputDecoration(
                labelText: 'Invitation Code',
                hintText: 'Enter 6-digit code',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _joinWithCode();
                },
                icon: const Icon(Icons.link),
                label: const Text('Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedPartnerInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryPink,
                      AppTheme.accentTeal,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'john.doe@example.com',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: AppTheme.primaryPink, size: 20),
                          const SizedBox(width: 12),
                          Text('partner_share.settings'.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          const Icon(Icons.link_off, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text('partner_share.disconnect'.tr(), style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'disconnect') {
                      _disconnectPartner();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successGreen.withOpacity(0.1),
                  AppTheme.successGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'partner_share.partner_active'.tr(),
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedDataPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentTeal.withOpacity(0.2),
                      AppTheme.primaryPink.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.visibility,
                  color: AppTheme.accentTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'partner_share.what_partner_sees'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentTeal,
                      AppTheme.accentTeal.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentTeal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _shareToWhatsApp(),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.share, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'partner_share.share'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
            Consumer<CycleProvider>(
              builder: (context, cycleProvider, child) {
                return Column(
                  children: [
                    if (_shareNextPeriod && cycleProvider.nextPeriodStart != null)
                      _buildSharedDataItem(
                        Icons.calendar_today,
                        'Next Period',
                        DateFormat('MMM d').format(cycleProvider.nextPeriodStart!),
                        AppTheme.primaryPink,
                      ),
                    if (_shareOvulation && cycleProvider.nextOvulationDate != null)
                      _buildSharedDataItem(
                        Icons.favorite,
                        'Ovulation',
                        DateFormat('MMM d').format(cycleProvider.nextOvulationDate!),
                        AppTheme.warningOrange,
                      ),
                    if (_shareLifestyle)
                      _buildSharedDataItem(
                        Icons.favorite_rounded,
                        'Daily Wellness',
                        'Sleep, Water, Mood',
                        AppTheme.accentTeal,
                      ),
                    if (_shareMood)
                      _buildSharedDataItem(
                        Icons.sentiment_satisfied,
                        'Current Mood',
                        'Happy & Energetic',
                        AppTheme.successGreen,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
    );
  }

  Widget _buildSharedDataItem(IconData icon, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPink.withOpacity(0.2),
                      AppTheme.primaryPink.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.privacy_tip,
                  color: AppTheme.primaryPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'partner_share.privacy_settings'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 8),
            Text(
              'partner_share.privacy_description'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            _buildPrivacyToggle(
              'partner_share.next_period_predictions'.tr(),
              'partner_share.next_period_desc'.tr(),
              _shareNextPeriod,
              (value) => setState(() => _shareNextPeriod = value),
            ),
            _buildPrivacyToggle(
              'partner_share.ovulation_tracking'.tr(),
              'partner_share.ovulation_desc'.tr(),
              _shareOvulation,
              (value) => setState(() => _shareOvulation = value),
            ),
            _buildPrivacyToggle(
              'partner_share.lifestyle_data'.tr(),
              'partner_share.lifestyle_desc'.tr(),
              _shareLifestyle,
              (value) => setState(() => _shareLifestyle = value),
            ),
            _buildPrivacyToggle(
              'partner_share.mood_tracking'.tr(),
              'partner_share.mood_desc'.tr(),
              _shareMood,
              (value) => setState(() => _shareMood = value),
            ),
            _buildPrivacyToggle(
              'partner_share.symptoms'.tr(),
              'partner_share.symptoms_desc'.tr(),
              _shareSymptoms,
              (value) => setState(() => _shareSymptoms = value),
            ),
          ],
        ),
    );
  }

  Widget _buildPrivacyToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryPink,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfReportSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPink.withOpacity(0.2),
                      AppTheme.accentTeal.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: AppTheme.primaryPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'partner_share.comprehensive_health_report'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 8),
            Text(
              'partner_share.report_description'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            
            // Report options
            _buildReportOption(
              'partner_share.quick_summary'.tr(),
              'partner_share.quick_summary_desc'.tr(),
              'summary',
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              'partner_share.detailed_report'.tr(),
              'partner_share.detailed_report_desc'.tr(),
              'detailed',
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              'partner_share.healthcare_report'.tr(),
              'partner_share.healthcare_report_desc'.tr(),
              'healthcare',
            ),
            
            const SizedBox(height: 20),
            
            // Report features
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.backgroundDark : AppTheme.accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentTeal.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'partner_share.report_includes'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                  const SizedBox(height: 8),
                  _buildFeatureItem('📊 ${'partner_share.cycle_statistics'.tr()}'),
                  _buildFeatureItem('📅 ${'partner_share.monthly_calendars'.tr()}'),
                  _buildFeatureItem('💊 ${'partner_share.symptom_tracking'.tr()}'),
                  _buildFeatureItem('💪 ${'partner_share.lifestyle_insights'.tr()}'),
                  _buildFeatureItem('🎯 ${'partner_share.recommendations'.tr()}'),
                  _buildFeatureItem('⚕️ ${'partner_share.health_indicators'.tr()}'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
    );
  }

  Widget _buildReportOption(String title, String description, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [
            AppTheme.backgroundDark,
            AppTheme.surfaceDark,
          ] : [
            AppTheme.primaryPink.withOpacity(0.05),
            AppTheme.accentTeal.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isGeneratingPdf ? null : () => _generatePdfReport(type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPink,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _isGeneratingPdf
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryPink,
                              AppTheme.primaryPink.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        feature,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentTeal.withOpacity(0.2),
                      AppTheme.primaryPink.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star,
                  color: AppTheme.accentTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'partner_share.benefits_title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.favorite,
              'partner_share.better_support'.tr(),
              'partner_share.better_support_desc'.tr(),
            ),
            _buildBenefitItem(
              Icons.calendar_today,
              'partner_share.period_preparation'.tr(),
              'partner_share.period_preparation_desc'.tr(),
            ),
            _buildBenefitItem(
              Icons.shopping_cart,
              'partner_share.practical_help'.tr(),
              'partner_share.practical_help_desc'.tr(),
            ),
            _buildBenefitItem(
              Icons.health_and_safety,
              'partner_share.health_awareness'.tr(),
              'partner_share.health_awareness_desc'.tr(),
            ),
          ],
        ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [
            AppTheme.backgroundDark,
            AppTheme.surfaceDark,
          ] : [
            AppTheme.primaryPink.withOpacity(0.05),
            AppTheme.accentTeal.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPink,
                  AppTheme.primaryPink.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPink.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendPartnerInvite() {
    if (_partnerEmailController.text.isEmpty) {
      _showMessage('Please enter your partner\'s email address');
      return;
    }

    // TODO: Implement actual invite logic
    _showMessage('Invitation sent successfully!');
    _partnerEmailController.clear();
  }

  void _joinWithCode() {
    if (_partnerCodeController.text.length != 6) {
      _showMessage('Please enter a valid 6-digit code');
      return;
    }

    // TODO: Implement actual join logic
    setState(() {
      _isPartnerConnected = true;
    });
    _showMessage('Successfully connected to partner!');
    _partnerCodeController.clear();
  }

  void _disconnectPartner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('partner_share.disconnect_title'.tr()),
        content: Text('partner_share.disconnect_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isPartnerConnected = false;
              });
              Navigator.pop(context);
              _showMessage('Partner disconnected successfully');
            },
            child: Text('partner_share.disconnect'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryPink,
      ),
    );
  }

  void _shareToWhatsApp() async {
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    
    if (cycleProvider.nextPeriodStart != null) {
      final success = await WhatsAppShare.shareCycleSummary(
        nextPeriodDate: cycleProvider.nextPeriodStart!,
        nextOvulationDate: cycleProvider.nextOvulationDate,
        cycleLength: cycleProvider.averageCycleLength ?? 28,
        periodLength: cycleProvider.averagePeriodLength ?? 5,
      );
      
      if (!success && mounted) {
        _showMessage('Could not open WhatsApp. Please make sure WhatsApp is installed.');
      } else if (mounted) {
        _showMessage('Opening WhatsApp to share cycle data...');
      }
    } else {
      _showMessage('No cycle data available to share yet.');
    }
  }

  Future<void> _generatePdfReport(String reportType) async {
    if (_isGeneratingPdf) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get user name
      final userName = authProvider.currentUser?.fullName ?? 'User';
      
      // Set date range based on report type
      DateTime? startDate;
      DateTime? endDate = DateTime.now();
      
      switch (reportType) {
        case 'summary':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'detailed':
          startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        case 'healthcare':
          startDate = DateTime.now().subtract(const Duration(days: 180));
          break;
      }

      _showMessage('partner_share.generating_pdf'.tr());

      // Generate PDF
      final pdfBytes = await PdfReportService.generateCycleReport(
        cycleProvider: cycleProvider,
        userName: userName,
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );

      // Create filename
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'OvuMate_${reportType}_Report_$dateStr.pdf';

      // Show options dialog
      _showPdfOptionsDialog(pdfBytes, fileName);

    } catch (e) {
      _showMessage('partner_share.failed_to_generate'.tr() + ': ${e.toString()}');
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  void _showPdfOptionsDialog(Uint8List pdfBytes, String fileName) {
    // Use a bottom sheet for a consistent share UI across platforms
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Text('partner_share.share_to_whatsapp'.tr()),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final xfile = XFile.fromData(
                        pdfBytes,
                        name: fileName,
                        mimeType: 'application/pdf',
                      );
                      await Share.shareXFiles([xfile]);
                      _showMessage('partner_share.opening_share'.tr());
                    } catch (e) {
                      _showMessage('partner_share.failed_to_share'.tr() + ': ${e.toString()}');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: Text('partner_share.share'.tr()),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final xfile = XFile.fromData(
                        pdfBytes,
                        name: fileName,
                        mimeType: 'application/pdf',
                      );
                      await Share.shareXFiles([xfile]);
                      _showMessage('partner_share.opening_share'.tr());
                    } catch (e) {
                      _showMessage('partner_share.failed_to_share'.tr() + ': ${e.toString()}');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: Text('partner_share.save'.tr()),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                final filePath = await PdfReportService.savePdfToDevice(pdfBytes, fileName);
                _showMessage('partner_share.pdf_saved'.tr() + '\nLocation: $filePath');
              } catch (e) {
                _showMessage('partner_share.failed_to_save'.tr() + ': ${e.toString()}');
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
  }
}
