import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/sensor_data.dart';
import 'screens/splash_screen.dart';
import 'services/bluetooth_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const AcSmartApp());
}

class AcSmartApp extends StatelessWidget {
  const AcSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorData()),
        ChangeNotifierProxyProvider<SensorData, BluetoothService>(
          create: (ctx) =>
              BluetoothService(sensorData: ctx.read<SensorData>()),
          update: (ctx, sensor, prev) =>
              prev ?? BluetoothService(sensorData: sensor),
        ),
      ],
      child: MaterialApp(
        title: 'AC Smart Control',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
