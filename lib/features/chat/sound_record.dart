import 'dart:async';
import 'dart:io';

import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/core/strings/enum_manager.dart';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_multi_type/image_multi_type.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/widgets/my_button.dart';

class AudioRecorderWidget extends StatefulWidget {
  const AudioRecorderWidget({
    super.key,
    required this.onSendAudio,
  });

  final Function(File?) onSendAudio;

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  Timer? _timer;
  int _seconds = 0;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  void _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/recorded_audio.aac';

    await _recorder!.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopRecording() async {
    await _recorder!.stopRecorder();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  void _playAudio() async {
    if (_filePath == null || _isPlaying) return;

    setState(() => _isPlaying = true);
    await _player!.startPlayer(
      fromURI: _filePath!,
      whenFinished: () => setState(() => _isPlaying = false),
    );
  }

  void _stopAudio() async {
    await _player!.stopPlayer();
    setState(() => _isPlaying = false);
  }

  void _resetRecording() async {
    if (_filePath == null) return;
    try {
      await File(_filePath!).delete();
    } catch (e) {}
    setState(() {
      _filePath = null;
      _seconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _player!.closePlayer();
    _timer?.cancel();
    try {
      File(_filePath!).delete();
    } catch (e) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DrawableText(
          text: _formatTime(_seconds),
          color: Colors.black,
          size: 40.0,
        ),
        20.0.verticalSpace,
        if (!(_filePath != null && !_isRecording))
          MyButton(
            onTap: _isRecording ? _stopRecording : _startRecording,
            icon: ImageMultiType(
              url: _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
            ),
            text: _isRecording ? 'Stop recording' : 'Start Recording',
            color:
                _isRecording ? AppColorManager.mainColorLight : AppColorManager.mainColor,
          ),
        20.0.verticalSpace,
        if (_filePath != null && !_isRecording) ...[
          /// أزرار إعادة التسجيل أو الإرسال
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              20.0.horizontalSpace,

              Expanded(
                child: MyButton(
                  onTap: _resetRecording,
                  icon: ImageMultiType(
                    url: Icons.delete,
                    color: Colors.white,
                  ),
                  text: 'Delete',
                  color: Colors.red,
                ),
              ),

              20.0.horizontalSpace,

              /// زر إرسال الصوت
              Expanded(
                child: MyButton(
                  iconAlignment: IconAlignment.end,
                  onTap: () => widget.onSendAudio(File(_filePath!)),
                  icon: ImageMultiType(
                    url: Icons.send,
                    color: Colors.white,
                  ),
                  text: 'Send',
                  color: AppColorManager.secondColor,
                ),
              ),
              20.0.horizontalSpace,
            ],
          ),
        ],
      ],
    );
  }
}

class AudioMessageBuilder extends StatefulWidget {
  final String audioUrl;

  const AudioMessageBuilder({
    Key? key,
    required this.audioUrl,
  }) : super(key: key);

  @override
  _AudioMessageBuilderState createState() => _AudioMessageBuilderState();
}

class _AudioMessageBuilderState extends State<AudioMessageBuilder> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _resetAudio();
      }
    });
  }

  Future<void> _initAudio() async {
    String path = await _getCachedAudioPath(widget.audioUrl);
    await _audioPlayer.setFilePath(path);

    _audioPlayer.durationStream.listen((d) {
      if (d != null) setState(() => _duration = d);
    });

    _audioPlayer.positionStream.listen((p) {
      setState(() => _position = p);
    });
  }

  Future<String> _getCachedAudioPath(String url) async {
    var file = await DefaultCacheManager().getSingleFile(url);
    return file.path;
  }

  void _playPause() async {
    if (_audioPlayer.playing) {
      setState(() {
        isPlaying = false;
      });
      await _audioPlayer.pause();
    } else {
      setState(() {
        isPlaying = true;
      });
      await _audioPlayer.play();
    }
  }

  void _resetAudio() {
    _audioPlayer.stop();
    setState(() {
      isPlaying = false;
      _position = Duration.zero;
    });
    _audioPlayer.seek(Duration.zero);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: ImageMultiType(
              height: 30.0.r,
              width: 30.0.r,
              url: isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _playPause,
          ),
          Expanded(
            child: Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              value: _position.inSeconds.toDouble(),
              activeColor: AppColorManager.threadColor,
              thumbColor: AppColorManager.whit,
              onChanged: (value) async {
                final position = Duration(seconds: value.toInt());
                await _audioPlayer.seek(position);
                setState(() => _position = position);
              },
            ),
          ),
          DrawableText(
            text: _formatDuration(_duration - _position),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
