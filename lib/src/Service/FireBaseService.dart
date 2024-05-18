import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final _storage = FirebaseStorage.instance;
  Future<List<String>> fetchFileNames(String directory) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(directory);
      final result = await ref.listAll();
      final fileNames = result.items.map((item) => item.name).toList();
      return fileNames;
    } catch (e) {
      print('Error al listar los archivos: $e');
      return [];
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
}
