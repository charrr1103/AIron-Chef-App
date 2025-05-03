import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:airon_chef/pages/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './signup_page.dart';
import './login_page.dart'; // Import the login page

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  String _email = '';
  String? _profilePicturePath;
  String? _userId;
  String _fullName = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BehaviorSubject<Map<String, dynamic>> _userProfileSubject =
  BehaviorSubject<Map<String, dynamic>>.seeded({});

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _userProfileSubject.close();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_userId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
          userDoc.data() as Map<String, dynamic>;
          _userProfileSubject.add(userData);
          setState(() {
            _email = userData['email'] ?? '';
            _fullName = userData['fullName'] ?? '';
            _profilePicturePath = userData['profilePicturePath'];
          });
        } else {
          _userProfileSubject.add({});
          setState(() {
            _email = '';
            _fullName = '';
            _profilePicturePath = null;
          });
        }
      } catch (e) {
        print("Error loading profile data: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load profile data.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        _userProfileSubject.add({});
        setState(() {
          _email = '';
          _fullName = '';
          _profilePicturePath = null;
        });
      }
    } else {
      _userProfileSubject.add({});
      setState(() {
        _email = '';
        _fullName = '';
        _profilePicturePath = null;
      });
    }
  }

  void _navigateToEditProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(
            email: _email,
            profilePicturePath: _profilePicturePath,
            fullName: _fullName,
            onProfilePictureChanged: (String? newPath) {
              setState(() {
                _profilePicturePath = newPath;
              });
            },
          ),
        ),
      );

      if (result != null && result is Map<String, String?>) {
        setState(() {
          _email = result['email'] ?? _email;
          _profilePicturePath = result['profilePicturePath'];
          _fullName = result['fullName'] ?? _fullName;
        });
        _userProfileSubject.add({
          'email': _email,
          'fullName': _fullName,
          'profilePicturePath': _profilePicturePath,
        });
        _saveProfileData();
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to edit your profile.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveProfileData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userId = user.uid;
      try {
        await _firestore.collection('users').doc(userId).update({
          'email': _email,
          'fullName': _fullName,
          'profilePicturePath': _profilePicturePath,
        });
        _userProfileSubject.add({
          'email': _email,
          'fullName': _fullName,
          'profilePicturePath': _profilePicturePath,
        });
      } catch (e) {
        print("Error saving profile data: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save profile data.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
    print('Notifications toggled: $_notificationsEnabled');
  }

  void _navigateToAbout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Airon Chef'),
          content: const Text(
            'Airon Chef is your personal cooking assistant app that helps you discover and create delicious recipes. '
                'Version 1.0.0\n\n'
                '© 2025 Airon Chef Team',
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToSignUp() {
    if (_auth.currentUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already signed in!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SignUpPage()),
          (Route<dynamic> route) => false,
    );
  }

  void _navigateToLogin() {
    if (_auth.currentUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already signed in!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _signOut() async {
    try {
      await _auth.signOut();
      // Clear the login state from SharedPreferences on logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error signing out: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign out. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF004AAD),
              Color(0xFFCB6CE6),
              Color(0xFFFFFFFF)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: StreamBuilder<Map<String, dynamic>>(
                    stream: _userProfileSubject.stream,
                    initialData: _userProfileSubject.value,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final userData = snapshot.data!;
                        final String? profilePicturePath =
                        userData['profilePicturePath'];
                        final String fullName = userData['fullName'] ?? '';
                        return Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey,
                                  backgroundImage: profilePicturePath != null
                                      ? FileImage(File(profilePicturePath))
                                  as ImageProvider<Object>?
                                      : null,
                                  child: profilePicturePath == null
                                      ? const Icon(Icons.person,
                                      size: 60, color: Colors.white)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _navigateToEditProfile,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF19006D),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 25.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            ElevatedButton(
                              onPressed: _navigateToEditProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF19006D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 8.0,
                                ),
                              ),
                              child: const Text('Edit Profile'),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
              ),
              const SizedBox(height: 24.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: const Text(
                        'General Settings',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('Language'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Language button remains but does nothing
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Language selection is not implemented'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications_none),
                            title: const Text('Notifications'),
                            value: _notificationsEnabled,
                            onChanged: (bool value) {
                              _toggleNotifications();
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.question_mark),
                            title: const Text('About'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _navigateToAbout,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.person_add),
                            title: const Text('Sign Up'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _navigateToSignUp,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.login),
                            title: const Text('Login'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _navigateToLogin,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Logout'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _signOut,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String email;
  final String? profilePicturePath;
  final Function(String?) onProfilePictureChanged;
  final String fullName;

  const EditProfilePage({
    Key? key,
    required this.email,
    required this.profilePicturePath,
    required this.onProfilePictureChanged,
    required this.fullName,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _emailController;
  String? _profilePicturePath;
  final ImagePicker _picker = ImagePicker();
  String? _userId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _fullNameController;
  final BehaviorSubject<Map<String, dynamic>> _userProfileSubject =
  BehaviorSubject<Map<String, dynamic>>.seeded({});

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _profilePicturePath = widget.profilePicturePath;
    _fullNameController = TextEditingController(text: widget.fullName);
    _getUserID();
  }

  Future<void> _getUserID() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _userProfileSubject.close();
    super.dispose();
  }

  void _saveChanges() async {
    if (_userId != null) {
      try {
        await _firestore.collection('users').doc(_userId).update({
          'email': _emailController.text,
          'fullName': _fullNameController.text,
          'profilePicturePath': _profilePicturePath,
        });
        Map<String, String?> result = {
          'email': _emailController.text,
          'profilePicturePath': _profilePicturePath,
          'fullName': _fullNameController.text,
        };
        _userProfileSubject.add({
          'email': _emailController.text,
          'fullName': _fullNameController.text,
          'profilePicturePath': _profilePicturePath,
        });
        Navigator.of(context).pop(result);
      } catch (e) {
        print("Error saving changes: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save changes.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profilePicturePath = pickedFile.path;
        });
        widget.onProfilePictureChanged(_profilePicturePath);
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print("Error picking image");
          if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              // Add some padding at the bottom to avoid navigation bar
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
      // This ensures the bottom sheet appears above the navigation bar
      isScrollControlled: true,
      // This gives some elevation to make it stand out
      elevation: 10,
      // This adds some shape to the bottom sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF004AAD),
                Color(0xFFCB6CE6)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: _showImageSourceBottomSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey,
                      backgroundImage: _profilePicturePath != null
                          ? FileImage(File(_profilePicturePath!))
                      as ImageProvider<Object>?
                          : null,
                      child: _profilePicturePath == null
                          ? const Icon(Icons.person,
                          size: 80, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF19006D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19006D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
