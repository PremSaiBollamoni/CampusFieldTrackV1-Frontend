import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import './tracking_service.dart';
import './file_writer_stub.dart'
    if (dart.library.io) './file_writer_mobile.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  String generateGpx(TrackingSession session) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<gpx version="1.1" creator="CampusFieldTrack" xmlns="http://www.topografix.com/GPX/1/1">',
    );
    buffer.writeln('  <metadata>');
    buffer.writeln(
      '    <name>Field Session ${session.startTime.toIso8601String()}</name>',
    );
    buffer.writeln(
      '    <time>${session.startTime.toUtc().toIso8601String()}</time>',
    );
    buffer.writeln('  </metadata>');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${session.areaName ?? "Field Session"}</name>');
    buffer.writeln('    <trkseg>');
    for (final point in session.routePoints) {
      buffer.writeln('      <trkpt lat="${point.lat}" lon="${point.lng}">');
      buffer.writeln('        <ele>${point.altitude.toStringAsFixed(1)}</ele>');
      buffer.writeln(
        '        <time>${point.timestamp.toUtc().toIso8601String()}</time>',
      );
      buffer.writeln(
        '        <speed>${point.speed.toStringAsFixed(2)}</speed>',
      );
      buffer.writeln('      </trkpt>');
    }
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  String generateCsv(TrackingSession session) {
    final buffer = StringBuffer();
    buffer.writeln(
      'timestamp,latitude,longitude,altitude_m,speed_ms,accuracy_m',
    );
    for (final point in session.routePoints) {
      buffer.writeln(
        '${point.timestamp.toIso8601String()},${point.lat},${point.lng},${point.altitude.toStringAsFixed(1)},${point.speed.toStringAsFixed(2)},${point.accuracy.toStringAsFixed(1)}',
      );
    }
    return buffer.toString();
  }

  String generateJson(TrackingSession session) {
    final data = {
      'session_id': session.id,
      'start_time': session.startTime.toIso8601String(),
      'end_time': session.endTime?.toIso8601String(),
      'duration_seconds': session.durationSeconds,
      'distance_km': session.distanceKm,
      'avg_speed_kmh': session.avgSpeedKmh,
      'stops_count': session.checkpoints.length,
      'area': session.areaName,
      'route_points': session.routePoints
          .map(
            (p) => {
              'lat': p.lat,
              'lng': p.lng,
              'alt': p.altitude,
              'speed_ms': p.speed,
              'accuracy_m': p.accuracy,
              'timestamp': p.timestamp.toIso8601String(),
            },
          )
          .toList(),
      'checkpoints': session.checkpoints
          .map(
            (c) => {
              'lat': c.location.latitude,
              'lng': c.location.longitude,
              'arrived_at': c.arrivedAt.toIso8601String(),
              'departed_at': c.departedAt?.toIso8601String(),
              'duration_seconds': c.duration.inSeconds,
            },
          )
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> exportAndShare(
    BuildContext context,
    TrackingSession session,
    String format,
  ) async {
    try {
      String content;
      String filename;

      final dateStr = session.startTime
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);

      switch (format.toUpperCase()) {
        case 'GPX':
          content = generateGpx(session);
          filename = 'fieldtrack_$dateStr.gpx';
          break;
        case 'CSV':
          content = generateCsv(session);
          filename = 'fieldtrack_$dateStr.csv';
          break;
        case 'JSON':
        default:
          content = generateJson(session);
          filename = 'fieldtrack_$dateStr.json';
          break;
      }

      if (kIsWeb) {
        // Web: copy to clipboard
        await Clipboard.setData(ClipboardData(text: content));
        Fluttertoast.showToast(
          msg: '$format data copied to clipboard',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF1E293B),
          textColor: const Color(0xFFF8FAFC),
        );
      } else {
        // Mobile: save to Downloads folder
        await _saveToDownloads(filename, content);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Export failed. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        textColor: Colors.white,
      );
    }
  }

  Future<void> _saveToDownloads(String filename, String content) async {
    try {
      // Request storage permission for Android
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try with manageExternalStorage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            Fluttertoast.showToast(
              msg: 'Storage permission denied',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: const Color(0xFFEF4444),
              textColor: Colors.white,
            );
            return;
          }
        }
      }

      // Get Downloads directory path
      String downloadsPath;
      if (Platform.isAndroid) {
        downloadsPath = '/storage/emulated/0/Download';
      } else {
        // iOS or other platforms - use a fallback
        downloadsPath = Directory.systemTemp.path;
      }

      final dir = Directory(downloadsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = '$downloadsPath/$filename';
      final bytes = utf8.encode(content);
      await writeFileBytes(filePath, bytes);

      debugPrint('📁 File saved to: $filePath');

      Fluttertoast.showToast(
        msg: 'Saved to Downloads: $filename',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ Save failed: $e');
      // Fallback to clipboard
      await Clipboard.setData(ClipboardData(text: content));
      Fluttertoast.showToast(
        msg: 'Save failed. Copied to clipboard instead.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFFF59E0B),
        textColor: Colors.white,
      );
    }
  }
}
