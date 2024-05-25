import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mi_app_optativa/src/Pages/Imagen_edition.dart';
import 'package:mi_app_optativa/src/Service/FireBaseService.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html; // Asegúrate de importar html para Flutter web
import 'package:path_provider/path_provider.dart';
import 'package:social_share/social_share.dart';

class FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final List<String> imagePaths;
  final int initialIndex;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  FullImageScreen({
    required this.imageUrl,
    required this.imagePaths,
    required this.initialIndex,
  });

  Future<void> _downloadImage(BuildContext context) async {
    try {
      if (imagePaths.isEmpty) {
        throw Exception('La lista de rutas de imágenes está vacía');
      }

      if (initialIndex < 0 || initialIndex >= imagePaths.length) {
        throw RangeError.range(initialIndex, 0, imagePaths.length - 1,
            'initialIndex fuera de rango');
      }

      final imagePath = imagePaths[initialIndex];
      print('Intentando descargar imagen: $imagePath');

      if (kIsWeb) {
        // Lógica de descarga para web
        final anchor = html.AnchorElement(href: imageUrl)
          ..setAttribute('target', '_blank')
          ..setAttribute('download', '');
        anchor.click();
      } else {
        // Lógica de descarga para móvil y escritorio
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();

        if (selectedDirectory != null) {
          // Descargar la imagen al directorio seleccionado
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

  Future<void> _shareImage(BuildContext context) async {
    try {
      if (imagePaths.isEmpty) {
        throw Exception('La lista de rutas de imágenes está vacía');
      }

      if (initialIndex < 0 || initialIndex >= imagePaths.length) {
        throw RangeError.range(initialIndex, 0, imagePaths.length - 1,
            'initialIndex fuera de rango');
      }

      final imagePath = imagePaths[initialIndex];
      final ref = FirebaseStorage.instance.ref().child('images/$imagePath');

      if (kIsWeb) {
        final imageUrl = await ref.getDownloadURL();
        await Share.share(imageUrl, subject: '¡Mira esta imagen!');
      } else {
        final Directory tempDir = await getTemporaryDirectory();
        final File tempFile = File('${tempDir.path}/$imagePath');

        final DownloadTask downloadTask = ref.writeToFile(tempFile);
        await downloadTask.whenComplete(() async {
          try {
            await SocialShare.shareOptions(
              '¡Mira esta imagen!',
              imagePath: tempFile.path,
            );
          } catch (e) {
            print('Error al compartir la imagen: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al compartir la imagen')),
            );
          }
        });
      }
    } catch (e) {
      print('Error al compartir la imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir la imagen')),
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
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareImage(context),
          ),
        ],
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
