import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _users = [];
  Set<String> _selectedUsers = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getAllUsers();
      if (response['success'] == true) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete $username?', style: GoogleFonts.manrope()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text('Delete', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteUser(username);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted successfully', style: GoogleFonts.manrope())),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _deleteMultipleUsers() async {
    if (_selectedUsers.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Users', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${_selectedUsers.length} users?', style: GoogleFonts.manrope()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text('Delete', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteMultipleUsers(_selectedUsers.toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Users deleted successfully', style: GoogleFonts.manrope())),
        );
        setState(() => _selectedUsers.clear());
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'User Management',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.onDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedUsers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
              onPressed: _deleteMultipleUsers,
              tooltip: 'Delete Selected (${_selectedUsers.length})',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.onDark),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: GoogleFonts.manrope(color: AppTheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: Text('Retry', style: GoogleFonts.manrope()),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Text('No users found', style: GoogleFonts.manrope(fontSize: 16, color: AppTheme.onDarkMuted)),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(AppTheme.surface),
                          columns: [
                            DataColumn(label: Checkbox(
                              value: _selectedUsers.length == _users.where((u) => u['role'] != 'ADMIN').length,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUsers = _users.where((u) => u['role'] != 'ADMIN').map((u) => u['username'].toString()).toSet();
                                  } else {
                                    _selectedUsers.clear();
                                  }
                                });
                              },
                            )),
                            DataColumn(label: Text('Emp ID', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Username', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Email', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Employment Type', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Designation', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Project', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Role', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Actions', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
                          ],
                          rows: _users.map((user) {
                            final username = user['username'].toString();
                            final isAdmin = user['role'] == 'ADMIN';
                            return DataRow(
                              selected: _selectedUsers.contains(username),
                              cells: [
                                DataCell(
                                  isAdmin
                                      ? const SizedBox.shrink()
                                      : Checkbox(
                                          value: _selectedUsers.contains(username),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedUsers.add(username);
                                              } else {
                                                _selectedUsers.remove(username);
                                              }
                                            });
                                          },
                                        ),
                                ),
                                DataCell(Text(user['empId']?.toString() ?? '-', style: GoogleFonts.manrope())),
                                DataCell(Text(username, style: GoogleFonts.manrope(fontWeight: FontWeight.w600))),
                                DataCell(Text(user['email']?.toString() ?? '-', style: GoogleFonts.manrope())),
                                DataCell(Text(user['employmentType']?.toString() ?? '-', style: GoogleFonts.manrope())),
                                DataCell(Text(user['designation']?.toString() ?? '-', style: GoogleFonts.manrope())),
                                DataCell(Text(user['projectAssigned']?.toString() ?? '-', style: GoogleFonts.manrope())),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? AppTheme.primary.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user['role']?.toString() ?? 'USER',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isAdmin ? AppTheme.primary : AppTheme.success,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  isAdmin
                                      ? Text('Protected', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.onDarkMuted))
                                      : IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                          onPressed: () => _deleteUser(username),
                                        ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
    );
  }
}
