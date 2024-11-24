import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class CO2Screen extends StatefulWidget {
  @override
  _CO2ScreenState createState() => _CO2ScreenState();
}

class _CO2ScreenState extends State<CO2Screen> {
  final client = MqttServerClient('broker.hivemq.com', '');
  String co2Level = '0'; // CO2 Level in ppm
  Color co2Color = Colors.green; // Default color for safe CO2 levels
  bool isConnected = false; // Track connection status
  TextEditingController thresholdController = TextEditingController();
  int alertThreshold = 1000; // Default CO2 threshold for alert

  @override
  void initState() {
    super.initState();
    _initializeMQTTClient();
  }

  // Initialize MQTT Client
  Future<void> _initializeMQTTClient() async {
    client.port = 1883;
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;
    client.logging(on: true);

    // Connect to the broker
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(
            'flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .keepAliveFor(60);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Connection error: $e');
      setState(() {
        co2Level = 'Connection failed';
      });
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      setState(() {
        co2Level = 'Connected';
      });
      _subscribeToTopic();
    } else {
      print('Failed to connect, status: ${client.connectionStatus}');
      setState(() {
        co2Level = 'Connection failed';
      });
      client.disconnect();
    }
  }

  // Function to connect to the MQTT broker
  void _subscribeToTopic() {
    const topic = 'classe/hayder/co2';
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final recentMessage = messages![0].payload as MqttPublishMessage;
      final co2Data = MqttPublishPayload.bytesToStringAsString(
          recentMessage.payload.message);

      print('Received CO² level: $co2Data ppm');
      setState(() {
        co2Level = '$co2Data ppm';
        print(co2Level);
      });
    });
  }

  void _onDisconnected() {
    print('Disconnected from broker');
    setState(() {
      co2Level = 'Disconnected';
    });
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  // Handle received messages
  void _onMessageReceived(
      List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> event) {
    final mqtt.MqttPublishMessage message =
        event[0].payload as mqtt.MqttPublishMessage;
    final payload =
        mqtt.MqttPublishPayload.bytesToStringAsString(message.payload.message);

    setState(() {
      co2Level = payload; // Update CO2 level with the received value
      _updateCO2Color(); // Update color based on new value
      _checkAlertCondition(); // Check if the CO2 level exceeds the threshold
    });
  }

  // Update the color based on CO2 levels
  void _updateCO2Color() {
    final int co2 = int.tryParse(co2Level) ?? 0;
    if (co2 < 400) {
      co2Color = Colors.green; // Safe
    } else if (co2 < 1000) {
      co2Color = Colors.orange; // Caution
    } else {
      co2Color = Colors.red; // Dangerous
    }
  }

  // Check if CO2 level exceeds the alert threshold
  void _checkAlertCondition() {
    final int co2 = int.tryParse(co2Level) ?? 0;
    if (co2 >= alertThreshold) {
      _showAlert("CO2 level has reached $co2 ppm, exceeding the limit!");
    }
  }

  // Show alert dialog
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('CO2 Alert'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // MQTT Callback when subscribed
  void _onSubscribed(String topic) {
    print("Successfully subscribed to topic: $topic");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CO2 Level Monitoring')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Real-time CO2 Level:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              isConnected ? '$co2Level ppm' : 'Connecting...',
              style: TextStyle(fontSize: 48, color: co2Color),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(co2Color),
            ),
            /*SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Implement further actions, e.g., show logs
              },
              child: Text('More Info'),
            ),*/
            SizedBox(height: 20),
            Text(
              co2Level,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            // Text Field for CO2 threshold
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Threshold (ppm)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    alertThreshold = int.tryParse(value) ??
                        1000; // Default to 1000 if invalid input
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Trigger threshold setting confirmation
                setState(() {
                  alertThreshold =
                      int.tryParse(thresholdController.text) ?? 1000;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Alert threshold set to $alertThreshold ppm')),
                );
              },
              child: Text('Set Threshold'),
            ),
          ],
        ),
      ),
    );
  }
}
