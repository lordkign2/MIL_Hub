import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../di/check_injection.dart';
import '../presentation/bloc/check_bloc.dart';
import '../presentation/screens/clean_check_screen.dart';

final checkSl = GetIt.instance;

class NewCheckScreen extends StatelessWidget {
  const NewCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => checkSl<CheckBloc>(),
      child: const CleanCheckScreen(),
    );
  }
}
