import 'package:flutter/material.dart';
import 'package:mi_app_optativa/src/Pages/Imagen_edition.dart';

class EditImageButton extends StatelessWidget {
  final String imageUrl;
  final List<String> imagePaths;
  final int initialIndex;

  const EditImageButton({
    Key? key,
    required this.imageUrl,
    required this.imagePaths,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditImagePage(
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Icon(Icons.edit),
    );
  }
}
