import 'main.dart';
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/video_recording_screen.dart'; 
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http; 

class InitialSetupWrapper extends StatefulWidget {
  const InitialSetupWrapper({super.key});
  @override
  State<InitialSetupWrapper> createState() => _InitialSetupWrapperState();
}

class _InitialSetupWrapperState extends State<InitialSetupWrapper> {
  bool _isUserDataSet = false;
  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  /// Checks if user's name and number are stored in SharedPreferences.
  Future<void> _checkUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName');
    final userNumber = prefs.getString('userNumber');
    setState(() {
      _isUserDataSet = userName != null && userNumber != null;
    });
  }

  /// Callback function to be called when initial setup is complete.
  void _onSetupComplete() {
    setState(() {
      _isUserDataSet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isUserDataSet
        ? const MainNavigation()
        : InitialSetupScreen(onSetupComplete: _onSetupComplete);
  }
}

class InitialSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  const InitialSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData() async {
    if (_nameController.text.isEmpty || _numberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and number')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userNumber', _numberController.text);
    widget.onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Sakhi Suraksha'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Let\'s get you set up!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g., Sneha Sharma',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Your Phone Number (for alerts)',
                hintText: 'e.g., 1234567890',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _locations =
      []; // Changed to dynamic for Supabase data
  final List<Map<String, String>> _contacts = [];
  String _userName = '';
  String _userNumber = '';
  String _emergencyMessage = '';
  String _currentCoordinates = 'Getting location...'; // To store coordinates
  String? _profileImagePath; // To store path to profile picture
  Timer? _locationRefreshTimer; // Timer for automatic location refresh

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadContacts();
    _loadLocations(); 
    _loadEmergencyMessage();
    _determineInitialPosition();
    _startLocationRefreshTimer(); 
  }

  @override
  void dispose() {
    _locationRefreshTimer?.cancel(); 
    super.dispose();
  }

  void _startLocationRefreshTimer() {
    _locationRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) {
      _updateAndSaveLocation();
    });
  }

  Future<void> _determineInitialPosition() async {
    Position position = await _getCurrentLocation();
    setState(() {
      _currentCoordinates =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    });
    _updateAndSaveLocation();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _refreshLocation() async {
    setState(() {
      _currentCoordinates = 'Getting location...';
    });
    try {
      Position position = await _getCurrentLocation();
      setState(() {
        _currentCoordinates =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      _updateAndSaveLocation();
    } catch (e) {
      setState(() {
        _currentCoordinates = 'Error: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh location: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateAndSaveLocation() async {
    try {
      Position position = await _getCurrentLocation();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('User not logged in. Cannot save location.');
        return;
      }

      final newLocationData = {
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      await Supabase.instance.client.from('locations').insert(newLocationData);

      await _loadLocations();

      setState(() {
        _currentCoordinates =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      print('Error updating and saving location to Supabase: $e');
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userNumber = prefs.getString('userNumber') ?? '';
      _profileImagePath = prefs.getString(
        'profileImagePath',
      ); 
    });
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList('contacts') ?? [];
    setState(() {
      _contacts.clear();
      _contacts.addAll(
        contacts.map((e) {
          final parts = e.split('|');
          return {
            'name': parts[0],
            'phone': parts[1],
            'isFavorite': parts.length > 2 ? parts[2] : 'false',
          }; 
        }),
      );
    });
  }

  /// Saves the current list of contacts to SharedPreferences.
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = _contacts
        .map((c) => '${c['name']}|${c['phone']}|${c['isFavorite']}')
        .toList();
    await prefs.setStringList('contacts', contacts);
  }

  /// Loads location history from Supabase for the current user.
  Future<void> _loadLocations() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('User not logged in. Cannot load locations.');
        return;
      }

      final response = await Supabase.instance.client
          .from('locations')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false) // Order by latest
          .limit(10); // Limit to last 10 locations

      setState(() {
        _locations.clear();
        _locations.addAll(
          response.map((e) => e as Map<String, dynamic>).toList(),
        );
      });
    } catch (e) {
      print('Error loading locations from Supabase: $e');
    }
  }

  /// Loads the custom emergency message from SharedPreferences.
  Future<void> _loadEmergencyMessage() async {
    final prefs = await SharedPreferences.getInstance();
    _emergencyMessage =
        prefs.getString('emergencyMessage') ??
        '$_userName, their coordinates and I\'m in emergency'; // Default message
  }

  /// Updates the emergency message in SharedPreferences and UI.
  void _updateEmergencyMessage(String newMessage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergencyMessage', newMessage);
    setState(() {
      _emergencyMessage = newMessage;
    });
  }

  /// Updates the user's name in SharedPreferences and UI.
  void _updateUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newName);
    setState(() {
      _userName = newName;
    });
  }

  /// Adds a new contact to the list and saves it.
  ///
  /// Enforces a maximum of 2 favorite contacts.
  void _addContact(String name, String phone, bool isFavorite) {
    setState(() {
      if (isFavorite) {
        final currentFavorites = _contacts
            .where((c) => c['isFavorite'] == 'true')
            .toList();
        if (currentFavorites.length >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only have up to 2 favorite contacts.'),
            ),
          );
          return;
        }
      }
      _contacts.add({
        'name': name,
        'phone': phone,
        'isFavorite': isFavorite.toString(),
      });
    });
    _saveContacts();
  }

  /// Updates the favorite status of a contact.
  ///
  /// Enforces a maximum of 2 favorite contacts.
  void _updateContactFavoriteStatus(int index, bool isFavorite) {
    setState(() {
      if (isFavorite) {
        final currentFavorites = _contacts
            .where((c) => c['isFavorite'] == 'true')
            .toList();
        if (currentFavorites.length >= 2 &&
            _contacts[index]['isFavorite'] == 'false') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only have up to 2 favorite contacts.'),
            ),
          );
          return;
        }
      }
      _contacts[index]['isFavorite'] = isFavorite.toString();
    });
    _saveContacts();
  }

  /// Deletes a contact from the list and saves the updated list.
  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
  }

  /// Updates the profile image path.
  void _updateProfileImage(String? imagePath) {
    setState(() {
      _profileImagePath = imagePath;
    });
  }

  /// Signs out the current user from Supabase and navigates to the AuthScreen.
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      // After signing out, navigate to the AuthScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        contacts: _contacts,
        userName: _userName,
        userNumber: _userNumber,
        emergencyMessage: _emergencyMessage,
        currentCoordinates: _currentCoordinates,
      ),
      ContactsScreen(
        contacts: _contacts,
        onAddContact: _addContact,
        onDeleteContact: _deleteContact,
        onUpdateContactFavoriteStatus: _updateContactFavoriteStatus,
      ),
      const ChatScreen(), // New: Using the separate ChatScreen
      SettingsScreen(
        currentEmergencyMessage: _emergencyMessage,
        onMessageChanged: _updateEmergencyMessage,
        onProfilePictureChanged: _updateProfileImage,
        currentProfileImagePath: _profileImagePath,
        onSignOut: _signOut,
        currentUserName: _userName,
        onNameChanged: _updateUserName,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedIndex == 0
                  ? 'Hi, $_userName!'
                  : _selectedIndex == 1
                      ? 'Emergency Contacts'
                      : _selectedIndex == 2
                          ? 'Chat with AI'
                          : 'Settings',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedIndex == 0) 
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: GestureDetector(
                  onTap: _refreshLocation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentCoordinates,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const VideoRecorderScreen(),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 3; 
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                    : null,
                child: _profileImagePath == null
                    ? const Icon(Icons.person, size: 25, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 16),
          child: GNav(
            gap: 5,
            activeColor: Colors.white,
            iconSize: 23,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            duration: const Duration(milliseconds: 200),
            tabBackgroundColor: Colors.pink.withOpacity(0.8),
            color: Colors.white,
            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.contacts, text: 'Contacts'),
              GButton(icon: Icons.chat, text: 'Chat'),
              GButton(icon: Icons.settings, text: 'Settings'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  final List<Map<String, String>> contacts;
  final String userName;
  final String userNumber;
  final String emergencyMessage;
  final String currentCoordinates;

  const HomeScreen({
    super.key,
    required this.contacts,
    required this.userName,
    required this.userNumber,
    required this.emergencyMessage,
    required this.currentCoordinates,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSendingAlert = false;
  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final double _shakeThreshold = 15.0;
  DateTime? _lastShakeTime;
  int _shakeCount = 0;
  DateTime? _lastShakeTimestamp;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startShakeDetection();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.locationWhenInUse.request();
    await Permission.microphone.request();
    await Permission.camera.request();
    await Permission.sms.request();
    await Permission.phone
        .request();
    await Permission.storage.request(); 
  }

  /// Starts listening to accelerometer events for shake detection.
  ///
  /// If 3 shakes are detected within a short period, it initiates the panic countdown.
  void _startShakeDetection() {
    _accelerometerSubscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen(
          (AccelerometerEvent event) {
            double acceleration =
                (event.x * event.x + event.y * event.y + event.z * event.z);
            if (acceleration > _shakeThreshold * _shakeThreshold) {
              final now = DateTime.now();
              if (_lastShakeTimestamp == null ||
                  now.difference(_lastShakeTimestamp!) >
                      const Duration(seconds: 2)) {
                _shakeCount = 1;
              } else {
                _shakeCount++;
              }
              _lastShakeTimestamp = now;

              if (_shakeCount >= 3 && !_isSendingAlert) {
                _shakeCount = 0;
                _showMessage('Shake detected 3 times! Initiating alert...');
                _startPanicCountdown(); // Start countdown on shake
              }
            }
          },
          onError: (e) {
            print('Error in accelerometer stream: $e');
          },
          cancelOnError: true,
        );
  }

  /// Sends an emergency SMS alert to favorite contacts.
  ///
  /// The message includes the user's name and current coordinates.
  Future<void> _sendEmergencyAlert() async {
    final favoriteContacts = widget.contacts
        .where((c) => c['isFavorite'] == 'true')
        .toList();

    if (favoriteContacts.isEmpty) {
      _showMessage(
        'No favorite emergency contacts added. Please add contacts first and mark them as favorite.',
      );
      setState(() {
        _isSendingAlert = false;
        _countdownSeconds = 3; // Reset countdown
      });
      return;
    }

    String message = widget.emergencyMessage
        .replaceAll('person name', widget.userName)
        .replaceAll(
          'their coordinates',
          'Lat: ${widget.currentCoordinates.split(',')[0]}, Lon: ${widget.currentCoordinates.split(',')[1]}',
        ) // Use current coordinates from MainNavigation
        .replaceAll('I\'m in emergency', 'I\'m in emergency');

    for (var contact in favoriteContacts) {
      String phoneNumber = contact['phone'] ?? '';
      if (phoneNumber.isNotEmpty) {
        if (!phoneNumber.startsWith('+91')) {
          phoneNumber = '+91$phoneNumber';
        }
        final Uri smsLaunchUri = Uri.parse(
          'sms:$phoneNumber?body=${Uri.encodeComponent(message)}',
        );
        try {
          if (await canLaunchUrl(smsLaunchUri)) {
            await launchUrl(smsLaunchUri, mode: LaunchMode.externalApplication);
          } else {
            _showMessage('Could not launch SMS app for ${contact['name']}.');
          }
        } catch (e) {
          _showMessage('Error launching SMS app for ${contact['name']}: $e');
        }
      }
    }

    _showMessage('Emergency SMS sent to favorite contacts!');
    setState(() {
      _isSendingAlert = false;
      _countdownSeconds = 3; // Reset countdown
    });
  }

  /// Starts a 3-second countdown before sending an emergency alert.
  void _startPanicCountdown() {
    if (_isSendingAlert) return;
    setState(() {
      _countdownSeconds = 3; // Set to 3 seconds
      _isSendingAlert = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds == 0) {
        timer.cancel();
        _sendEmergencyAlert();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  /// Cancels the ongoing panic countdown.
  void _cancelPanicCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isSendingAlert = false;
      _countdownSeconds = 3;
    });
    _showMessage('Emergency alert cancelled.');
  }

  /// Displays a snackbar message.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Initiates a direct phone call to the given phone number.
  Future<void> _makeDirectCall(String phoneNumber) async {
    if (!phoneNumber.startsWith('+91')) {
      phoneNumber = '+91$phoneNumber';
    }
    await FlutterPhoneDirectCaller.callNumber(phoneNumber);
  }

  /// Launches Google Maps to search for a given query.
  Future<void> _launchMapsSearch(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/$encodedQuery',
    ); // Changed to a generic Maps search URI
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showMessage('Could not launch maps for "$query".');
    }
  }

  /// Initiates a fake incoming call.
  void _startFakeCall() {
    final favoriteContacts = widget.contacts
        .where((c) => c['isFavorite'] == 'true')
        .toList();

    if (favoriteContacts.isEmpty) {
      _showMessage(
        'No favorite contacts available for a fake call. Please add and mark at least one contact as favorite.',
      );
      return;
    }

    final random = Random();
    final randomContact =
        favoriteContacts[random.nextInt(favoriteContacts.length)];
    final callerName = randomContact['name'] ?? 'Unknown Caller';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FakeCallScreen(callerName: callerName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteContacts = widget.contacts
        .where((c) => c['isFavorite'] == 'true')
        .take(2)
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // SOS Button
            GestureDetector(
              onLongPressStart: (_) => _startPanicCountdown(),
              onLongPressEnd: (_) => _cancelPanicCountdown(),
              onTap: () {
                if (_isSendingAlert && _countdownSeconds > 0) {
                  _cancelPanicCountdown();
                } else if (!_isSendingAlert) {
                  _showMessage('Long press for emergency!');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _isSendingAlert && _countdownSeconds > 0
                      ? Colors.orangeAccent
                      : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red[800]!.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSendingAlert && _countdownSeconds > 0)
                      Text(
                        '$_countdownSeconds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (_isSendingAlert)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    else
                      const Icon(Icons.sos, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      _isSendingAlert && _countdownSeconds > 0
                          ? 'Releasing in...'
                          : (_isSendingAlert
                                ? 'Sending Alert...'
                                : 'Long Press for Emergency'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Emergency Numbers Section
            Column(
              children: [
                Row(
                  children: [
                    _buildNumberCard(
                      context,
                      'Women\'s Helpline',
                      '181',
                      Colors.purple,
                    ),
                    const SizedBox(width: 15),
                    _buildNumberCard(context, 'Emergency', '112', Colors.blue),
                  ],
                ),
                const SizedBox(height: 15),
                if (favoriteContacts.isNotEmpty)
                  Row(
                    children: [
                      _buildNumberCard(
                        context,
                        favoriteContacts[0]['name']!,
                        favoriteContacts[0]['phone']!,
                        Colors.pinkAccent,
                      ),
                      if (favoriteContacts.length > 1) ...[
                        const SizedBox(width: 15),
                        _buildNumberCard(
                          context,
                          favoriteContacts[1]['name']!,
                          favoriteContacts[1]['phone']!,
                          Colors.pinkAccent,
                        ),
                      ],
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Add up to 2 favorite contacts in the Contacts tab.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 40),

            // Fake Call Button
            ElevatedButton.icon(
              onPressed: _startFakeCall,
              icon: const Icon(Icons.phone_missed, color: Colors.white),
              label: const Text('Get Fake Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Near Me Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Near Me',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNearMeIcon(
                      context,
                      Icons.local_police,
                      'Police',
                      'police stations near me',
                    ),
                    _buildNearMeIcon(
                      context,
                      Icons.local_hospital,
                      'Hospitals',
                      'hospitals near me',
                    ),
                    _buildNearMeIcon(
                      context,
                      Icons.bus_alert,
                      'Bus Stations',
                      'bus stations near me',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for emergency numbers or favorite contacts.
  Widget _buildNumberCard(
    BuildContext context,
    String name,
    String number,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _makeDirectCall(number),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Icon(Icons.phone, color: color, size: 30),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  number,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an icon button for searching nearby places on maps.
  Widget _buildNearMeIcon(
    BuildContext context,
    IconData icon,
    String label,
    String searchQuery,
  ) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => _launchMapsSearch(searchQuery),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

// --- Fake Call Screen ---
/// A screen that simulates an incoming phone call.
class FakeCallScreen extends StatefulWidget {
  final String callerName;
  const FakeCallScreen({super.key, required this.callerName});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _isRinging = true;
  bool _isInCall = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  Timer? _ringingTimer;
  AudioPlayer? _audioPlayer; // For simulated ringtone

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  @override
  void dispose() {
    _ringingTimer?.cancel();
    _callTimer?.cancel();
    _audioPlayer?.stop(); // Stop audio if playing
    _audioPlayer?.dispose();
    super.dispose();
  }

  /// Starts the simulated ringing process and plays a ringtone.
  void _startRinging() async {
    setState(() {
      _isRinging = true;
      _isInCall = false;
      _callDurationSeconds = 0;
    });

    _audioPlayer = AudioPlayer();
    // Play ringtone from assets folder (ensure 'assets/ringtone.mp3' exists)
    await _audioPlayer?.play(AssetSource('ringtone.mp3'));

    // Simulate call ringing for 10 seconds, then automatically end
    _ringingTimer = Timer(const Duration(seconds: 10), () {
      if (_isRinging) {
        _endCall(); // Simulate missed call
      }
    });
  }

  /// Answers the simulated call, stops ringing, and starts the call timer.
  void _answerCall() {
    _ringingTimer?.cancel();
    _audioPlayer?.stop(); // Stop ringtone
    setState(() {
      _isRinging = false;
      _isInCall = true;
    });
    _startCallTimer();
  }

  /// Starts a timer to track the duration of the simulated call.
  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationSeconds++;
      });
    });
  }

  /// Ends the simulated call and navigates back.
  void _endCall() {
    _ringingTimer?.cancel();
    _callTimer?.cancel();
    _audioPlayer?.stop();
    setState(() {
      _isRinging = false;
      _isInCall = false;
      _callDurationSeconds = 0;
    });
    Navigator.of(context).pop(); // Go back to previous screen
  }

  /// Formats the call duration into MM:SS string.
  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for call UI
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Column(
              children: [
                const SizedBox(height: 50), // Space from top
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isRinging)
                  const Text(
                    'Incoming Call...',
                    style: TextStyle(color: Colors.white70, fontSize: 20),
                  )
                else if (_isInCall)
                  Text(
                    _formatDuration(_callDurationSeconds),
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  )
                else
                  const Text(
                    'Call Ended',
                    style: TextStyle(color: Colors.redAccent, fontSize: 20),
                  ),
                const SizedBox(height: 60),
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline Button (always present)
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'decline',
                        backgroundColor: Colors.redAccent,
                        onPressed: _endCall,
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  // Answer Button (only if ringing)
                  if (_isRinging)
                    Column(
                      children: [
                        FloatingActionButton(
                          heroTag: 'answer',
                          backgroundColor: Colors.green,
                          onPressed: _answerCall,
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Answer',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Contacts Screen (Local) ---
/// A screen for managing emergency contacts.
class ContactsScreen extends StatefulWidget {
  final List<Map<String, String>> contacts;
  final Function(String, String, bool) onAddContact;
  final Function(int) onDeleteContact;
  final Function(int, bool) onUpdateContactFavoriteStatus;
  const ContactsScreen({
    super.key,
    required this.contacts,
    required this.onAddContact,
    required this.onDeleteContact,
    required this.onUpdateContactFavoriteStatus,
  });
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isFavorite = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Shows a dialog to add a new emergency contact.
  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();
    _isFavorite = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[850],
              title: const Text(
                'Add Emergency Contact',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10), // Added spacing
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Mark as Favorite (Max 2)',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Checkbox(
                        value: _isFavorite,
                        onChanged: (bool? newValue) {
                          setStateInDialog(() {
                            _isFavorite = newValue ?? false;
                          });
                        },
                        activeColor: Colors.pinkAccent,
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Add'),
                  onPressed: () {
                    if (_nameController.text.isNotEmpty &&
                        _phoneController.text.isNotEmpty) {
                      widget.onAddContact(
                        _nameController.text,
                        _phoneController.text,
                        _isFavorite,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.contacts.isEmpty
          ? const Center(
              child: Text(
                'No emergency contacts added yet. Tap + to add one!',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10), // Adjust for app bar
              itemCount: widget.contacts.length,
              itemBuilder: (context, index) {
                final contact = widget.contacts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 15,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Rounded card
                  ),
                  child: ListTile(
                    title: Text(
                      contact['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      contact['phone'] ?? 'No Phone',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            contact['isFavorite'] == 'true'
                                ? Icons.star
                                : Icons.star_border,
                            color: contact['isFavorite'] == 'true'
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          onPressed: () => widget.onUpdateContactFavoriteStatus(
                            index,
                            !(contact['isFavorite'] == 'true'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => widget.onDeleteContact(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
