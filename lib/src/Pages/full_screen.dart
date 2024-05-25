import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mi_app_optativa/src/Pages/Imagen_edition.dart';
import 'package:mi_app_optativa/src/Service/FireBaseService.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

class FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final List<String> imagePaths; // Nueva lista de rutas de imágenes
  final int initialIndex;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  FullImageScreen({
    required this.imageUrl,
    required this.imagePaths, // Agregar el parámetro para las rutas de imágenes
    required this.initialIndex,
  });

  Future<void> _downloadImage(BuildContext context) async {
    try {
      // Verificar si la lista de rutas de imágenes está vacía
      if (imagePaths.isEmpty) {
        throw Exception('La lista de rutas de imágenes está vacía');
      }

      // Verificar si initialIndex está dentro del rango de la lista imagePaths
      if (initialIndex < 0 || initialIndex >= imagePaths.length) {
        throw RangeError.range(initialIndex, 0, imagePaths.length - 1,
            'initialIndex fuera de rango');
      }

      final imagePath = imagePaths[initialIndex];
      print('Intentando descargar imagen: $imagePath');

      // Verificar si se está ejecutando en la plataforma web
      if (kIsWeb) {
        final anchor = html.AnchorElement(href: imageUrl)
          ..setAttribute('target', '_blank')
          ..setAttribute('download',
              ''); // Añade el atributo 'download' para indicar al navegador que descargue el archivo
        anchor.click();
        print('Descargar en la plataforma web no está implementado');
      } else {
        // Implementa la lógica para descargar en otras plataformas
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();

        if (selectedDirectory != null) {
          await _storageService.downloadFileToDirectory(
              imagePath, selectedDirectory);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imagen descargada con éxito')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se seleccionó ninguna carpeta')),
          );
        }
      }
    } catch (e) {
      print('Error al descargar la imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar la imagen')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Imagen Completa'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditImagePage(imageUrl: imageUrl),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadImage(context),
          ),
        ],
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
