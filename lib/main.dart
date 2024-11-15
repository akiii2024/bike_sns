import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'pages/welcomePage.dart';

Future<void> main() async {
  // Flutter Engineを初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 位置情報サービスの初期化と権限チェック
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      locale: const Locale('ja', 'JP'),
      home: const WelcomePage(),
    );
  }
}
