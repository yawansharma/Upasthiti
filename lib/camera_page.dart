import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();

    // 🔴 SAFETY CHECK (Windows only)
    if (!Platform.isWindows) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) // Transparent background in Flutter
      ..loadHtmlString(_cameraHtml);

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    // 1. NON-WINDOWS FALLBACK UI
    if (!Platform.isWindows) {
      return Scaffold(
        backgroundColor: const Color(0xFF101010),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_outlined,
                  size: 64, color: Colors.grey.shade700),
              const SizedBox(height: 16),
              const Text(
                "Camera not supported",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Text(
                "This feature is available on Windows only.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 2. LOADING STATE UI
    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF101010),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6A8A73), // Sage Green loader
          ),
        ),
      );
    }

    // 3. MAIN CAMERA UI
    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Dark Charcoal
      appBar: AppBar(
        title: const Text("Camera"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Text
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Align your face within the frame",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),

          // The Viewfinder
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF6A8A73), // Sage Green Border
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A8A73).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              // ClipRRect ensures the square WebView doesn't bleed out of rounded corners
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: WebViewWidget(controller: _controller!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔴 HTML with LIVE CAMERA (Slightly styled to ensure full fit)
const String _cameraHtml = """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { margin: 0; background: black; overflow: hidden; display: flex; align-items: center; justify-content: center; height: 100vh; }
  video { width: 100%; height: 100%; object-fit: cover; }
  h2 { font-family: sans-serif; text-align: center; }
</style>
</head>
<body>
<video id="video" autoplay playsinline></video>

<script>
navigator.mediaDevices.getUserMedia({ video: true })
  .then(stream => {
    document.getElementById('video').srcObject = stream;
  })
  .catch(err => {
    document.body.innerHTML = '<h2 style="color:white;">Camera error: ' + err + '</h2>';
  });
</script>

</body>
</html>
""";

