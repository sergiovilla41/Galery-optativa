import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mi_app_optativa/src/Service/FireBaseService.dart'; // Ajusta el import según la ubicación real del archivo
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraFloatingButton extends StatefulWidget {
  @override
  _CameraFloatingButtonState createState() => _CameraFloatingButtonState();
}

class _CameraFloatingButtonState extends State<CameraFloatingButton> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  late FirebaseStorageService _firebaseStorageService;

  @override
  void initState() {
    super.initState();
    _firebaseStorageService = FirebaseStorageService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {});
    }
  }

  Future<void> _takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final XFile imageFile = await _controller!.takePicture();
        final String imagePath = imageFile.path;

        // Subir imagen a Firebase Storage
        final fileName = path.basename(imagePath);
        await _firebaseStorageService.uploadFile(
            File(imagePath), 'images/$fileName');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto tomada y subida con éxito')),
        );
      } catch (e) {
        print('Error al tomar la foto: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar la foto')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller == null || !_controller!.value.isInitialized
        ? Container()
        : FloatingActionButton(
            onPressed: _takePicture,
            child: Icon(Icons.camera_alt),
          );
  }
}
