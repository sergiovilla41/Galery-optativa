import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CameraFloatingButton extends StatefulWidget {
  @override
  _CameraFloatingButtonState createState() => _CameraFloatingButtonState();
}

class _CameraFloatingButtonState extends State<CameraFloatingButton> {
  late FirebaseStorage _firebaseStorage;

  @override
  void initState() {
    super.initState();
    _firebaseStorage = FirebaseStorage.instance;
  }

  Future<void> _takePicture() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? pickedImage =
          await _picker.pickImage(source: ImageSource.camera);

      if (pickedImage != null) {
        final Uint8List data = await pickedImage.readAsBytes();
        final String fileName = pickedImage.name;

        final UploadTask uploadTask =
            _firebaseStorage.ref('images/$fileName').putData(data);

        await uploadTask.whenComplete(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Foto tomada y subida con éxito')),
          );
        });
      }
    } catch (e) {
      print('Error al tomar la foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar la foto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _takePicture,
      child: Icon(Icons.camera_alt),
    );
  }
}
