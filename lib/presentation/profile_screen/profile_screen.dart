import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  String? _error;
  String? _originalUsername;
  String? _originalEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _apiService.getUser();
      if (mounted) {
        setState(() {
          _usernameController.text = userData['username'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _originalUsername = userData['username'];
          _originalEmail = userData['email'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final usernameChanged = _usernameController.text.trim() != _originalUsername;
    final emailChanged = _emailController.text.trim() != _originalEmail;
    
    if (!usernameChanged && !emailChanged) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updateData = <String, dynamic>{};
      if (usernameChanged) {
        updateData['username'] = _usernameController.text.trim();
      }
      if (emailChanged) {
        updateData['email'] = _emailController.text.trim();
      }
      
      await _apiService.updateUser(updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All password fields are required'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New passwords do not match'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      await _apiService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isChangingPassword = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('incorrect') 
                ? 'Current password is incorrect' 
                : 'Failed to change password'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isChangingPassword = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
          'Profile',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading || _isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isLoading || _isSaving ? AppTheme.onDarkMuted : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: GoogleFonts.manrope(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile Section
                    Text(
                      'PROFILE INFORMATION',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onDarkMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onDarkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.glassBorder),
                              ),
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppTheme.onDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Email',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onDarkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.glassBorder),
                              ),
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppTheme.onDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Password Section
                    Text(
                      'CHANGE PASSWORD',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onDarkMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Password',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onDarkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.glassBorder),
                              ),
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppTheme.onDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'New Password',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onDarkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.glassBorder),
                              ),
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppTheme.onDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Confirm New Password',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onDarkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.glassBorder),
                              ),
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppTheme.onDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isChangingPassword ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isChangingPassword
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Change Password',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}