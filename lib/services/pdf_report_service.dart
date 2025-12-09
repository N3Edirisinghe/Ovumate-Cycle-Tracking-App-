import 'dart:io' show Platform, File;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart'; // Temporarily disabled due to Windows build issues
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class PdfReportService {
  static const _primaryColor = PdfColor.fromInt(0xFFE91E63);
  static const _accentColor = PdfColor.fromInt(0xFF00BCD4);
  static const _textColor = PdfColor.fromInt(0xFF333333);
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);

  static pw.TextStyle get _h1 => pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: _primaryColor,
      );

  static pw.TextStyle get _h2 => pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: _textColor,
      );

  static pw.TextStyle get _body => pw.TextStyle(
        fontSize: 12,
        color: _textColor,
      );

  static pw.PageTheme _buildPageTheme() {
    return pw.PageTheme(
      margin: const pw.EdgeInsets.fromLTRB(28, 36, 28, 36),
      theme: pw.ThemeData(defaultTextStyle: _body),
    );
  }

  static pw.Widget _wrapWithFrame(pw.Widget content, pw.Context context) {
    final generatedOn =
        DateFormat('MMM dd, yyyy').format(DateTime.now());
    return pw.Stack(
      children: [
        // Header ribbon
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: 18,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  _primaryColor,
                  _accentColor,
                ],
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
          ),
        ),
        // Page content
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 24, bottom: 28),
          child: content,
        ),
        // Footer with page number
        pw.Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated on $generatedOn',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  )),
              pw.Text(
                'Page ${context.pageNumber}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Generate a comprehensive cycle report PDF
  static Future<Uint8List> generateCycleReport({
    required CycleProvider cycleProvider,
    required String userName,
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormatter = DateFormat('MMM dd, yyyy');
    
    // Set date range
    startDate ??= DateTime.now().subtract(const Duration(days: 90));
    endDate ??= DateTime.now();
    
    // Filter entries by date range
    final filteredEntries = cycleProvider.cycleEntries
        .where((entry) => 
            entry.date.isAfter(startDate!) && 
            entry.date.isBefore(endDate!.add(const Duration(days: 1))))
        .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

    // Add cover page
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(),
        build: (pw.Context context) => _buildCoverPage(
          userName: userName,
          reportType: reportType,
          dateRange: '${dateFormatter.format(startDate!)} - ${dateFormatter.format(endDate!)}',
          generatedDate: dateFormatter.format(now),
        ),
      ),
    );

    // Add summary page
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(),
        build: (pw.Context context) => _wrapWithFrame(
          _buildSummaryPage(
          cycleProvider: cycleProvider,
          entries: filteredEntries,
          startDate: startDate!,
          endDate: endDate!,
          ),
          context,
        ),
      ),
    );

    // Add cycle analysis page
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(),
        build: (pw.Context context) => _wrapWithFrame(
          _buildCycleAnalysisPage(
          cycleProvider: cycleProvider,
          entries: filteredEntries,
          ),
          context,
        ),
      ),
    );

    // Add lifestyle analysis page
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(),
        build: (pw.Context context) => _wrapWithFrame(
          _buildLifestyleAnalysisPage(
          entries: filteredEntries,
          ),
          context,
        ),
      ),
    );

    // Add symptom tracking page
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(),
        build: (pw.Context context) => _wrapWithFrame(
          _buildSymptomTrackingPage(
          entries: filteredEntries,
          ),
          context,
        ),
      ),
    );

    // Add monthly calendar views
    if (reportType == 'detailed') {
      final months = _getMonthsInRange(startDate!, endDate!);
      for (final month in months) {
        pdf.addPage(
          pw.Page(
            pageTheme: _buildPageTheme(),
            build: (pw.Context context) => _wrapWithFrame(
              _buildMonthlyCalendarPage(
              month: month,
              entries: filteredEntries,
              ),
              context,
            ),
          ),
        );
      }
    }

    // Add recommendations page
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(),
        build: (pw.Context context) => _wrapWithFrame(
          _buildRecommendationsPage(
          cycleProvider: cycleProvider,
          entries: filteredEntries,
          ),
          context,
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCoverPage({
    required String userName,
    required String reportType,
    required String dateRange,
    required String generatedDate,
  }) {
    return pw.Stack(
      children: [
        // Decorative gradient background
        pw.Positioned.fill(
          child: pw.Container(
          decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [
                  PdfColor.fromInt(0xFFFCE4EC),
                  PdfColor.fromInt(0xFFE0F7FA),
                ],
              ),
            ),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
            pw.SizedBox(height: 36),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(18),
                gradient: pw.LinearGradient(
                  colors: [_primaryColor, _accentColor],
                ),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColors.grey500,
                    blurRadius: 8,
                    offset: const PdfPoint(0, 2),
              ),
            ],
          ),
              child: pw.Column(
                children: [
                  pw.Text('OvuMate', style: pw.TextStyle(
                    fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                  )),
                  pw.SizedBox(height: 6),
                  pw.Text('Cycle Health Report', style: pw.TextStyle(
                    fontSize: 18, color: PdfColors.white,
                  )),
                ],
          ),
        ),
            pw.SizedBox(height: 36),
            pw.Text('Personal Cycle Report for', style: _h2),
            pw.SizedBox(height: 8),
            pw.Text(userName, style: pw.TextStyle(
              fontSize: 30, fontWeight: pw.FontWeight.bold, color: _primaryColor,
            )),
            pw.SizedBox(height: 28),
        pw.Container(
              padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
                  _kvRow('Report Type', reportType.toUpperCase()),
                  pw.SizedBox(height: 8),
                  _kvRow('Date Range', dateRange),
                  pw.SizedBox(height: 8),
                  _kvRow('Generated', generatedDate),
            ],
          ),
        ),
        pw.Spacer(),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16),
              child: pw.Text(
          'This report contains personal health information. Please keep it confidential.',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
          textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _kvRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value),
      ],
    );
  }

  static pw.Widget _bullet(String text) {
    return pw.Bullet(
      text: text,
      style: _body,
      bulletSize: 4,
      bulletShape: pw.BoxShape.circle,
      bulletColor: _primaryColor,
      padding: const pw.EdgeInsets.only(bottom: 2),
    );
  }

  static pw.Widget _buildSummaryPage({
    required CycleProvider cycleProvider,
    required List<CycleEntry> entries,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final periodDays = entries.where((e) => e.isPeriodDay).length;
    final symptomDays = entries.where((e) => e.symptoms.isNotEmpty).length;
    final moodEntries = entries.where((e) => e.mood != null).length;
    final lifestyleEntries = entries.where((e) => 
        e.sleepHours != null || e.waterIntake != null || e.stressLevel != null).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Health Summary'),
        pw.SizedBox(height: 30),
        
        // Key Statistics
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(15),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Key Statistics',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  _buildStatCard('Total Entries', '${entries.length}', _primaryColor),
                  pw.SizedBox(width: 20),
                  _buildStatCard('Period Days', '$periodDays', PdfColors.red),
                  pw.SizedBox(width: 20),
                  _buildStatCard('Symptom Days', '$symptomDays', PdfColors.orange),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                children: [
                  _buildStatCard('Avg Cycle', '${cycleProvider.averageCycleLength ?? 0}d', _accentColor),
                  pw.SizedBox(width: 20),
                  _buildStatCard('Avg Period', '${cycleProvider.averagePeriodLength ?? 0}d', _accentColor),
                  pw.SizedBox(width: 20),
                  _buildStatCard('Cycles Tracked', '${cycleProvider.cyclesTracked}', _accentColor),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // Cycle Health Overview
        _buildSectionHeader('Cycle Health Overview'),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _primaryColor),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            children: [
              _buildOverviewItem('Current Phase', cycleProvider.currentPhase.phaseDisplayName),
              if (cycleProvider.nextPeriodStart != null)
                _buildOverviewItem(
                  'Next Period', 
                  DateFormat('MMM dd, yyyy').format(cycleProvider.nextPeriodStart!)
                ),
              if (cycleProvider.nextOvulationDate != null)
                _buildOverviewItem(
                  'Next Ovulation', 
                  DateFormat('MMM dd, yyyy').format(cycleProvider.nextOvulationDate!)
                ),
              _buildOverviewItem('Cycle Regularity', _getCycleRegularity(cycleProvider)),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // Recent Activity
        _buildSectionHeader('Recent Activity Summary'),
        pw.SizedBox(height: 15),
        _bullet('$periodDays period days recorded'),
        _bullet('$symptomDays days with symptoms logged'),
        _bullet('$moodEntries mood entries recorded'),
        _bullet('$lifestyleEntries lifestyle entries completed'),
        _bullet('${entries.length} total health entries tracked'),
      ],
    );
  }

  static pw.Widget _buildCycleAnalysisPage({
    required CycleProvider cycleProvider,
    required List<CycleEntry> entries,
  }) {
    final periodEntries = entries.where((e) => e.isPeriodDay).toList();
    final cycleLengths = _calculateCycleLengths(periodEntries);
    final periodLengths = _calculatePeriodLengths(periodEntries);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Cycle Analysis'),
        pw.SizedBox(height: 30),
        
        // Cycle Patterns
        _buildSectionHeader('Cycle Patterns'),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            children: [
              if (cycleLengths.isNotEmpty) ...[
                _buildAnalysisItem('Average Cycle Length', '${_average(cycleLengths.map((e) => e.toDouble()).toList()).toStringAsFixed(1)} days'),
                _buildAnalysisItem('Shortest Cycle', '${cycleLengths.reduce((a, b) => a < b ? a : b)} days'),
                _buildAnalysisItem('Longest Cycle', '${cycleLengths.reduce((a, b) => a > b ? a : b)} days'),
                _buildAnalysisItem('Cycle Variation', '${_standardDeviation(cycleLengths.map((e) => e.toDouble()).toList()).toStringAsFixed(1)} days'),
              ],
              if (periodLengths.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                _buildAnalysisItem('Average Period Length', '${_average(periodLengths.map((e) => e.toDouble()).toList()).toStringAsFixed(1)} days'),
                _buildAnalysisItem('Shortest Period', '${periodLengths.reduce((a, b) => a < b ? a : b)} days'),
                _buildAnalysisItem('Longest Period', '${periodLengths.reduce((a, b) => a > b ? a : b)} days'),
              ],
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // Flow Analysis
        _buildSectionHeader('Flow Analysis'),
        pw.SizedBox(height: 15),
        _buildFlowAnalysis(periodEntries),
        
        pw.SizedBox(height: 30),
        
        // Predictive Insights
        _buildSectionHeader('Predictive Insights'),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _accentColor),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• Based on your tracking data, your cycles are ${_getCycleRegularity(cycleProvider)}'),
              pw.Text('• Your fertility window typically occurs around day ${_getTypicalOvulationDay(cycleLengths)}'),
              pw.Text('• Period symptoms are most commonly experienced ${_getMostCommonSymptomDays(entries)}'),
              pw.Text('• Your tracking consistency: ${_getTrackingConsistency(entries)}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLifestyleAnalysisPage({
    required List<CycleEntry> entries,
  }) {
    final sleepEntries = entries.where((e) => e.sleepHours != null).toList();
    final waterEntries = entries.where((e) => e.waterIntake != null).toList();
    final stressEntries = entries.where((e) => e.stressLevel != null).toList();
    final moodEntries = entries.where((e) => e.mood != null).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Lifestyle Analysis'),
        pw.SizedBox(height: 30),
        
        // Sleep Analysis
        if (sleepEntries.isNotEmpty) ...[
          _buildSectionHeader('Sleep Analysis'),
          pw.SizedBox(height: 15),
          _buildLifestyleMetricAnalysis(
            'Sleep Hours',
            sleepEntries.map((e) => e.sleepHours!.toDouble()).toList(),
            'hours',
          ),
          pw.SizedBox(height: 20),
        ],
        
        // Water Intake Analysis
        if (waterEntries.isNotEmpty) ...[
          _buildSectionHeader('Water Intake Analysis'),
          pw.SizedBox(height: 15),
          _buildLifestyleMetricAnalysis(
            'Daily Water',
            waterEntries.map((e) => e.waterIntake!.toDouble()).toList(),
            'ml',
          ),
          pw.SizedBox(height: 20),
        ],
        
        // Stress Level Analysis
        if (stressEntries.isNotEmpty) ...[
          _buildSectionHeader('Stress Level Analysis'),
          pw.SizedBox(height: 15),
          _buildLifestyleMetricAnalysis(
            'Stress Level',
            stressEntries.map((e) => e.stressLevel!.toDouble()).toList(),
            '/10',
          ),
          pw.SizedBox(height: 20),
        ],
        
        // Mood Patterns
        if (moodEntries.isNotEmpty) ...[
          _buildSectionHeader('Mood Patterns'),
          pw.SizedBox(height: 15),
          _buildMoodAnalysis(moodEntries),
        ],
      ],
    );
  }

  static pw.Widget _buildSymptomTrackingPage({
    required List<CycleEntry> entries,
  }) {
    final symptomEntries = entries.where((e) => e.symptoms.isNotEmpty).toList();
    final allSymptoms = <String, int>{};
    
    for (final entry in symptomEntries) {
      for (final symptom in entry.symptoms) {
        allSymptoms[symptom] = (allSymptoms[symptom] ?? 0) + 1;
      }
    }

    final sortedSymptoms = allSymptoms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Symptom Tracking'),
        pw.SizedBox(height: 30),
        
        // Symptom Frequency
        _buildSectionHeader('Symptom Frequency'),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Most Common Symptoms',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.SizedBox(height: 10),
              ...sortedSymptoms.take(10).map((symptom) =>
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(symptom.key),
                      pw.Text('${symptom.value} times (${((symptom.value / symptomEntries.length) * 100).toStringAsFixed(1)}%)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // Symptom Insights
        _buildSectionHeader('Symptom Insights'),
        pw.SizedBox(height: 15),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('• Total symptom days: ${symptomEntries.length}'),
            pw.Text('• Symptom-free days: ${entries.length - symptomEntries.length}'),
            if (sortedSymptoms.isNotEmpty)
              pw.Text('• Most frequent symptom: ${sortedSymptoms.first.key}'),
            pw.Text('• Average symptoms per entry: ${(allSymptoms.values.reduce((a, b) => a + b) / symptomEntries.length).toStringAsFixed(1)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMonthlyCalendarPage({
    required DateTime month,
    required List<CycleEntry> entries,
  }) {
    final monthEntries = entries.where((entry) =>
        entry.date.year == month.year && entry.date.month == month.month).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Calendar - ${DateFormat('MMMM yyyy').format(month)}'),
        pw.SizedBox(height: 30),
        
        // Monthly stats
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Monthly Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total entries: ${monthEntries.length}'),
              pw.Text('Period days: ${monthEntries.where((e) => e.isPeriodDay).length}'),
              pw.Text('Symptom days: ${monthEntries.where((e) => e.symptoms.isNotEmpty).length}'),
              pw.Text('Mood entries: ${monthEntries.where((e) => e.mood != null).length}'),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Entry list
        _buildSectionHeader('Daily Entries'),
        pw.SizedBox(height: 15),
        if (monthEntries.isEmpty)
          pw.Text('No entries recorded for this month')
        else
          ...monthEntries.map((entry) => _buildEntryItem(entry)),
      ],
    );
  }

  static pw.Widget _buildRecommendationsPage({
    required CycleProvider cycleProvider,
    required List<CycleEntry> entries,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeader('Health Recommendations'),
        pw.SizedBox(height: 30),
        
        // General Health Tips
        _buildSectionHeader('General Health Tips'),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('🌱 Maintain regular sleep schedule (7-9 hours per night)'),
              pw.SizedBox(height: 8),
              pw.Text('💧 Stay hydrated (aim for 8-10 glasses of water daily)'),
              pw.SizedBox(height: 8),
              pw.Text('🏃‍♀️ Engage in regular physical activity'),
              pw.SizedBox(height: 8),
              pw.Text('🥗 Maintain a balanced diet rich in nutrients'),
              pw.SizedBox(height: 8),
              pw.Text('😌 Practice stress management techniques'),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // Personalized Recommendations
        _buildSectionHeader('Personalized Recommendations'),
        pw.SizedBox(height: 15),
        ..._generatePersonalizedRecommendations(cycleProvider, entries),
        
        pw.SizedBox(height: 30),
        
        // When to Consult Healthcare
        _buildSectionHeader('When to Consult Your Healthcare Provider'),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.red),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('⚠️ Irregular cycles (consistently shorter than 21 days or longer than 35 days)'),
              pw.SizedBox(height: 5),
              pw.Text('⚠️ Severe pain that interferes with daily activities'),
              pw.SizedBox(height: 5),
              pw.Text('⚠️ Heavy bleeding (changing pad/tampon every hour)'),
              pw.SizedBox(height: 5),
              pw.Text('⚠️ Missing periods for 3+ months'),
              pw.SizedBox(height: 5),
              pw.Text('⚠️ Unusual symptoms or significant changes in patterns'),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  static pw.Widget _buildPageHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 15),
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: _primaryColor,
      ),
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0x1AFFFFFF),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                color: _textColor,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildOverviewItem(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildAnalysisItem(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFlowAnalysis(List<CycleEntry> periodEntries) {
    final flowCounts = <int, int>{};
    // Note: flowIntensity field may need to be added to CycleEntry model
    // For now, we'll use a placeholder analysis
    flowCounts[1] = 1;
    flowCounts[2] = 2;
    flowCounts[3] = 3;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Flow Intensity Distribution',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          ...flowCounts.entries.map((entry) =>
            pw.Text('Flow ${entry.key}: ${entry.value} days (${((entry.value / periodEntries.length) * 100).toStringAsFixed(1)}%)')
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLifestyleMetricAnalysis(String title, List<double> values, String unit) {
    if (values.isEmpty) return pw.Container();

    final avg = _average(values);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          _buildAnalysisItem('Average $title', '${avg.toStringAsFixed(1)}$unit'),
          _buildAnalysisItem('Minimum $title', '${min.toStringAsFixed(1)}$unit'),
          _buildAnalysisItem('Maximum $title', '${max.toStringAsFixed(1)}$unit'),
          _buildAnalysisItem('Total Entries', '${values.length}'),
        ],
      ),
    );
  }

  static pw.Widget _buildMoodAnalysis(List<CycleEntry> moodEntries) {
    final moodCounts = <String, int>{};
    for (final entry in moodEntries) {
      if (entry.mood != null) {
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
      }
    }

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mood Distribution',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          ...sortedMoods.take(5).map((mood) =>
            pw.Text('${mood.key}: ${mood.value} times (${((mood.value / moodEntries.length) * 100).toStringAsFixed(1)}%)')
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEntryItem(CycleEntry entry) {
    final dateStr = DateFormat('MMM dd').format(entry.date);
    final details = <String>[];
    
    if (entry.isPeriodDay) details.add('Period');
    if (entry.mood != null) details.add('Mood: ${entry.mood}');
    if (entry.symptoms.isNotEmpty) details.add('Symptoms: ${entry.symptoms.take(3).join(', ')}');
    if (entry.sleepHours != null) details.add('Sleep: ${entry.sleepHours}h');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            dateStr,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (details.isNotEmpty)
            pw.Text(details.join(' • ')),
        ],
      ),
    );
  }

  static List<pw.Widget> _generatePersonalizedRecommendations(
    CycleProvider cycleProvider,
    List<CycleEntry> entries,
  ) {
    final recommendations = <pw.Widget>[];
    
    // Sleep recommendations
    final sleepEntries = entries.where((e) => e.sleepHours != null).toList();
    if (sleepEntries.isNotEmpty) {
      final avgSleep = _average(sleepEntries.map((e) => e.sleepHours!.toDouble()).toList());
      if (avgSleep < 7) {
        recommendations.add(
          pw.Text('🛌 Consider increasing your sleep to 7-9 hours per night (current average: ${avgSleep.toStringAsFixed(1)}h)'),
        );
        recommendations.add(pw.SizedBox(height: 8));
      }
    }

    // Water recommendations
    final waterEntries = entries.where((e) => e.waterIntake != null).toList();
    if (waterEntries.isNotEmpty) {
      final avgWater = _average(waterEntries.map((e) => e.waterIntake!.toDouble()).toList());
      if (avgWater < 2000) {
        recommendations.add(
          pw.Text('💧 Consider increasing your daily water intake (current average: ${avgWater.toStringAsFixed(0)}ml)'),
        );
        recommendations.add(pw.SizedBox(height: 8));
      }
    }

    // Stress recommendations
    final stressEntries = entries.where((e) => e.stressLevel != null).toList();
    if (stressEntries.isNotEmpty) {
      final avgStress = _average(stressEntries.map((e) => e.stressLevel!.toDouble()).toList());
      if (avgStress > 6) {
        recommendations.add(
          pw.Text('😌 Consider stress management techniques (current average: ${avgStress.toStringAsFixed(1)}/10)'),
        );
        recommendations.add(pw.SizedBox(height: 8));
      }
    }

    return recommendations;
  }

  // Utility functions
  static List<int> _calculateCycleLengths(List<CycleEntry> periodEntries) {
    if (periodEntries.length < 2) return [];
    
    periodEntries.sort((a, b) => a.date.compareTo(b.date));
    final lengths = <int>[];
    
    for (int i = 1; i < periodEntries.length; i++) {
      final length = periodEntries[i].date.difference(periodEntries[i - 1].date).inDays;
      if (length > 0 && length < 100) { // Filter out invalid cycles
        lengths.add(length);
      }
    }
    
    return lengths;
  }

  static List<int> _calculatePeriodLengths(List<CycleEntry> periodEntries) {
    // This is a simplified calculation - in reality, you'd need consecutive period days
    return [5]; // Placeholder
  }

  static double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _standardDeviation(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = _average(values);
    final squaredDiffs = values.map((x) => (x - mean) * (x - mean)).toList();
    return math.sqrt(_average(squaredDiffs));
  }

  static String _getCycleRegularity(CycleProvider cycleProvider) {
    // Simplified implementation
    return 'regular'; // You can implement actual regularity calculation
  }

  static int _getTypicalOvulationDay(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return 14;
    final avgCycle = _average(cycleLengths.map((e) => e.toDouble()).toList());
    return (avgCycle - 14).round();
  }

  static String _getMostCommonSymptomDays(List<CycleEntry> entries) {
    return 'during the first 2-3 days of menstruation';
  }

  static String _getTrackingConsistency(List<CycleEntry> entries) {
    final totalDays = DateTime.now().difference(
      entries.isNotEmpty ? entries.last.date : DateTime.now()
    ).inDays;
    final consistency = (entries.length / totalDays * 100).clamp(0, 100);
    return '${consistency.toStringAsFixed(0)}%';
  }

  static List<DateTime> _getMonthsInRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var current = DateTime(start.year, start.month);
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }
    
    return months;
  }

  /// Save PDF to device and share
  static Future<String> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      // For web, trigger browser download
      return _savePdfForWeb(pdfBytes, fileName);
    } else {
      // For mobile/desktop, use file system
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    }
  }

  /// Save PDF for web platform using browser download
  static Future<String> _savePdfForWeb(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      // Use share_plus XFile for web download
      // This will trigger browser download on web
      final xfile = XFile.fromData(
        pdfBytes,
        name: fileName,
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([xfile], subject: fileName);
      return 'Downloaded: $fileName';
    }
    throw UnsupportedError('Web download only works on web platform');
  }

  /// Save PDF to a temporary, shareable location and return its path
  static Future<String> savePdfToTemporary(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      // For web, trigger browser download
      return _savePdfForWeb(pdfBytes, fileName);
    } else {
      // For mobile/desktop, use temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final file = File(tempPath);
      await file.writeAsBytes(pdfBytes);
      return tempPath;
    }
  }

  /// Save PDF to an Android-friendly external location for sharing, fallback to temp elsewhere
  static Future<String> savePdfForSharing(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      // For web, trigger browser download
      return _savePdfForWeb(pdfBytes, fileName);
    }
    
    try {
      if (Platform.isAndroid) {
        // Prefer Downloads if available
        final downloadsDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        final targetDir = (downloadsDirs != null && downloadsDirs.isNotEmpty)
            ? downloadsDirs.first
            : await getExternalStorageDirectory();
        if (targetDir != null) {
          final path = '${targetDir.path}/$fileName';
          final file = File(path);
          await file.writeAsBytes(pdfBytes);
          return path;
        }
      }
    } catch (_) {
      // ignore and fallback
    }
    // Fallback
    return savePdfToTemporary(pdfBytes, fileName);
  }

  // Temporarily disabled due to Windows build issues with printing package
  /*
  /// Share PDF using the printing package
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  /// Print PDF using the printing package
  static Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
  */
}
