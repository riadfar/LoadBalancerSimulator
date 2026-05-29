import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/network_facade.dart';
import 'features/load_balancer/presentation/bloc/load_balancer_bloc.dart';
import 'features/load_balancer/presentation/screens/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Load Balancing Test Bench',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6826BD),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => LoadBalancerBloc(networkFacade: NetworkFacade()),
        child: const SetupScreen(),
      ),
    );
  }
}
