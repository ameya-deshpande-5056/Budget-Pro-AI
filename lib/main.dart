import 'package:budget_pro_ai_app/presentation/managers/prediction_cubit/prediction_cubit.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_cubit.dart';
import 'package:budget_pro_ai_app/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TransactionCubit()),
        BlocProvider(create: (_) => PredictionCubit()),
      ],
      child: MaterialApp(
        title: 'Budgeting App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(),
      ),
    );
  }
}