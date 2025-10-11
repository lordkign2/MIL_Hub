import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../screens/landing_page.dart';
import '../../../../screens/home.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

/// Widget that handles authentication state and navigation
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = sl.get<AuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authBloc.stream,
      initialData: _authBloc.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;

        return switch (state) {
          AuthInitial() || AuthLoading() => const Scaffold(
            body: LoadingIndicator(message: 'Loading...'),
          ),
          AuthAuthenticated() => const HomeScreen(),
          AuthUnauthenticated() => const LandingPage(),
          AuthError() => const LandingPage(),
          AuthActionSuccess() => const HomeScreen(),
        };
      },
    );
  }
}
