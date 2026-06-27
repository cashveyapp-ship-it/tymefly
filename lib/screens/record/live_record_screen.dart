import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LiveRecordScreen extends StatefulWidget {
  const LiveRecordScreen({super.key});

  @override
  State<LiveRecordScreen> createState() => _LiveRecordScreenState();
}

class _LiveRecordScreenState extends State<LiveRecordScreen> {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  bool loading = true;
  bool recording = false;
  int selectedCameraIndex = 0;
  int seconds = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    setupCamera();
  }

  Future<void> setupCamera() async {
    try {
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) setState(() => loading = false);
        return;
      }

      await initializeCamera(selectedCameraIndex);
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> initializeCamera(int index) async {
    setState(() => loading = true);

    await controller?.dispose();

    controller = CameraController(
      cameras[index],
      ResolutionPreset.high,
      enableAudio: true,
    );

    await controller!.initialize();

    if (!mounted) return;

    setState(() {
      selectedCameraIndex = index;
      loading = false;
    });
  }

  Future<void> switchCamera() async {
    if (recording || cameras.length < 2) return;

    final nextIndex = selectedCameraIndex == 0 ? 1 : 0;
    await initializeCamera(nextIndex);
  }

  Future<void> startRecording() async {
    if (controller == null || recording) return;

    await controller!.startVideoRecording();

    setState(() {
      recording = true;
      seconds = 0;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => seconds++);
    });
  }

  Future<void> stopRecording() async {
    if (controller == null || !recording) return;

    timer?.cancel();

    final file = await controller!.stopVideoRecording();

    if (!mounted) return;

    setState(() {
      recording = false;
      seconds = 0;
    });

    Navigator.pop<File>(context, File(file.path));
  }

  String timerText() {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    timer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Camera is not available.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          Positioned(
            top: 50,
            left: 18,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: 18,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                onPressed: switchCamera,
              ),
            ),
          ),

          Positioned(
            top: 58,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: recording ? Colors.red : Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  recording ? 'REC  ${timerText()}' : '00:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 42,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: recording ? stopRecording : startRecording,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recording ? Colors.red : Colors.white,
                    border: Border.all(
                      color: AppTheme.pink,
                      width: 5,
                    ),
                  ),
                  child: Icon(
                    recording ? Icons.stop_rounded : Icons.videocam_rounded,
                    color: recording ? Colors.white : AppTheme.primary,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
