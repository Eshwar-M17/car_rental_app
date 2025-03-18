import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminAuthWrapper extends StatelessWidget {
  final Widget adminScreen;

  const AdminAuthWrapper({Key? key, required this.adminScreen}) : super(key: key);

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final idTokenResult = await user.getIdTokenResult(true);
    return idTokenResult.claims != null && idTokenResult.claims!['admin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          return adminScreen;
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text("Access Denied"),
            backgroundColor: Colors.red,
          ),
          body: const Center(
            child: Text("You are not authorized to access this page."),
          ),
        );
      },
    );
  }
}
