import 'dart:async';
import 'dart:convert';

import 'package:background_stt/speech_result.dart';
import 'package:flutter/services.dart';

class BackgroundStt {
  var _tag = "BackgroundStt";
  static const _channel = const MethodChannel('background_stt');
  static const _eventChannel = EventChannel('background_stt_stream');

  static var _lastResult = "";

  static SpeechResult _speechResultSaved = SpeechResult();

  static Stream<SpeechResult> get speechResult =>
      _speechListenerController.stream;

  static StreamController<SpeechResult> _speechListenerController =
      StreamController<SpeechResult>();

  StreamSubscription<SpeechResult> speechSubscription =
      _speechListenerController.stream.asBroadcastStream().listen(
          (data) {
            print("DataReceived: " + data.result);
          },
          onDone: () {},
          onError: (error) {
            print("Some Error");
          });

  Future<String> get startSpeechListenService async {
    final String result = await _channel.invokeMethod('startService');
    print('[$_tag] Received: $result');
    return result;
  }

  Future<String> confirmIntent(String confirmationText) async {
    final String result = await _channel.invokeMethod('confirmIntent',
        <String, dynamic>{'confirmationText': confirmationText});
    print('[$_tag] confirmIntent: $result');
    return result;
  }

  Future<String> get stopSpeechListenService async {
    _stopSpeechListener();
    final String result = await _channel.invokeMethod('stopService');
    print('[$_tag] Received: $result');
    return result;
  }

  StreamSubscription<SpeechResult> getSpeechResults() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      Map result = jsonDecode(event);
      _speechResultSaved = SpeechResult.fromJson(result);
      if (_lastResult.isEmpty || _lastResult != _speechResultSaved.result) {
        _speechListenerController.add(_speechResultSaved);
        _lastResult = _speechResultSaved.result;
      }
    }, onError: (dynamic error) {});

    return speechSubscription;
  }

  void _stopSpeechListener() {
    _speechListenerController.close();
    speechSubscription.cancel();
  }
}
