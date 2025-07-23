import 'package:flutter/material.dart';
import '../main.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class VideoRecorderScreen extends StatefulWidget {
  const VideoRecorderScreen({super.key});

  @override
  State<VideoRecorderScreen> createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera available.')),
        );
      }
      return;
    }
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: true,
    );

    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        })
        .catchError((Object e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                print('User denied camera access.');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Camera access denied. Please enable in settings.')),
                  );
                }
                break;
              default:
                print('Handle other camera errors: ${e.code}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Camera error: ${e.description}')),
                  );
                }
                break;
            }
          }
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not initialized.')),
        );
      }
      return;
    }
    if (_isRecording) {
      return;
    }

    try {
      setState(() {
        _isRecording = true;
      });
      await _controller!.startVideoRecording();
    } on CameraException catch (e) {
      print('Error starting video recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: ${e.description}')),
        );
      }
      setState(() {
        _isRecording = false;
      });
      return;
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return;
    }

    try {
      final XFile file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      _saveVideoToDownloads(file.path);
    } on CameraException catch (e) {
      print('Error stopping video recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: ${e.description}')),
        );
      }
      setState(() {
        _isRecording = false;
      });
      return;
    }
  }

  Future<void> _saveVideoToDownloads(String videoFilePath) async {
    try {
      Directory? targetDirectory;
      if (Platform.isAndroid) {
        // For Android, use a well-known public directory like Downloads
        targetDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        // For iOS, save to the application's documents directory
        targetDirectory = await getApplicationDocumentsDirectory();
      } else {
        // Fallback for other platforms, might need specific implementation
        targetDirectory = await getApplicationDocumentsDirectory();
      }

      if (!await targetDirectory!.exists()) {
        await targetDirectory.create(recursive: true);
      }

      final String fileName =
          'SakhiSuraksha_Video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String newPath = '${targetDirectory.path}/$fileName';
      await File(videoFilePath).copy(newPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video saved to: ${targetDirectory.path}/$fileName')),
        );
      }
    } catch (e) {
      print('Error saving video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller == null || !_controller!.value.isInitialized) {
              return const Center(
                child: Text(
                  'No camera available or access denied.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: GestureDetector(
                      onTap: () {
                        if (_isRecording) {
                          _stopVideoRecording();
                        } else {
                          _startVideoRecording();
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 12),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : null,
                          color: _isRecording ? Colors.white : Colors.black,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            );
          } else {
            // Show a loading indicator while camera is initializing
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
            );
          }
        },
      ),
    );
  }
}

