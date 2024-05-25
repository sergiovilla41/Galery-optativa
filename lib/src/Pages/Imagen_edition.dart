import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_cropper/image_cropper.dart';
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

  Future<void> _cropImage() async {
    try {
      if (_editedImage != null) {
        if (kIsWeb) {
          final croppedFile = await _cropImageWeb();
          if (croppedFile != null) {
            final reader = html.FileReader();
            reader.readAsDataUrl(croppedFile);
            reader.onLoadEnd.listen((event) {
              final imageDataUrl = reader.result as String?;
              if (imageDataUrl != null) {
                final base64Image = imageDataUrl.replaceFirst(
                    RegExp(r'data:image/[^;]+;base64,'), '');
                final croppedImageBytes = base64.decode(base64Image);
                setState(() {
                  _editedImage = img.decodeImage(croppedImageBytes);
                  _imageProvider = MemoryImage(croppedImageBytes);
                });
              }
            });
          }
        } else {
          // Rest of the code for non-web platforms
        }
      }
    } catch (e) {
      print('Error cropping image: $e');
    }
  }

  Future<html.File?> _cropImageWeb() async {
    final completer = Completer<html.File?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      if (input.files!.isNotEmpty) {
        completer.complete(input.files!.first);
      } else {
        completer.complete(null);
      }
    });
    return completer.future;
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
                          onPressed: _cropImage,
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
