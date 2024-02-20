import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:math';

class MQTTConnectionHandler {
  MqttServerClient client = MqttServerClient.withPort(
    "test.mosquitto.org",
    "flutter_${getRandomString(8)}",
    1883
  );
  
  MQTTConnectionHandler() {
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    
    final connectionMessage = MqttConnectMessage()
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connectionMessage;
  }

  Future<bool> connect() async {
    try {
      await client.connect();
      return true;
    } catch (e) {
      client.disconnect();
      return false;
    }
  }

  void setOnConnected(Function() callback) {
    client.onConnected = callback;
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void setCallback(Function(List<MqttReceivedMessage<MqttMessage>>) callback) {
    client.updates?.listen(callback);
  }
}

String getRandomString(int length) {
  final random = Random();
  final result = String.fromCharCodes(
    List.generate(length, (index) => random.nextInt(33) + 89)
  );

  return result;
}