import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static const String _host = 'mta-mqtt.dtsvtm.com';
  static const int _port = 8883;
  static const String _username = 'mtabox';
  static const String _password = 'mta123.';
  static const String _clientIdPrefix = 'mta_tablet';

  MqttServerClient? _client;
  Timer? _retryTimer;
  final List<Map<String, dynamic>> _queue = [];

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    _retryTimer?.cancel();
    final clientId = '${_clientIdPrefix}_${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient.withPort(_host, clientId, _port);
    _client!.secure = true;
    _client!.securityContext = SecurityContext.defaultContext;
    _client!.onBadCertificate = (dynamic cert) => true;
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.setProtocolV311();
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onAutoReconnect = () => print('MQTT: Yeniden baglaniliyor...');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(_username, _password)
        .startClean();
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      if (!isConnected) {
        print('MQTT: Baglanti kurulamadi, 5 sn sonra tekrar denenecek.');
        _scheduleRetry();
      }
    } catch (e) {
      print('MQTT baglanti hatasi: $e');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () => connect());
  }

  void _onConnected() {
    print('MQTT baglantisi kuruldu: $_host:$_port');
    if (_queue.isNotEmpty) {
      print('MQTT kuyruktaki ${_queue.length} mesaj gonderiliyor...');
      for (var item in _queue) {
        _send(item['topic'], item['payload']);
      }
      _queue.clear();
    }
  }

  void _onDisconnected() {
    print('MQTT baglantisi kesildi.');
  }

  void publish(String topic, Map<String, dynamic> payload) {
    if (!isConnected) {
      print('MQTT bagli degil, kuyruga eklendi -> $topic');
      _queue.add({'topic': topic, 'payload': payload});
      return;
    }
    _send(topic, payload);
  }

  void _send(String topic, Map<String, dynamic> payload) {
    try {
      final jsonStr = jsonEncode(payload);
      final builder = MqttClientPayloadBuilder();
      builder.addUTF8String(jsonStr);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('MQTT -> $topic');
    } catch (e) {
      print('MQTT yayinlama hatasi: $e');
    }
  }

  void disconnect() {
    _retryTimer?.cancel();
    _client?.disconnect();
  }
}
