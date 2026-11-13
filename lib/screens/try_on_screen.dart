import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/wardrobe_item.dart';

class TryOnScreen extends StatefulWidget {
  final List<WardrobeItem> selectedItems;
  const TryOnScreen({required this.selectedItems, Key? key}) : super(key: key);
  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  final List<Offset> _positions = [];
  final List<double> _scales = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _positions.addAll(List.generate(widget.selectedItems.length, (i) => Offset(100, 200 + 100.0 * i)));
    _scales.addAll(List.generate(widget.selectedItems.length, (i) => 1.0));
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied. Please enable it in settings.')),
        );
      }
      return;
    }
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Use the back camera if available
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras![0],
      );
      _controller = CameraController(backCamera, ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4B4B4B)),
        title: const Text('Try On', style: TextStyle(color: Color(0xFF4B4B4B), fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
      ),
      body: !_isCameraReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),
                ...List.generate(widget.selectedItems.length, (i) {
                  final item = widget.selectedItems[i];
                  return Positioned(
                    left: _positions[i].dx,
                    top: _positions[i].dy,
                    child: GestureDetector(
                      onScaleUpdate: (details) {
                        setState(() {
                          _positions[i] += details.focalPointDelta;
                          _scales[i] = details.scale.clamp(0.5, 3.0);
                        });
                      },
                      child: Transform.scale(
                        scale: _scales[i],
                        child: Opacity(
                          opacity: 0.85,
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(item.imageUrl, width: 120, height: 120, fit: BoxFit.contain)
                              : Container(width: 120, height: 120, color: const Color(0xFFA4D3A0)),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}