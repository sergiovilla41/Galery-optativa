import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';

class ImageEditorScreen extends StatefulWidget {
  final String imageUrl;

  const ImageEditorScreen({required this.imageUrl});

  @override
  _ImageEditorScreenState createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late Uint8List _editedImageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndEditImage();
  }

  Future<void> _loadAndEditImage() async {
    setState(() {
      _isLoading = true; // Inicia el indicador de carga
    });

    try {
      final File? editedFile = await FlutterNativeImage.compressImage(
        widget.imageUrl,
        quality: 80,
        percentage: 100,
      );

      if (editedFile != null) {
        _editedImageBytes = await editedFile.readAsBytes();
      } else {
        throw Exception('El archivo editado es nulo');
      }
    } catch (error) {
      print('Error al cargar/editar la imagen: $error');
      // En caso de error, muestra un mensaje y deja _editedImageBytes vacío
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('No se pudo cargar/editar la imagen'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isLoading = false; // Detiene el indicador de carga
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Editor'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _editedImageBytes.isNotEmpty
              ? Center(
                  child: Image.memory(
                    _editedImageBytes,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text('No se pudo editar la imagen'),
                ),
    );
  }
}
