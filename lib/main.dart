import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/reader_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MonsterReaderApp());
}

class MonsterReaderApp extends StatelessWidget {
  const MonsterReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReaderProvider(),
      child: MaterialApp(
        title: 'Monster Reader',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF4444),
            surface: Color(0xFF1A1A1A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
