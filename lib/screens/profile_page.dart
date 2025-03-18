// lib/screens/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:f_logs/f_logs.dart';
import 'package:carrentalapp/core/widgets/common_widgets.dart';
import 'package:carrentalapp/core/theme/app_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  List<Map<String, String>>? _uploadedDocuments;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check network connectivity first
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception(
            "No internet connection. Please check your network and try again.");
      }

      final user = _auth.currentUser;
      FLog.info(text: 'Current user: ${user?.uid}');

      if (user == null) {
        throw Exception("User not logged in. Please log in again.");
      }

      // Check if user exists in Firestore
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        FLog.info(text: 'User document exists: ${userDoc.exists}');

        if (!userDoc.exists) {
          // Create a new user document if it doesn't exist
          final userData = {
            'name': user.displayName ?? 'User',
            'email': user.email ?? 'No Email',
            'earnings': 0,
            'documents': [],
            'verificationDocuments': [],
            'createdAt': FieldValue.serverTimestamp(),
          };

          await _firestore.collection('users').doc(user.uid).set(userData);

          FLog.info(text: 'Created new user document for ${user.uid}');

          setState(() {
            _userData = {
              'name': userData['name'],
              'email': userData['email'],
              'earnings': userData['earnings'],
            };

            _uploadedDocuments = [];
          });
        } else {
          // User document exists, fetch the data
          final data = userDoc.data();
          FLog.info(text: 'User data: $data');

          if (data == null) {
            throw Exception("User data is empty. Please try again.");
          }

          setState(() {
            _userData = {
              'name': data['name'] ?? 'No Name',
              'email': data['email'] ?? 'No Email',
              'earnings': data['earnings'] ?? 0,
            };

            // Handle verification documents
            final verificationDocs = data['verificationDocuments'] ?? [];
            FLog.info(text: 'Verification docs: $verificationDocs');

            _uploadedDocuments = List<Map<String, String>>.from(
              verificationDocs.map((doc) => {
                    'name': doc['name'] ?? '',
                    'url': doc['url'] ?? '',
                  }),
            );
          });
        }
      } catch (firestoreError) {
        FLog.error(text: 'Firestore error: $firestoreError');
        throw Exception("Error accessing user data: $firestoreError");
      }
    } catch (e, stackTrace) {
      FLog.error(
        text: 'Error loading profile: $e',
        stacktrace: stackTrace,
      );

      setState(() {
        _errorMessage = e.toString();
        _userData = null; // Ensure userData is null to show error state
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadUserData,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() => _isLoading = true);
        final user = _auth.currentUser;
        if (user != null) {
          final file = File(result.files.first.path!);
          final fileName = result.files.first.name;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final storagePath =
              'users/${user.uid}/documents/$timestamp-$fileName';

          // Upload file to Firebase Storage
          final uploadTask = _storage.ref(storagePath).putFile(file);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          // Update Firestore with document info
          await _firestore.collection('users').doc(user.uid).update({
            'verificationDocuments': FieldValue.arrayUnion([
              {
                'name': fileName,
                'url': downloadUrl,
                'uploadedAt': timestamp,
              }
            ])
          });

          // Refresh user data
          _loadUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document uploaded successfully')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
      FLog.info(text: 'Error uploading document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Profile',
        showBackButton: false,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? LoadingIndicator(message: 'Loading profile...')
          : _userData == null
              ? EmptyState(
                  message: _errorMessage ?? 'Could not load profile data',
                  icon: Icons.error_outline,
                  actionLabel: 'Retry',
                  onAction: _loadUserData,
                )
              : SingleChildScrollView(
                  padding: AppUI.padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildProfileInfo(),
                      const SizedBox(height: 24),
                      _buildDocumentsSection(),
                    ],
                  ),
                ),
    );
  }

  // Add this method to handle logout confirmation
  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildProfileHeader() {
    final user = _auth.currentUser;
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle with primary color
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              // Inner circle with image
              Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/avatar2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userData?['name'] ?? 'User',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _userData?['email'] ?? 'No Email',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', _userData?['name'] ?? 'No Name'),
            _buildInfoRow('Email', _userData?['email'] ?? 'No Email'),
            _buildInfoRow('Earnings', '₹${_userData?['earnings'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification Documents',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _uploadedDocuments == null || _uploadedDocuments!.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No documents uploaded yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _uploadDocument,
                        icon: Icon(Icons.upload_file),
                        label: Text('Upload Document'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _uploadedDocuments!.length,
                itemBuilder: (context, index) {
                  final doc = _uploadedDocuments![index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading:
                          Icon(Icons.description, color: AppColors.primary),
                      title: Text(doc['name'] ?? 'Document'),
                      trailing: IconButton(
                        icon: Icon(Icons.visibility),
                        onPressed: () {
                          // View document
                        },
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
