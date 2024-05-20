import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_optativa/src/Controllers/AvatarController.dart';
import 'package:mi_app_optativa/src/Pages/Home.dart';
import 'package:mi_app_optativa/src/Pages/Log_In.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => AvatarProvider(),
      child: LoginApp(),
    ),
  );
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galeria de Imagenes',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 43, 82, 38),
        hintColor: Color.fromARGB(255, 67, 105, 34),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LogIn(),
        '/login': (context) => LogIn(),
        '/home': (context) => Home(),
      },
    );
  }
}
