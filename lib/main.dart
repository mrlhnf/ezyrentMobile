import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shoppeeclone/login.dart';
import 'package:shoppeeclone/map.dart';
import 'package:shoppeeclone/Student/Homepage.dart';
import 'firebase_options.dart';
import 'package:shoppeeclone/Landlord/Homepage.dart';
import 'package:shoppeeclone/register.dart';
import 'package:shoppeeclone/splashscreen.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/OwnerHomepage': (context) => const HouseRentalHomePage(),
        '/StudentHomepage': (context) => const studenthomepage(),
        '/register': (context) => const RegistrationPage(),
        '/map': (context) => const MapPage(),
      },
    ));
  });
}
