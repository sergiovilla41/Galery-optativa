import 'dart:io';
import 'dart:html' as html;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageService {
  final _storage = FirebaseStorage.instance;

  Future<List<String>> fetchFileNames(String directory) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(directory);
      final result = await ref.listAll();

      // Obtener nombres de archivo con metadatos
      final fileNamesWithMetadata =
          await Future.wait(result.items.map((item) async {
        final metadata = await item.getMetadata();
        final uploadedAt = metadata.customMetadata?['uploadedAt'];
        if (uploadedAt != null) {
          return {
            'name': item.name,
            'uploadedAt': DateTime.parse(uploadedAt),
          };
        } else {
          // Si no hay fecha de carga, asignar una fecha predeterminada
          return {
            'name': item.name,
            'uploadedAt': DateTime
                .now(), // O cualquier otra fecha predeterminada que prefieras
          };
        }
      }));

      // Ordenar los nombres de archivo por fecha de carga (más reciente primero)
      fileNamesWithMetadata.sort((a, b) =>
          (b['uploadedAt'] as DateTime).compareTo(a['uploadedAt'] as DateTime));

      // Extraer solo los nombres de archivo
      final sortedFileNames =
          fileNamesWithMetadata.map((item) => item['name'] as String).toList();

      return sortedFileNames;
    } catch (e) {
      print('Error al listar los archivos: $e');
      return []; // Devuelve una lista vacía en caso de error
    }
  }

  Future<String> getImageURL(String imagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(imagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error al obtener la URL de la imagen: $e');
      return '';
    }
  }

  Future<void> uploadImage(String filePath, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('images/$fileName');
      await ref.putFile(File(filePath));
    } catch (e) {
      print('Error al subir la imagen: $e');
    }
  }

  Future<void> uploadFile(File file, String path) async {
    try {
      await _storage.ref().child(path).putFile(file);
    } catch (e) {
      print('Error uploading file: $e');
      throw e; // Propaga el error para que pueda ser manejado en el widget que llama a este método
    }
  }

  Future<void> deleteFiles(List<String> fileNames) async {
    try {
      await Future.wait(fileNames.map((fileName) async {
        final ref = FirebaseStorage.instance.ref().child('images/$fileName');
        await ref.delete();
      }));
    } catch (e) {
      print('Error al eliminar archivos: $e');
      throw e;
    }
  }

  Future<void> downloadSelectedFiles(List<String> fileNames) async {
    try {
      final Directory? downloadDirectory = await getExternalStorageDirectory();
      for (String fileName in fileNames) {
        final ref = FirebaseStorage.instance.ref().child('images/$fileName');
        final File downloadFile = File('${downloadDirectory!.path}/$fileName');
        await ref.writeToFile(downloadFile);
      }
      // Mostrar un mensaje de éxito al usuario
    } catch (e) {
      print('Error al descargar archivos seleccionados: $e');
      // Mostrar un mensaje de error al usuario
    }
  }

  Future<void> downloadFileToDirectory(
      String fileName, String directoryPath) async {
    try {
      print(
          'Starting download for file: $fileName to directory: $directoryPath');
      final ref = _storage.ref().child('images/$fileName');
      final File downloadFile = File('$directoryPath/$fileName');

      if (kIsWeb) {
        print('Running on web platform');
        final url = await ref.getDownloadURL();
        print('Download URL: $url');
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        print('File downloaded via web');
      } else {
        await ref.writeToFile(downloadFile);
        print('File downloaded to ${downloadFile.path}');
      }
    } catch (e) {
      print('Error al descargar archivo: $e');
    }
  }
}
