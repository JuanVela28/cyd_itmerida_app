import 'package:cyd_itmerida_app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://dhpkvbqluzmrssryscjw.supabase.co',
    publishableKey: 'sb_publishable_WSDlzZOC2gQmGQg9t69_EQ_1tlL-zhQ',
  );
  runApp(MyApp());
}
