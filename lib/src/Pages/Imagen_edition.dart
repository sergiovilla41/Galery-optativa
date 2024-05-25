import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:mi_app_optativa/src/Pages/Home.dart';

class EditImagePage extends StatefulWidget {
  final String imageUrl;

  EditImagePage({required this.imageUrl});

  @override
  _EditImagePageState createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage> {
  img.Image? _editedImage;
  ImageProvider _imageProvider = MemoryImage(Uint8List(0));
  bool _isLoading = true;
  bool _isProcessing = false;
  img.Image? _originalImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      if (kIsWeb) {
        final response = await http.get(Uri.parse(widget.imageUrl));
        if (response.statusCode == 200) {
          final imageBytes = response.bodyBytes;
          setState(() {
            _imageProvider = MemoryImage(imageBytes);
            _editedImage = img.decodeImage(imageBytes);
            _originalImage = img.decodeImage(imageBytes);
            _isLoading = false;
          });
        } else {
          print('Failed to load image from web');
        }
      } else {
        final ref = firebase_storage.FirebaseStorage.instance
            .refFromURL(widget.imageUrl);
        final imageData = await ref.getData();
        if (imageData != null) {
          setState(() {
            _imageProvider = MemoryImage(imageData);
            _editedImage = img.decodeImage(imageData);
            _originalImage = img.decodeImage(imageData);
            _isLoading = false;
          });
        } else {
          print('Failed to load image from Firebase Storage');
        }
      }
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filterType) {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    img.Image filteredImage;

    switch (filterType) {
      case 'blackWhite':
        filteredImage = img.grayscale(_originalImage!);
        break;
      case 'blur':
        filteredImage = img.gaussianBlur(_originalImage!, radius: 10);
        break;
      case 'blue':
        filteredImage =
            img.colorOffset(_originalImage!, red: -100, green: -100, blue: 150);
        break;
      default:
        filteredImage = _originalImage!;
    }

    final filteredImageBytes = Uint8List.fromList(img.encodeJpg(filteredImage));
    setState(() {
      _editedImage = filteredImage;
      _imageProvider = MemoryImage(filteredImageBytes);
      _isProcessing = false;
    });
  }

  void cropImage(img.Image image, int width, int height) {
    // Verifica que las dimensiones del recorte sean válidas
    if (width <= 0 ||
        height <= 0 ||
        width > image.width ||
        height > image.height) {
      print('Invalid crop dimensions');
      return;
    }

    // Calcula las coordenadas del recorte para centrarlo en la imagen original
    final x = (image.width - width) ~/ 2;
    final y = (image.height - height) ~/ 2;

    // Realiza el recorte
    final croppedImage = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // Actualiza la imagen editada con el recorte
    setState(() {
      _editedImage = croppedImage;
    });
  }

  Future<void> _saveImage(BuildContext context) async {
    if (_editedImage != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('images')
            .child(DateTime.now().toString() + '.jpg');
        final uploadTask =
            ref.putData(Uint8List.fromList(img.encodeJpg(_editedImage!)));
        final taskSnapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await taskSnapshot.ref.getDownloadURL();

        print('Image uploaded to Firebase Storage: $downloadUrl');

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } catch (e) {
        print('Error saving image: $e');
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    } else {
      print('No image to save');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveImage(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Image(
                            image: _imageProvider,
                            fit: BoxFit.contain,
                          ),
                          if (_isProcessing)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.crop),
                          onPressed: () => cropImage(_editedImage!, 200,
                              200), // Por ejemplo, recorte de 200x200 píxeles
                        ),
                        IconButton(
                          icon: Icon(Icons.rotate_right),
                          onPressed: () {
                            setState(() {
                              _editedImage =
                                  img.copyRotate(_editedImage!, angle: 90);
                              _imageProvider = MemoryImage(Uint8List.fromList(
                                  img.encodeJpg(_editedImage!)));
                            });
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.filter),
                          onSelected: _applyFilter,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'blackWhite',
                              child: Text("Blanco y Negro"),
                            ),
                            PopupMenuItem(
                              value: 'blur',
                              child: Text("Difuminar"),
                            ),
                            PopupMenuItem(
                              value: 'blue',
                              child: Text("Filtro Azul"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
