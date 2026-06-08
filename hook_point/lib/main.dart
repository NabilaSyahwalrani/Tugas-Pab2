import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'firebase_options.dart';
import 'services/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  timeago.setLocaleMessages('id', timeago.IdMessages());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'HookPoint',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
          useMaterial3: false,
          primarySwatch: Colors.blue,
      ),

      darkTheme: ThemeData.dark(),

      themeMode: ThemeMode.light,


      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phishing, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('HookPoint...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}
