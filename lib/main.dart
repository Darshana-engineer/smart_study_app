import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/welcome_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/role_screen.dart';
import 'material/uploadmaterial_page.dart';
import 'material/view_material_page.dart';
import 'exam/exam_section.dart';
import 'role/admin_panel.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Study App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
      routes: {
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/login': (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String?;
          return LoginScreen(selectedRole: role);
        },
        '/signup': (context) => const SignUpScreen(),
        '/role': (context) {
          final prn = ModalRoute.of(context)!.settings.arguments as String;
          return RoleScreen(prn: prn);
        },
        '/admin': (context) {
          final prn = ModalRoute.of(context)!.settings.arguments as String;
          return AdminPanel(prn: prn);
        },
        '/upload': (context) => const UploadMaterialPage(),
        '/view': (context) => const ViewMaterialPage(subject: 'subject'),
        '/exam': (context) => const ExamSectionPage(subject: 'subject', studentPRN: 'prn', prn: ''),
        '/exam_section': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return ExamSectionPage(
            subject: args['subject'] ?? 'default', 
            studentPRN: args['studentPRN'] ?? '', 
            prn: args['prn'] ?? '',
          );
        },
      },
    );
  }
}
