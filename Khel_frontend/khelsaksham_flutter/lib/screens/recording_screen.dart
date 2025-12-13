import 'dart:typed_data';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/api_singleton.dart';

class RecordingScreen extends StatefulWidget {
  final String exercise;

  const RecordingScreen({super.key, required this.exercise});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late String selectedExercise;
  String recordingState = "idle"; // idle | recording | preview
  int repCount = 0;
  double? maxJumpHeight; // cm (approx)
  String? videoUri;

  CameraController? _controller;
  late final PoseDetector _poseDetector;
  bool _isBusy = false;

  // state trackers
  bool _wasDown = false;
  bool _wasLow = false;
  bool _wasHigh = false;

  // baseline for jump
  double? _baselineAnkleY;

  final exercises = const [
    {"id": "pushups", "icon": Icons.fitness_center, "title": "Push-ups", "desc": "Record continuous push-ups"},
    {"id": "situps", "icon": Icons.chair, "title": "Sit-ups", "desc": "Record abdominal crunches"},
    {"id": "jump", "icon": Icons.directions_run, "title": "Vertical Jump", "desc": "Record maximum jump height"},
    {"id": "pullups", "icon": Icons.sports_gymnastics, "title": "Pull-ups", "desc": "Record upper body strength"},
  ];

  @override
  void initState() {
    super.initState();
    selectedExercise = widget.exercise;
    _initCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = recordingState == "recording";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Recording Studio",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const Text("Record your athletic performance for AI-powered assessment",
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 16),

            // Exercise Picker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Exercise",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 12),
                  ...exercises.map((ex) {
                    final active = selectedExercise == ex["id"];
                    return GestureDetector(
                      onTap: () => setState(() {
                        selectedExercise = ex["id"] as String;
                        repCount = 0;
                        maxJumpHeight = null;
                        _resetFlags();
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFEFF6FF) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: active ? Border.all(color: const Color(0xFF3B82F6)) : null,
                        ),
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(ex["icon"] as IconData,
                                size: 22,
                                color: active ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ex["title"] as String,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: active ? const Color(0xFF1E3A8A) : const Color(0xFF334155))),
                              Text(ex["desc"] as String,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ]),
                          )
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Camera Preview & Recording Controls
            Container(
              height: 400,
              decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(16)),
              child: Stack(alignment: Alignment.center, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _controller != null && _controller!.value.isInitialized
                      ? CameraPreview(_controller!)
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                if (isRecording)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("${selectedExercise.toUpperCase()} detected",
                            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
                        Text("$repCount",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        if (selectedExercise == "jump" && maxJumpHeight != null)
                          Text("Max Jump: ${maxJumpHeight!.toStringAsFixed(1)} px",
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ]),
                    ),
                  ),
                if (!isRecording)
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.fitness_center, size: 36, color: Color(0xFF475569)),
                    const SizedBox(height: 8),
                    Text("Ready to Record ${selectedExercise.toUpperCase()}",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    const Text("Position yourself in frame and tap record",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ]),
                if (recordingState == "preview")
                  Positioned(
                    bottom: 16,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        onPressed: handleRetake,
                        child: const Text("Retake"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        onPressed: handleUpload,
                        child: const Text("Upload"),
                      ),
                    ]),
                  )
                else
                  Positioned(
                    bottom: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: isRecording ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      onPressed: handleRecordPress,
                      icon: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isRecording ? 2 : 5),
                        ),
                      ),
                      label: Text(isRecording ? "Stop" : "Record"),
                    ),
                  )
              ]),
            ),
            if (videoUri != null)
              Text("Video saved at: $videoUri",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            Text("Status: $recordingState",
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  void handleRecordPress() {
    setState(() {
      if (recordingState == "idle") {
        repCount = 0;
        videoUri = null;
        maxJumpHeight = null;
        recordingState = "recording";
        _resetFlags();
      } else if (recordingState == "recording") {
        recordingState = "preview";
      }
    });
  }

  void handleRetake() {
    setState(() {
      videoUri = null;
      recordingState = "idle";
      repCount = 0;
      maxJumpHeight = null;
      _resetFlags();
    });
  }

  /// ✅ Upload to backend
  Future<void> handleUpload() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading workout result...")),
    );
    try {
      // For now, skip actual video (we can add later)
      final response = await api.saveResult({
  "exercise": selectedExercise,
  "reps": repCount,
  "video_url": "https://placeholder.video",
  "video_hash": "hash_${DateTime.now().millisecondsSinceEpoch}",
  "timestamp": DateTime.now().toIso8601String(),
});

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("✅ Result submitted successfully!")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("⚠️ Upload failed: ${response.statusCode}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error submitting: $e")));
    } finally {
      setState(() {
        recordingState = "idle";
        repCount = 0;
        maxJumpHeight = null;
        videoUri = null;
      });
    }
  }

  void _detectExercise(Pose pose) {
    switch (selectedExercise) {
      case "pushups":
        _detectPushups(pose);
        break;
      case "situps":
        _detectSitups(pose);
        break;
      case "jump":
        _detectJumps(pose);
        break;
      case "pullups":
        _detectPullups(pose);
        break;
    }
  }

  void _detectJumps(Pose pose) {
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (ankle == null) return;

    _baselineAnkleY ??= ankle.y;

    final diff = _baselineAnkleY! - ankle.y;
    final jumping = diff > 30;

    if (jumping && !_wasLow) {
      _wasLow = true;
      if (diff > (maxJumpHeight ?? 0)) {
        setState(() => maxJumpHeight = diff);
      }
    } else if (!jumping && _wasLow) {
      _wasLow = false;
      setState(() => repCount++);
    }
  }

  void _detectPullups(Pose pose) {
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    if (wrist == null || shoulder == null) return;

    const tol = 30.0;
    final above = wrist.y < shoulder.y - tol;

    if (above && !_wasHigh) _wasHigh = true;
    else if (!above && _wasHigh) {
      _wasHigh = false;
      setState(() => repCount++);
    }
  }

  void _detectPushups(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    if (shoulder == null || elbow == null) return;

    const tol = 25.0;
    final down = elbow.y > shoulder.y + tol;

    if (down && !_wasDown) _wasDown = true;
    else if (!down && _wasDown) {
      _wasDown = false;
      setState(() => repCount++);
    }
  }

  void _detectSitups(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    if (nose == null || hip == null) return;

    const tol = 50.0;
    final down = nose.y > hip.y + tol;

    if (down && !_wasDown) _wasDown = true;
    else if (!down && _wasDown) {
      _wasDown = false;
      setState(() => repCount++);
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _controller!.initialize();

    if (!mounted) return;
    setState(() {});
    _controller!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || recordingState != "recording") return;
    _isBusy = true;

    try {
      final bytesBuilder = BytesBuilder();
      for (final plane in image.planes) {
        bytesBuilder.add(plane.bytes);
      }
      final bytes = bytesBuilder.toBytes();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(
                  _controller!.description.sensorOrientation) ??
              InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) _detectExercise(poses.first);
    } catch (e) {
      debugPrint("Detection error: $e");
    }

    _isBusy = false;
  }

  void _resetFlags() {
    _wasDown = false;
    _wasLow = false;
    _wasHigh = false;
    _baselineAnkleY = null;
  }
}
