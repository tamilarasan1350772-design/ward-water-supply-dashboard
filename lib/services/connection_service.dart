import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionService {
  static const String _simulatedOnlineKey = 'simulated_online_status';
  final _connectionController = StreamController<bool>.broadcast();

  ConnectionService() {
    _init();
  }

  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnline = prefs.getBool(_simulatedOnlineKey) ?? true;
    _connectionController.add(isOnline);
  }

  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_simulatedOnlineKey) ?? true;
  }

  Future<void> setConnected(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simulatedOnlineKey, status);
    _connectionController.add(status);
  }

  void dispose() {
    _connectionController.close();
  }
}
