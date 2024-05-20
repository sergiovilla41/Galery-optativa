import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
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
  ImageProvider _imageProvider =
      MemoryImage(Uint8List(0)); // Initialize with a default empty image
  bool _isLoading = true;
  bool _isProcessing = false;

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
            _isLoading = false;
          });
        } else {
          print('Failed to load image from web');
        }
      } else {
        final imageFile = File(widget.imageUrl);
        if (imageFile.existsSync()) {
          final imageBytes = imageFile.readAsBytesSync();
          setState(() {
            _imageProvider = FileImage(imageFile);
            _editedImage = img.decodeImage(imageBytes);
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
    ImageCropper imageCropper =
        ImageCropper(); // Create an instance of ImageCropper
    CroppedFile? croppedFile = await imageCropper.cropImage(
      cropStyle: CropStyle.rectangle,
      sourcePath: widget.imageUrl,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [],
    );

    if (croppedFile != null) {
      final croppedImageBytes = await croppedFile.readAsBytes();
      final croppedImage = img.decodeImage(croppedImageBytes);
      setState(() {
        _editedImage = croppedImage;
        _imageProvider = MemoryImage(croppedImageBytes);
      });
    }
  }

  Future<void> _rotateImage() async {
    if (_editedImage != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final rotatedImage = img.copyRotate(_editedImage!, 90);
        final rotatedImageBytes =
            Uint8List.fromList(img.encodeJpg(rotatedImage));
        await Future.delayed(Duration(
            seconds: 1)); // Simulando un retraso de 1 segundo para la rotación
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

  void _applyFilter() {
    if (_editedImage != null) {
      setState(() {
        _isProcessing = true;
      });

      final filteredImage = img.grayscale(_editedImage!);
      setState(() {
        _editedImage = filteredImage;
        final filteredImageBytes =
            Uint8List.fromList(img.encodeJpg(filteredImage));
        _imageProvider = MemoryImage(filteredImageBytes);
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveImage(BuildContext context) async {
    if (_editedImage != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('images')
            .child(DateTime.now().toString() + '.jpg');
        final firebase_storage.UploadTask uploadTask =
            ref.putData(Uint8List.fromList(img.encodeJpg(_editedImage!)));
        final firebase_storage.TaskSnapshot taskSnapshot =
            await uploadTask.whenComplete(() => null);
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        print('Image uploaded to Firebase Storage: $downloadUrl');

        // Navigate back to the home page after saving the image
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
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Icon(Icons.error));
                            },
                          ),
                          if (_isProcessing)
                            Container(
                              color: Colors.black.withOpacity(
                                  0.5), // Fondo oscuro semitransparente
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
                          onPressed: _rotateImage,
                        ),
                        IconButton(
                          icon: Icon(Icons.filter),
                          onPressed: _applyFilter,
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
