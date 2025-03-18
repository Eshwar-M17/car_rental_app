import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/enhanced_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data()?['documents'] ?? {};
            final docs = userDoc.data()?['verificationDocuments'] ?? [];
            _uploadedDocuments = List<Map<String, String>>.from(
              docs.map((doc) => {
                    'name': doc['name'] ?? '',
                    'url': doc['url'] ?? '',
                  }),
            );
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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

          await _loadUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeDocument(Map<String, String> document) async {
    try {
      setState(() => _isLoading = true);

      final user = _auth.currentUser;
      if (user != null) {
        // Remove from Storage
        if (document['url'] != null) {
          final ref = FirebaseStorage.instance.refFromURL(document['url']!);
          await ref.delete();
        }

        // Remove from Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'verificationDocuments': FieldValue.arrayRemove([document])
        });

        await _loadUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document removed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing document: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit profile functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(UIConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (_userData?['name']?.isNotEmpty == true)
                                ? _userData!['name'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        Text(
                          _userData?['name'] ?? 'No Name',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          _userData?['email'] ?? 'No Email',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: UIConstants.spacingXL),

                  // Document Verification Section
                  GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Identity Verification',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                            if (_uploadedDocuments?.isEmpty ?? true)
                              ElevatedButton.icon(
                                onPressed: _uploadDocument,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: UIConstants.spacingS),
                        if (_uploadedDocuments?.isEmpty ?? true)
                          Text(
                            'Please upload your identification documents for verification',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          )
                        else
                          Column(
                            children: _uploadedDocuments!.map((doc) {
                              return ListTile(
                                leading: const Icon(Icons.description,
                                    color: Colors.white),
                                title: Text(
                                  doc['name'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.white),
                                  onPressed: () => _removeDocument(doc),
                                ),
                                onTap: () {
                                  if (doc['url'] != null) {
                                    // TODO: Implement document preview
                                  }
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: UIConstants.spacingXL),

                  // Statistics Section
                  Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: UIConstants.spacingM),
                  ResponsiveGrid(
                    children: [
                      StatsCard(
                        value: '${_userData?['earnings'] ?? 0}',
                        label: 'Total Earnings',
                        icon: Icons.attach_money,
                        valueColor: Colors.green,
                      ),
                      // Add more statistics as needed
                    ],
                  ),

                  const SizedBox(height: UIConstants.spacingXL),

                  // Settings Section
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: UIConstants.spacingM),
                  InfoCard(
                    title: 'Notification Settings',
                    subtitle: 'Manage your notification preferences',
                    icon: Icons.notifications,
                    onTap: () {
                      // TODO: Implement notification settings
                    },
                  ),
                  const SizedBox(height: UIConstants.spacingM),
                  InfoCard(
                    title: 'Privacy Settings',
                    subtitle: 'Manage your privacy preferences',
                    icon: Icons.privacy_tip,
                    onTap: () {
                      // TODO: Implement privacy settings
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
