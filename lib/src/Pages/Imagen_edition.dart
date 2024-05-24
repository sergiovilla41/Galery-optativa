import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:crop/crop.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:mi_app_optativa/src/Pages/Home.dart';
import 'package:path_provider/path_provider.dart';

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
  final CropController _cropController = CropController(aspectRatio: 1.0);
  img.Image? _originalImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      if (kIsWeb) {
        print('Loading image on web...');
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
        print('Loading image on mobile...');
        final imageFile = File(widget.imageUrl);
        if (imageFile.existsSync()) {
          final imageBytes = imageFile.readAsBytesSync();
          setState(() {
            _imageProvider = FileImage(imageFile);
            _editedImage = img.decodeImage(imageBytes);
            _originalImage = img.decodeImage(imageBytes);
            _isLoading = false;
          });
        } else {
          print('File does not exist.');
        }
      }
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cropImage() async {
    if (_editedImage == null) return;

    if (kIsWeb) {
      print('Cropping on web...');
      final croppedArea = _cropController.crop();
      if (croppedArea != null) {
        final croppedImageBytes = Uint8List.fromList(croppedArea as List<int>);
        setState(() {
          _editedImage = img.decodeImage(croppedImageBytes);
          _imageProvider = MemoryImage(croppedImageBytes);
        });
      }
    } else {
      print('Cropping on mobile...');
      File? tempFile;
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(_editedImage!));

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: tempFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Imagen',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final croppedImageBytes = await croppedFile.readAsBytes();
        setState(() {
          _editedImage = img.decodeImage(croppedImageBytes);
          _imageProvider = MemoryImage(croppedImageBytes);
        });
      }
    }
  }

  Future<void> _rotateImage() async {
    if (_editedImage != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final rotatedImage = img.copyRotate(_editedImage!, angle: 90);
        final rotatedImageBytes =
            Uint8List.fromList(img.encodeJpg(rotatedImage));
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          _editedImage = rotatedImage;
          _imageProvider = MemoryImage(rotatedImageBytes);
          _isProcessing = false;
        });
      } catch (e) {
        print('Error rotating image: $e');
        setState(() {
          _isProcessing = false;
        });
      }
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
                        if (!kIsWeb)
                          IconButton(
                            icon: Icon(Icons.crop),
                            onPressed: _cropImage,
                          ),
                        if (kIsWeb)
                          IconButton(
                            icon: Icon(Icons.crop),
                            onPressed: _cropImage,
                          ),
                        IconButton(
                          icon: Icon(Icons.rotate_right),
                          onPressed: _rotateImage,
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
