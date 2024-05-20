import 'package:flutter/material.dart';
import 'package:mi_app_optativa/src/Pages/Imagen_edition.dart';

class FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final List<String> imagePaths;
  final int initialIndex;

  FullImageScreen({
    required this.imageUrl,
    required this.imagePaths,
    required this.initialIndex,
  });

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
        ],
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
