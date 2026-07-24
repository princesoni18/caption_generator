import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'home_screen.dart';

class SplashDownloadScreen extends StatefulWidget {
  const SplashDownloadScreen({super.key});

  @override
  State<SplashDownloadScreen> createState() => _SplashDownloadScreenState();
}

class _SplashDownloadScreenState extends State<SplashDownloadScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'Checking resources...';
  CancelToken? _cancelToken;
  
  // The medium model is ~1.5GB
  final String modelUrl = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin';
  final String modelFilename = 'ggml-medium.bin';

  @override
  void initState() {
    super.initState();
    _checkAndDownloadModel();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _checkAndDownloadModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedPath = prefs.getString('custom_model_path');
      String basePath;

      if (savedPath != null && savedPath.isNotEmpty) {
        basePath = savedPath;
      } else {
        final Directory docDir = await getApplicationDocumentsDirectory();
        basePath = docDir.path;
      }

      final String modelPath = '$basePath/$modelFilename';
      final File modelFile = File(modelPath);

      if (await modelFile.exists()) {
        setState(() {
          _statusMessage = 'Resources ready.';
          _progress = 1.0;
          _isDownloading = false;
        });
        _navigateToHome(modelPath);
      } else {
        setState(() {
          _isDownloading = true;
          _statusMessage = 'Downloading Model... (This may take a while)';
        });
        await _downloadFile(modelUrl, modelPath);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking resources: $e';
      });
    }
  }

  Future<void> _downloadFile(String url, String savePath) async {
    Dio dio = Dio();
    _cancelToken = CancelToken();
    try {
      await dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _statusMessage = 'Downloading Model... ${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB\nSaving to: $savePath';
            });
          }
        },
      );
      
      setState(() {
        _statusMessage = 'Download Complete!';
        _isDownloading = false;
      });
      _navigateToHome(savePath);
      
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return; // User cancelled
      }
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download Failed. Please check your internet connection.\n$e';
      });
    } finally {
      dio.close();
    }
  }

  Future<void> _changeFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_model_path', selectedDirectory);
      
      _cancelToken?.cancel('User changed directory');
      
      setState(() {
        _progress = 0.0;
        _isDownloading = false;
      });

      _checkAndDownloadModel();
    }
  }

  void _navigateToHome(String modelPath) {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(modelPath: modelPath),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                size: 80,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 30),
              Text(
                'WHISPER CAPTIONS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 40),
              if (_isDownloading || _progress < 1.0)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey.shade900,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (Platform.isWindows)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Change Download Folder'),
                        onPressed: _changeFolder,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurpleAccent,
                          side: const BorderSide(color: Colors.deepPurpleAccent),
                        ),
                      ),
                  ],
                )
              else
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.greenAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
