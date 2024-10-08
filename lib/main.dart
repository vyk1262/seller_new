import 'package:flutter/material.dart';
import 'package:trade_seller/seller_login.dart';
import 'package:trade_seller/constants/colors.dart';
import 'package:trade_seller/seller_home.dart';
import 'package:trade_seller/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trade Seller by FarmOS',
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // useMaterial3: true,
        // primaryColor: AppColors.scaffoldBackground,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        // appBarTheme: const AppBarTheme(
        //   color: AppColors.scaffoldBackground,
        //   titleTextStyle: TextStyle(color: Colors.white),
        // ),
        buttonTheme: const ButtonThemeData(
          buttonColor: AppColors.simpleButton,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.elevatedButton,
            foregroundColor: Colors.white,
          ),
        ),
        // floatingActionButtonTheme: const FloatingActionButtonThemeData(
        //   backgroundColor: AppColors.scaffoldBackground,
        // ),
        // bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        //   backgroundColor: AppColors.scaffoldBackground,
        // ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // Show splash screen initially
        '/auth': (context) =>
            AuthScreen(), // Route to the authentication screen
        '/home': (context) => MyHomePage(), // Route to the home screen
      },
    );
  }
}
