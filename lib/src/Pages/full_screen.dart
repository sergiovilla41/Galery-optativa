import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditableImage extends StatelessWidget {
  final VoidCallback? onImageEdited;

  const EditableImage({Key? key, this.onImageEdited}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final imagePicker = ImagePicker();
        final pickedImage =
            await imagePicker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null && onImageEdited != null) {
          // Aquí puedes realizar acciones después de que el usuario haya seleccionado una imagen
          onImageEdited!();
        }
      },
      child: Icon(Icons
          .image), // Puedes cambiar este ícono por una vista previa de la imagen seleccionada si lo deseas
    );
  }
}

class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Imagen Completa'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error);
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes agregar la lógica para editar la imagen
                // Puedes abrir un editor de imágenes aquí
              },
              child: Text('Editar Imagen'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Aplicación'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EditableImage(
              onImageEdited: () {
                // Aquí puedes manejar la lógica después de que el usuario haya seleccionado y editado una imagen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullImageScreen(
                      imageUrl: 'URL_DE_LA_IMAGEN_AQUI',
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text('Toque para editar la imagen'),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
