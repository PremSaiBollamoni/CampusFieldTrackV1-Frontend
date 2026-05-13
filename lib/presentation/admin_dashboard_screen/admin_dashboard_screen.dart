import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'add_users_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final MapController _mapController = MapController();
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _allSessions = [];
  String? _selectedUserId;
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getAdminStats();
      final users = await _apiService.getAdminUsers();
      final sessions = await _apiService.getAllSessions();
      
      print('📊 Loaded ${sessions.length} sessions');
      for (var session in sessions) {
        print('Session ${session['id']}: userId=${session['userId']}');
      }
      
      setState(() {
        _stats = stats;
        _users = users;
        _allSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.onDarkMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: AppTheme.onDarkMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e', style: GoogleFonts.manrope()),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _onUserSelected(String? userId) {
    print('🎯 User selected: $userId');
    setState(() {
      _selectedUserId = userId;
      _selectedSessionId = null; // Reset session selection when user changes
    });
    print('📍 Filtering ${_allSessions.length} sessions for userId: $userId');
  }

  void _onSessionSelected(String? sessionId) {
    print('📍 Session selected: $sessionId');
    setState(() {
      _selectedSessionId = sessionId;
    });
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Export Data',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExportOption(
              icon: Icons.people_rounded,
              title: 'Export All Users',
              subtitle: 'Download complete data for all users',
              onTap: () {
                Navigator.pop(context);
                _exportAllUsers();
              },
            ),
            if (_selectedUserId != null) ...[
              const SizedBox(height: 12),
              _ExportOption(
                icon: Icons.person_rounded,
                title: 'Export Selected User',
                subtitle: 'Download data for selected user only',
                onTap: () {
                  Navigator.pop(context);
                  _exportUser(_selectedUserId!);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportAllUsers() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              const SizedBox(width: 16),
              Text('Generating export...', style: GoogleFonts.manrope()),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final data = await _apiService.downloadExportAllUsers();
      
      // Save to Downloads folder
      final fileName = 'CampusFieldTrack_AllUsers_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = await _saveFile(data, fileName);
      
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Saved to Downloads/$fileName',
                    style: GoogleFonts.manrope(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e', style: GoogleFonts.manrope()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _exportUser(String userId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              const SizedBox(width: 16),
              Text('Generating export...', style: GoogleFonts.manrope()),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final data = await _apiService.downloadExportUser(userId);
      
      // Save to Downloads folder
      final fileName = 'CampusFieldTrack_User_${userId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = await _saveFile(data, fileName);
      
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Saved to Downloads/$fileName',
                    style: GoogleFonts.manrope(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e', style: GoogleFonts.manrope()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<String?> _saveFile(List<int> bytes, String fileName) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access Downloads folder');
      }

      // Save file
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      print('✅ File saved: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ Error saving file: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Container(
              color: AppTheme.background,
              child: const Center(child: CircularProgressIndicator()),
            )
          : Stack(
              children: [
                // Layer 1: Full-screen map background
                Positioned.fill(
                  child: _buildFullScreenMap(),
                ),
                
                // Layer 2: Floating header + KPI cards
                SafeArea(
                  child: Column(
                    children: [
                      _buildFloatingHeader(),
                      const SizedBox(height: 16),
                      _buildFloatingKPICards(),
                    ],
                  ),
                ),
                
                // Layer 3: Draggable bottom sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.35,
                  maxChildSize: 0.8,
                  builder: (context, scrollController) {
                    return _buildBottomSheet(scrollController);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildFullScreenMap() {
    // Filter sessions by user
    var sessions = _selectedUserId != null
        ? _allSessions.where((s) {
            final userId = s['userId'];
            return userId != null && userId.toString() == _selectedUserId;
          }).toList()
        : _allSessions;

    // Further filter by specific session if selected
    if (_selectedSessionId != null) {
      sessions = sessions.where((s) => s['id'] == _selectedSessionId).toList();
    }

    final allPoints = <LatLng>[];
    for (final session in sessions) {
      final routePoints = session['routePoints'] as List<dynamic>?;
      if (routePoints != null) {
        for (final point in routePoints) {
          allPoints.add(LatLng(point['lat'], point['lng']));
        }
      }
    }

    final center = allPoints.isNotEmpty
        ? LatLng(
            allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length,
            allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length,
          )
        : const LatLng(20.5937, 78.9629);

    // Fit map to bounds when user/session is selected
    if ((_selectedUserId != null || _selectedSessionId != null) && allPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final bounds = LatLngBounds.fromPoints(allPoints);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        } catch (e) {
          print('Error fitting bounds: $e');
        }
      });
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        // Draw routes
        ...sessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final routePoints = session['routePoints'] as List<dynamic>?;
          if (routePoints == null || routePoints.length < 2) return const SizedBox();
          
          final points = routePoints.map((p) => LatLng(p['lat'], p['lng'])).toList();
          final isSessionSelected = _selectedSessionId != null && session['id'] == _selectedSessionId;
          final isUserSelected = _selectedUserId != null;
          final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.success, AppTheme.warning];
          final color = isSessionSelected ? AppTheme.primary : 
                        isUserSelected ? colors[index % colors.length] : 
                        colors[index % colors.length];
          
          return PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: color,
                strokeWidth: isSessionSelected ? 6 : (isUserSelected ? 4 : 3),
              ),
            ],
          );
        }).toList(),
        // Start markers
        if (sessions.isNotEmpty)
          MarkerLayer(
            markers: sessions.where((s) {
              final routePoints = s['routePoints'] as List<dynamic>?;
              return routePoints != null && routePoints.isNotEmpty;
            }).map((session) {
              final routePoints = session['routePoints'] as List<dynamic>;
              final firstPoint = routePoints.first;
              return Marker(
                point: LatLng(firstPoint['lat'], firstPoint['lng']),
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                ),
              );
            }).toList(),
          ),
        // End markers
        if (sessions.isNotEmpty)
          MarkerLayer(
            markers: sessions.where((s) {
              final routePoints = s['routePoints'] as List<dynamic>?;
              return routePoints != null && routePoints.length >= 2;
            }).map((session) {
              final routePoints = session['routePoints'] as List<dynamic>;
              final lastPoint = routePoints.last;
              return Marker(
                point: LatLng(lastPoint['lat'], lastPoint['lng']),
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                ),
              );
            }).toList(),
          ),
        // Checkpoint markers
        if (sessions.isNotEmpty)
          MarkerLayer(
            markers: sessions.expand((session) {
              final checkpoints = session['checkpoints'] as List<dynamic>?;
              if (checkpoints == null) return <Marker>[];
              return checkpoints.map((cp) {
                return Marker(
                  point: LatLng(cp['lat'], cp['lng']),
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warning.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.pause_rounded, size: 12, color: Colors.white),
                  ),
                );
              }).toList();
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFloatingHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Admin Dashboard',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onDark,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.download_rounded, color: AppTheme.success, size: 20),
                    onPressed: _showExportDialog,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.person_add_rounded, color: AppTheme.secondary, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddUsersScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.manage_accounts_rounded, color: AppTheme.primary, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                    onPressed: () => _handleLogout(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingKPICards() {
    return SizedBox(
      height: 95,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FloatingKPICard(
            icon: Icons.people_rounded,
            label: 'Total Users',
            value: '${_stats['totalUsers'] ?? 0}',
            gradient: [AppTheme.primary, AppTheme.secondary],
          ),
          const SizedBox(width: 12),
          _FloatingKPICard(
            icon: Icons.route_rounded,
            label: 'Sessions Today',
            value: '${_stats['sessionsToday'] ?? 0}',
            gradient: [AppTheme.secondary, AppTheme.success],
          ),
          const SizedBox(width: 12),
          _FloatingKPICard(
            icon: Icons.straighten_rounded,
            label: 'Distance Today',
            value: '${(_stats['distanceToday'] ?? 0).toStringAsFixed(1)} km',
            gradient: [AppTheme.success, AppTheme.warning],
          ),
          const SizedBox(width: 12),
          _FloatingKPICard(
            icon: Icons.place_rounded,
            label: 'Stops Today',
            value: '${_stats['stopsToday'] ?? 0}',
            gradient: [AppTheme.warning, AppTheme.error],
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(ScrollController scrollController) {
    // Get user sessions if a user is selected
    final userSessions = _selectedUserId != null
        ? _allSessions.where((s) => s['userId']?.toString() == _selectedUserId).toList()
        : [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onDarkMuted.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Session switcher (shown when user is selected)
          if (_selectedUserId != null && userSessions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_rounded, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Sessions',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${userSessions.length} total',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onDarkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _SessionChip(
                          label: 'All Sessions',
                          isSelected: _selectedSessionId == null,
                          onTap: () => _onSessionSelected(null),
                        ),
                        const SizedBox(width: 8),
                        ...userSessions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final session = entry.value;
                          final sessionId = session['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _SessionChip(
                              label: 'Session ${index + 1}',
                              isSelected: _selectedSessionId == sessionId,
                              onTap: () => _onSessionSelected(sessionId),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppTheme.onDarkMuted.withOpacity(0.15), height: 1),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Users',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onDark,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${_users.length}',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = _users[index];
                final isSelected = _selectedUserId == user['id'].toString();
                
                return GestureDetector(
                  onTap: () {
                    final userId = user['id']?.toString();
                    final isSelected = _selectedUserId == userId;
                    _onUserSelected(isSelected ? null : userId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [AppTheme.primary.withOpacity(0.12), AppTheme.secondary.withOpacity(0.12)],
                            )
                          : null,
                      color: isSelected ? null : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? AppTheme.primary.withOpacity(0.15)
                              : Colors.black.withOpacity(0.03),
                          blurRadius: isSelected ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              (user['username'] ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['username'] ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onDark,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.route_rounded, size: 15, color: AppTheme.onDarkMuted),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${user['sessionCount'] ?? 0} sessions',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: AppTheme.onDarkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.download_rounded, color: AppTheme.success, size: 18),
                              onPressed: () => _exportUser(user['id'].toString()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingKPICard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const _FloatingKPICard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onDarkMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SessionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                )
              : null,
          color: isSelected ? null : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.onDark,
          ),
        ),
      ),
    );
  }
}


class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.onDarkMuted.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.onDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.onDarkMuted),
          ],
        ),
      ),
    );
  }
}
