import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 40,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CampusFieldTrack',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'V1.0.0',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.onDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              'A real-time GPS tracking application for field sessions with intelligent stop detection and comprehensive analytics. Track your movements, analyze your routes, and export your data in multiple formats.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.onDark,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Developed by Prem For Centurion University of Technology and Management, Vizianagaram, Andhra Pradesh',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppTheme.onDarkMuted.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}