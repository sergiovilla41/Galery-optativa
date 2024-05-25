import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mi_app_optativa/src/Pages/Home.dart';
import 'package:mi_app_optativa/src/Service/FireBaseService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileListScreen extends StatefulWidget {
  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  List<String> fileNames = [];
  List<String> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    fetchFileNames();
  }

  Future<void> fetchFileNames() async {
    final directory = "images";
    final result = await _storageService.fetchFileNames(directory);

    setState(() {
      fileNames = result;
    });
  }

  Future<void> deleteSelectedFiles() async {
    try {
      await _storageService.deleteFiles(selectedFiles);
      setState(() {
        fileNames.removeWhere((fileName) => selectedFiles.contains(fileName));
        selectedFiles.clear();
      });
      fetchFileNames();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } catch (e) {
      print('Error al eliminar archivos seleccionados: $e');
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
    } catch (e) {
      print('Error al descargar archivos seleccionados: $e');
    }
  }

  Future<void> shareSelectedFiles(List<String> fileNames) async {
    try {
      List<String> filePaths = [];
      for (String fileName in fileNames) {
        final ref = FirebaseStorage.instance.ref().child('images/$fileName');
        final Directory tempDir = await getTemporaryDirectory();
        final File tempFile = File('${tempDir.path}/$fileName');
        await ref.writeToFile(tempFile);
        filePaths.add(tempFile.path);
      }
      await Share.shareFiles(filePaths);
    } catch (e) {
      print('Error al compartir archivos seleccionados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listado de Archivos'),
        actions: [
          if (selectedFiles.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: deleteSelectedFiles,
            ),
          if (selectedFiles.isNotEmpty)
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () {
                downloadSelectedFiles(selectedFiles);
              },
            ),
          if (selectedFiles.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                shareSelectedFiles(selectedFiles);
              },
            ),
        ],
      ),
      body: fileNames.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: fileNames.length,
              itemBuilder: (BuildContext context, int index) {
                final fileName = fileNames[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedFiles.contains(fileName)) {
                        selectedFiles.remove(fileName);
                      } else {
                        selectedFiles.add(fileName);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      FutureBuilder<String>(
                        future: _storageService.getImageURL('images/$fileName'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Icon(Icons.error));
                          } else {
                            final imageUrl = snapshot.data!;
                            return imageUrl.isEmpty
                                ? Center(child: Icon(Icons.error_outline))
                                : Image.network(
                                    imageUrl,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.error);
                                    },
                                  );
                          }
                        },
                      ),
                      if (selectedFiles.contains(fileName))
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(Icons.check_circle, color: Colors.green),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
