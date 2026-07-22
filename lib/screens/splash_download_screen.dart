import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  
  // The medium model is ~1.5GB
  final String modelUrl = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin';
  final String modelFilename = 'ggml-medium.bin';

  @override
  void initState() {
    super.initState();
    _checkAndDownloadModel();
  }

  Future<void> _checkAndDownloadModel() async {
    try {
      final Directory docDir = await getApplicationDocumentsDirectory();
      final String modelPath = '${docDir.path}/$modelFilename';
      final File modelFile = File(modelPath);

      if (await modelFile.exists()) {
        setState(() {
          _statusMessage = 'Resources ready.';
          _progress = 1.0;
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
    try {
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _statusMessage = 'Downloading Model... ${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
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
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download Failed. Please check your internet connection.\n$e';
      });
    } finally {
      dio.close();
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
