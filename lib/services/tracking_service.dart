import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './api_service.dart';

enum TrackingState { idle, active, paused, stopped }

class RoutePoint {
  final double lat;
  final double lng;
  final double altitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  RoutePoint({
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  LatLng get latLng => LatLng(lat, lng);

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'alt': altitude,
    'speed': speed,
    'accuracy': accuracy,
    'ts': timestamp.millisecondsSinceEpoch,
  };

  factory RoutePoint.fromJson(Map<String, dynamic> j) => RoutePoint(
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    altitude: (j['alt'] as num?)?.toDouble() ?? 0.0,
    speed: (j['speed'] as num?)?.toDouble() ?? 0.0,
    accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0.0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
  );

  factory RoutePoint.fromPosition(Position p) => RoutePoint(
    lat: p.latitude,
    lng: p.longitude,
    altitude: p.altitude,
    speed: p.speed < 0 ? 0 : p.speed,
    accuracy: p.accuracy,
    timestamp: p.timestamp,
  );
}

class CheckpointData {
  final LatLng location;
  final DateTime arrivedAt;
  DateTime? departedAt;
  final int index;

  CheckpointData({
    required this.location,
    required this.arrivedAt,
    required this.index,
    this.departedAt,
  });

  Duration get duration => (departedAt ?? DateTime.now()).difference(arrivedAt);

  Map<String, dynamic> toJson() => {
    'lat': location.latitude,
    'lng': location.longitude,
    'arrivedAt': arrivedAt.millisecondsSinceEpoch,
    'departedAt': departedAt?.millisecondsSinceEpoch,
    'index': index,
  };

  factory CheckpointData.fromJson(Map<String, dynamic> j) => CheckpointData(
    location: LatLng(
      (j['lat'] as num).toDouble(),
      (j['lng'] as num).toDouble(),
    ),
    arrivedAt: DateTime.fromMillisecondsSinceEpoch(j['arrivedAt'] as int),
    departedAt: j['departedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['departedAt'] as int)
        : null,
    index: j['index'] as int,
  );
}

class TrackingSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<RoutePoint> routePoints;
  final List<CheckpointData> checkpoints;
  double distanceKm;
  TrackingState state;
  String? areaName;

  TrackingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    List<RoutePoint>? routePoints,
    List<CheckpointData>? checkpoints,
    this.distanceKm = 0.0,
    this.state = TrackingState.idle,
    this.areaName,
  }) : routePoints = routePoints ?? [],
       checkpoints = checkpoints ?? [];

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  int get durationSeconds => duration.inSeconds;

  double get avgSpeedKmh {
    if (routePoints.isEmpty || durationSeconds == 0) return 0;
    return distanceKm / (durationSeconds / 3600);
  }

  double get currentSpeedKmh {
    if (routePoints.length < 2) return 0;
    final last = routePoints.last;
    return last.speed * 3.6; // m/s to km/h
  }

  LatLng? get currentLocation =>
      routePoints.isNotEmpty ? routePoints.last.latLng : null;

  LatLng? get startLocation =>
      routePoints.isNotEmpty ? routePoints.first.latLng : null;

  List<LatLng> get polylinePoints => routePoints.map((p) => p.latLng).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.millisecondsSinceEpoch,
    'endTime': endTime?.millisecondsSinceEpoch,
    'routePoints': routePoints.map((p) => p.toJson()).toList(),
    'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
    'distanceKm': distanceKm,
    'state': state.name,
    'areaName': areaName,
  };

  factory TrackingSession.fromJson(Map<String, dynamic> j) {
    final session = TrackingSession(
      id: j['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(j['startTime'] as int),
      endTime: j['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(j['endTime'] as int)
          : null,
      routePoints: (j['routePoints'] as List<dynamic>)
          .map((p) => RoutePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      checkpoints: (j['checkpoints'] as List<dynamic>)
          .map((c) => CheckpointData.fromJson(c as Map<String, dynamic>))
          .toList(),
      distanceKm: (j['distanceKm'] as num).toDouble(),
      state: TrackingState.values.firstWhere(
        (s) => s.name == j['state'],
        orElse: () => TrackingState.stopped,
      ),
      areaName: j['areaName'] as String?,
    );
    return session;
  }
}

class TrackingService extends ChangeNotifier {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  TrackingSession? _activeSession;
  final List<TrackingSession> _completedSessions = [];

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  // Stop detection (improved)
  static const double _stopSpeedThresholdKmh = 1.5;
  static const int _stopDurationSeconds = 120; // 2 minutes
  static const double _stopLocationVarianceMeters = 15.0; // GPS jitter threshold
  static const double _stopMergeRadiusMeters = 25.0; // Merge nearby stops
  
  DateTime? _lastLowSpeedTime;
  bool _isAtStop = false;
  LatLng? _stopLocation;
  final List<LatLng> _lowSpeedBuffer = []; // Track points during low-speed period

  // Minimum distance filter (meters)
  static const double _minDistanceFilter = 5.0;

  // --- Throttle: notify UI at most once per 1.5 s during active tracking ---
  static const Duration _uiThrottleDuration = Duration(milliseconds: 1500);
  DateTime _lastNotifyTime = DateTime(2000);
  bool _pendingNotify = false;
  Timer? _notifyThrottleTimer;

  // --- Indoor / time-based checkpoint: every 30 seconds ---
  static const Duration _indoorCheckpointInterval = Duration(seconds: 30);
  Timer? _indoorCheckpointTimer;
  Position? _lastKnownPosition;

  bool _gpsAvailable = false;
  bool _permissionGranted = false;
  String? _locationError;

  // Getters
  TrackingSession? get activeSession => _activeSession;
  List<TrackingSession> get completedSessions =>
      List.unmodifiable(_completedSessions);
  TrackingState get trackingState =>
      _activeSession?.state ?? TrackingState.idle;
  bool get isTracking => trackingState == TrackingState.active;
  bool get gpsAvailable => _gpsAvailable;
  bool get permissionGranted => _permissionGranted;
  String? get locationError => _locationError;

  // Today's stats
  double get todayDistanceKm {
    final today = DateTime.now();
    return _completedSessions
        .where(
          (s) =>
              s.startTime.year == today.year &&
              s.startTime.month == today.month &&
              s.startTime.day == today.day,
        )
        .fold(0.0, (sum, s) => sum + s.distanceKm);
  }

  int get todayDurationSeconds {
    final today = DateTime.now();
    return _completedSessions
        .where(
          (s) =>
              s.startTime.year == today.year &&
              s.startTime.month == today.month &&
              s.startTime.day == today.day,
        )
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  int get todayStops {
    final today = DateTime.now();
    return _completedSessions
        .where(
          (s) =>
              s.startTime.year == today.year &&
              s.startTime.month == today.month &&
              s.startTime.day == today.day,
        )
        .fold(0, (sum, s) => sum + s.checkpoints.length);
  }

  Future<void> initialize() async {
    await _loadSessions();
    await _checkPermissions();
    _listenToServiceStatus();
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      _permissionGranted = true;
      _gpsAvailable = true;
      notifyListeners();
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _gpsAvailable = serviceEnabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _permissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!serviceEnabled) {
      _locationError = 'GPS is disabled. Please enable location services.';
    } else if (!_permissionGranted) {
      _locationError = 'Location permission denied.';
    } else {
      _locationError = null;
    }

    notifyListeners();
  }

  void _listenToServiceStatus() {
    // getServiceStatusStream is not supported on Flutter Web
    if (kIsWeb) return;

    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      status,
    ) {
      _gpsAvailable = status == ServiceStatus.enabled;
      if (!_gpsAvailable && isTracking) {
        _locationError = 'GPS signal lost. Waiting for signal...';
      } else if (_gpsAvailable) {
        _locationError = null;
      }
      notifyListeners();
    });
  }

  Future<bool> requestPermissions() async {
    await _checkPermissions();
    return _permissionGranted;
  }

  Future<void> openLocationSettings() async {
    if (kIsWeb) return;
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    if (kIsWeb) return;
    await Geolocator.openAppSettings();
  }

  Future<void> startTracking() async {
    if (!_permissionGranted) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    if (!_gpsAvailable) {
      _locationError = 'GPS is disabled. Please enable location services.';
      notifyListeners();
      return;
    }

    final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    _activeSession = TrackingSession(
      id: sessionId,
      startTime: DateTime.now(),
      state: TrackingState.active,
    );

    _lastLowSpeedTime = null;
    _lowSpeedBuffer.clear();
    _isAtStop = false;
    _stopLocation = null;
    _lastKnownPosition = null;

    _startPositionStream();
    _startIndoorCheckpointTimer();
    await _persistActiveSession();
    notifyListeners();
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPositionUpdate);
  }

  /// Starts a periodic 30-second timer that records the current position
  /// as a route point and checkpoint — ensures indoor walking is always tracked
  /// even when GPS distance changes are below the distance filter.
  void _startIndoorCheckpointTimer() {
    _indoorCheckpointTimer?.cancel();
    _indoorCheckpointTimer = Timer.periodic(_indoorCheckpointInterval, (_) {
      if (_activeSession == null ||
          _activeSession!.state != TrackingState.active) {
        return;
      }
      if (_lastKnownPosition == null) return;

      final pos = _lastKnownPosition!;
      final newPoint = RoutePoint.fromPosition(pos);
      final newLatLng = newPoint.latLng;

      // Always add the point (bypass distance filter for time-based recording)
      if (_activeSession!.routePoints.isNotEmpty) {
        final lastPoint = _activeSession!.routePoints.last;
        final distanceM = _haversineDistanceM(lastPoint.latLng, newLatLng);
        // Only accumulate distance if there was actual movement
        if (distanceM >= _minDistanceFilter) {
          _activeSession!.distanceKm += distanceM / 1000.0;
        }
      }

      _activeSession!.routePoints.add(newPoint);
      
      // Track low-speed points for improved stop detection
      final speedKmh = newPoint.speed * 3.6;
      if (speedKmh < _stopSpeedThresholdKmh) {
        if (_lastLowSpeedTime == null) {
          _lastLowSpeedTime = DateTime.now();
          _lowSpeedBuffer.clear();
          _lowSpeedBuffer.add(newLatLng);
        } else {
          _lowSpeedBuffer.add(newLatLng);
        }
      }
      
      _persistActiveSession();
      _throttledNotify();
    });
  }

  void _onPositionUpdate(Position position) {
    if (_activeSession == null ||
        _activeSession!.state != TrackingState.active) {
      return;
    }

    // Filter out very low-accuracy readings (relaxed to 100m to allow initial fixes)
    if (position.accuracy > 100) return;

    // Always store the latest known position for indoor checkpoint timer
    _lastKnownPosition = position;

    final newPoint = RoutePoint.fromPosition(position);
    final newLatLng = newPoint.latLng;

    // Distance filter
    if (_activeSession!.routePoints.isNotEmpty) {
      final lastPoint = _activeSession!.routePoints.last;
      final distanceM = _haversineDistanceM(lastPoint.latLng, newLatLng);
      if (distanceM < _minDistanceFilter) return;

      // Accumulate distance
      _activeSession!.distanceKm += distanceM / 1000.0;
    }

    _activeSession!.routePoints.add(newPoint);

    // Improved stop detection: speed + duration + stability
    final speedKmh = newPoint.speed * 3.6;
    
    if (speedKmh < _stopSpeedThresholdKmh) {
      // User is moving slowly
      if (_lastLowSpeedTime == null) {
        _lastLowSpeedTime = DateTime.now();
        _lowSpeedBuffer.clear();
        _lowSpeedBuffer.add(newLatLng);
      } else {
        _lowSpeedBuffer.add(newLatLng);
        final stoppedFor = DateTime.now().difference(_lastLowSpeedTime!).inSeconds;
        
        // Check if stop conditions are met (2 min + location stability)
        if (stoppedFor >= _stopDurationSeconds && !_isAtStop) {
          final variance = _calculateLocationVariance(_lowSpeedBuffer);
          
          // Only create stop if location is stable (variance ≤ 15m)
          if (variance <= _stopLocationVarianceMeters) {
            _isAtStop = true;
            _stopLocation = newLatLng;
            _createOrMergeCheckpoint(newLatLng);
          }
        }
      }
    } else {
      // User is moving
      _lastLowSpeedTime = null;
      _lowSpeedBuffer.clear();
      
      if (_isAtStop) {
        _isAtStop = false;
        // Close last checkpoint
        if (_activeSession!.checkpoints.isNotEmpty) {
          _activeSession!.checkpoints.last.departedAt = DateTime.now();
        }
      }
    }

    _persistActiveSession();
    _throttledNotify();
  }

  /// Notifies listeners at most once per [_uiThrottleDuration].
  /// Ensures the final update is always delivered.
  void _throttledNotify() {
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime) >= _uiThrottleDuration) {
      _lastNotifyTime = now;
      _pendingNotify = false;
      _notifyThrottleTimer?.cancel();
      notifyListeners();
    } else if (!_pendingNotify) {
      _pendingNotify = true;
      final remaining = _uiThrottleDuration - now.difference(_lastNotifyTime);
      _notifyThrottleTimer?.cancel();
      _notifyThrottleTimer = Timer(remaining, () {
        if (_pendingNotify) {
          _pendingNotify = false;
          _lastNotifyTime = DateTime.now();
          notifyListeners();
        }
      });
    }
  }

  void _recordCheckpoint(LatLng location) {
    if (_activeSession == null) return;
    final cp = CheckpointData(
      location: location,
      arrivedAt: DateTime.now(),
      index: _activeSession!.checkpoints.length,
    );
    _activeSession!.checkpoints.add(cp);
    notifyListeners();
  }

  /// Calculate location variance (max distance spread) from a buffer of points
  double _calculateLocationVariance(List<LatLng> points) {
    if (points.length < 2) return 0;
    
    double maxDistance = 0;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final dist = _haversineDistanceM(points[i], points[j]);
        if (dist > maxDistance) maxDistance = dist;
      }
    }
    return maxDistance;
  }

  /// Create checkpoint or merge with nearby existing stop
  void _createOrMergeCheckpoint(LatLng location) {
    if (_activeSession == null) return;
    
    // Check if there's a recent stop within merge radius
    if (_activeSession!.checkpoints.isNotEmpty) {
      final lastCheckpoint = _activeSession!.checkpoints.last;
      final distToLast = _haversineDistanceM(lastCheckpoint.location, location);
      
      // If within merge radius and last checkpoint is still open, extend it
      if (distToLast <= _stopMergeRadiusMeters && lastCheckpoint.departedAt == null) {
        // Don't create new checkpoint, just extend the existing one
        return;
      }
    }
    
    // Create new checkpoint
    final cp = CheckpointData(
      location: location,
      arrivedAt: DateTime.now(),
      index: _activeSession!.checkpoints.length,
    );
    _activeSession!.checkpoints.add(cp);
    notifyListeners();
  }

  /// Public method to manually record a checkpoint at [location].
  /// Used when the user explicitly taps Stop to mark the final position.
  void recordManualCheckpoint(LatLng location) {
    _recordCheckpoint(location);
  }

  void pauseTracking() {
    if (_activeSession == null) return;
    _activeSession!.state = TrackingState.paused;
    _positionSubscription?.cancel();
    _indoorCheckpointTimer?.cancel();
    _notifyThrottleTimer?.cancel();
    _pendingNotify = false;
    _lastLowSpeedTime = null;
    _lowSpeedBuffer.clear();
    _persistActiveSession();
    notifyListeners();
  }

  void resumeTracking() {
    if (_activeSession == null) return;
    _activeSession!.state = TrackingState.active;
    _lastLowSpeedTime = null;
    _lowSpeedBuffer.clear();
    _startPositionStream();
    _startIndoorCheckpointTimer();
    _persistActiveSession();
    notifyListeners();
  }

  Future<TrackingSession?> stopTracking() async {
    if (_activeSession == null) return null;

    print('🛑 STOP TRACKING CALLED');
    _positionSubscription?.cancel();
    _indoorCheckpointTimer?.cancel();
    _activeSession!.state = TrackingState.stopped;
    _activeSession!.endTime = DateTime.now();

    if (_activeSession!.checkpoints.isNotEmpty &&
        _activeSession!.checkpoints.last.departedAt == null) {
      _activeSession!.checkpoints.last.departedAt = DateTime.now();
    }

    final completed = _activeSession!;
    _activeSession = null;

    print('📊 Session stats: ${completed.routePoints.length} points, ${completed.checkpoints.length} checkpoints, ${completed.distanceKm} km');

    if (completed.routePoints.isNotEmpty && completed.distanceKm > 0.0) {
      _completedSessions.insert(0, completed);
      await _saveSessions();
      
      // Sync to backend immediately
      print('🔄 Starting backend sync...');
      try {
        await _syncToBackend(completed);
        print('✅ Backend sync successful');
        
        // Force reload from backend
        print('🔄 Reloading sessions from backend...');
        await _loadSessions();
        print('✅ Sessions reloaded from backend: ${_completedSessions.length} sessions');
      } catch (e) {
        print('❌ Sync failed: $e');
      }
    } else {
      print('⚠️ Session too short, not saving');
    }

    await _clearActiveSession();
    notifyListeners();
    return completed;
  }

  Future<void> _syncToBackend(TrackingSession session) async {
    final apiService = ApiService();
    final token = await apiService.getToken();
    
    print('🔑 JWT Token present: ${token != null}');
    if (token == null) {
      throw Exception('No authentication token');
    }

    final payload = {
      'id': session.id,
      'startTime': session.startTime.millisecondsSinceEpoch,
      'endTime': session.endTime?.millisecondsSinceEpoch,
      'distanceKm': session.distanceKm,
      'areaName': session.areaName,
      'state': session.state.name,
      'routePoints': session.routePoints.map((p) => p.toJson()).toList(),
      'checkpoints': session.checkpoints.map((c) => c.toJson()).toList(),
    };

    final routePointsList = payload['routePoints'] as List;
    final checkpointsList = payload['checkpoints'] as List;
    print('📤 Payload size: ${routePointsList.length} points, ${checkpointsList.length} checkpoints');
    print('📤 First point: ${routePointsList.isNotEmpty ? routePointsList[0] : 'none'}');
    print('📤 POST ${ApiService.baseUrl}/sessions/full-sync');

    final response = await apiService.syncSession(payload);
    print('📥 Response: $response');
    
    if (!response['success']) {
      throw Exception(response['message']);
    }
  }

  void discardSession() {
    _positionSubscription?.cancel();
    _indoorCheckpointTimer?.cancel();
    _notifyThrottleTimer?.cancel();
    _pendingNotify = false;
    _lastLowSpeedTime = null;
    _lowSpeedBuffer.clear();
    _activeSession = null;
    _clearActiveSession();
    notifyListeners();
  }

  // Haversine distance in meters
  double _haversineDistanceM(LatLng a, LatLng b) {
    const R = 6371000.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final aVal = sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLng * sinDLng;
    final c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));
    return R * c;
  }

  // Persistence
  static const String _sessionsKey = 'completed_sessions';
  static const String _activeSessionKey = 'active_session';

  Future<void> _loadSessions() async {
    try {
      print('🔄 Loading sessions...');
      final prefs = await SharedPreferences.getInstance();

      // Load completed sessions from backend ONLY
      try {
        final apiService = ApiService();
        print('🌐 Fetching sessions from backend...');
        final backendSessions = await apiService.getSessions();
        print('📥 Received ${backendSessions.length} sessions from backend');
        
        _completedSessions.clear();
        for (final sessionData in backendSessions) {
          try {
            _completedSessions.add(TrackingSession.fromJson(sessionData));
          } catch (e) {
            print('⚠️ Failed to parse session: $e');
          }
        }
        print('✅ Loaded ${_completedSessions.length} sessions from backend');
      } catch (e) {
        print('❌ Failed to load from backend: $e');
        // NO FALLBACK - show empty if backend fails
        _completedSessions.clear();
      }

      // Restore active session if any
      final activeJson = prefs.getString(_activeSessionKey);
      if (activeJson != null) {
        try {
          final decoded = jsonDecode(activeJson) as Map<String, dynamic>;
          final restored = TrackingSession.fromJson(decoded);
          // Mark as paused so user can decide to resume or discard
          restored.state = TrackingState.paused;
          _activeSession = restored;
          print('🔄 Restored active session: ${restored.id}');
        } catch (e) {
          print('⚠️ Failed to restore active session: $e');
        }
      }
    } catch (e) {
      print('❌ Load sessions error: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _completedSessions.map((s) => s.toJson()).toList(),
      );
      await prefs.setString(_sessionsKey, encoded);
    } catch (_) {}
  }

  Future<void> _persistActiveSession() async {
    if (_activeSession == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _activeSessionKey,
        jsonEncode(_activeSession!.toJson()),
      );
    } catch (_) {}
  }

  Future<void> _clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionKey);
    } catch (_) {}
  }

  Future<void> deleteSession(String sessionId) async {
    _completedSessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    _notifyThrottleTimer?.cancel();
    _indoorCheckpointTimer?.cancel();
    super.dispose();
  }
}