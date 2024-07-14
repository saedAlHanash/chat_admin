import 'package:fitness_admin_chat/features/chat/userss_bloc/users_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<UsersCubit, UsersInitial>(
        builder: (context, state) {
          return Placeholder();
        },
      ),
    );
  }
}
