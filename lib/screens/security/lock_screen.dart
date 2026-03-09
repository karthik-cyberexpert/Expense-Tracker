import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:permission_handler/permission_handler.dart';
import '../../services/security_service.dart';
import '../../utils/permission_helper.dart';

class LockScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;
  final String lockType; // 'pin', 'pattern', 'password'
  final VoidCallback? onSuccess;

  const LockScreen({
    super.key, 
    this.isOnboarding = false, 
    this.lockType = 'pin',
    this.onSuccess
  });

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _input = "";
  String _confirmInput = "";
  bool _isConfirming = false;
  String _message = "";
  int _remainingSeconds = 0;
  Timer? _timer;
  String _activeType = 'pin';

  // Pattern specific
  List<int> _patternPoints = [];
  
  // Password specific
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initLock();
  }

  void _initLock() async {
    final security = ref.read(securityServiceProvider);
    _activeType = widget.isOnboarding ? widget.lockType : (await security.getLockType() ?? 'pin');
    
    _message = widget.isOnboarding ? 'Setup ${_activeType.toUpperCase()}' : 'Enter ${_activeType.toUpperCase()}';
    
    _checkLockStatus();
    if (!widget.isOnboarding) {
      _authenticateWithBiometrics();
    }
  }

  void _checkLockStatus() async {
    final security = ref.read(securityServiceProvider);
    final remaining = await security.getLockTimeRemaining();
    if (remaining > 0) {
      setState(() {
        _remainingSeconds = remaining;
        _message = 'Try again in $_remainingSeconds s';
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _message = 'Try again in $_remainingSeconds s';
        } else {
          _message = _isConfirming ? 'Confirm ${_activeType.toUpperCase()}' : 'Enter ${_activeType.toUpperCase()}';
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    final security = ref.read(securityServiceProvider);
    if (await security.useBiometric()) {
      final auth = LocalAuthentication();
      try {
        final canCheck = await auth.canCheckBiometrics;
        final isSupported = await auth.isDeviceSupported();
        
        if (canCheck && isSupported) {
          final didAuthenticate = await auth.authenticate(
            localizedReason: 'Authenticate to unlock Expense Tracker',
            options: const AuthenticationOptions(
              biometricOnly: true, // Force biometrics
              stickyAuth: true,
              useErrorDialogs: true,
            ),
          );
          if (didAuthenticate) {
            _onVerified();
          }
        }
      } catch (e) {
        debugPrint('Biometric Error: $e');
      }
    }
  }

  void _onVerified() async {
    await ref.read(securityServiceProvider).resetWrongAttempts();
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _handleWrongAttempt() async {
    final security = ref.read(securityServiceProvider);
    await security.incrementWrongAttempts();
    
    final attempts = await security.getWrongAttempts();
    final threshold = await security.getIntruderAttemptsThreshold();
    final useIntruder = await security.useIntruderSelfie();

    if (useIntruder && attempts >= threshold) {
      _captureIntruder();
    }

    final remaining = await security.getLockTimeRemaining();
    setState(() {
      _input = "";
      _patternPoints.clear();
      _passwordController.clear();
      
      if (remaining > 0) {
        _remainingSeconds = remaining;
        _message = 'Try again in $_remainingSeconds s';
        _startTimer();
      } else {
        _message = 'Wrong ${_activeType.toUpperCase()}. Try again';
      }
    });
  }

  Future<void> _captureIntruder() async {
    try {
      // Check and request permission if not already granted
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      final image = await controller.takePicture();
      
      final directory = await getApplicationDocumentsDirectory();
      final intruderDir = Directory(join(directory.path, 'intruders'));
      if (!await intruderDir.exists()) {
        await intruderDir.create(recursive: true);
      }
      
      final fileName = 'intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(image.path).copy(join(intruderDir.path, fileName));
      
      await controller.dispose();
    } catch (e) {
      debugPrint("Failed to capture intruder: $e");
    }
  }

  bool _forceSetNewPinMode = false;

  void _submitInput(String val) async {
    final security = ref.read(securityServiceProvider);
    
    if (widget.isOnboarding || _isConfirming || _forceSetNewPinMode) {
      if (!_isConfirming) {
        setState(() {
          _confirmInput = val;
          _input = "";
          _passwordController.clear();
          _patternPoints.clear();
          _isConfirming = true;
          _message = _forceSetNewPinMode ? 'Confirm new ${_activeType.toUpperCase()}' : 'Confirm ${_activeType.toUpperCase()}';
        });
      } else {
        if (val == _confirmInput) {
          await security.setLock(_activeType, val);
          if (_forceSetNewPinMode) {
             setState(() => _forceSetNewPinMode = false);
          }
          _onVerified();
        } else {
          setState(() {
            _input = "";
            _passwordController.clear();
            _patternPoints.clear();
            _message = '${_activeType.toUpperCase()}s don\'t match. Try again';
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            setState(() {
              _isConfirming = false;
              _message = _forceSetNewPinMode ? 'Set new ${_activeType.toUpperCase()}' : (widget.isOnboarding ? 'Setup ${_activeType.toUpperCase()}' : 'Confirm ${_activeType.toUpperCase()}');
              _confirmInput = "";
              if (_forceSetNewPinMode) _isConfirming = false; // special reset for forgot password
            });
          });
        }
      }
    } else {
      final savedVal = await security.getLockValue();
      if (val == savedVal) {
        _onVerified();
      } else {
        _handleWrongAttempt();
      }
    }
  }

  void _showForgotDialog() async {
    final security = ref.read(securityServiceProvider);
    final question = await security.getSecurityQuestion();
    
    if (question == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No security question configured. Please reset app data.')));
      return;
    }

    final answerController = TextEditingController();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security Question:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(question, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(hintText: 'Your Answer'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final correct = await security.verifySecurityAnswer(answerController.text);
              if (correct) {
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _isConfirming = false;
                  _confirmInput = "";
                  _input = "";
                  _message = 'Enter new ${_activeType.toUpperCase()}';
                  _remainingSeconds = 0;
                  _forceSetNewPinMode = true; 
                });
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong Answer')));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isOnboarding ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: _remainingSeconds > 0 ? Colors.red : Colors.black
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStatusIndicator(),
                ],
              ),
              _buildLockUI(),
              if (!widget.isOnboarding && _remainingSeconds == 0)
                TextButton(
                  onPressed: _showForgotDialog,
                  child: Text('Forgot Password?', style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_activeType != 'pin') return const SizedBox(height: 16);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14, height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _input.length ? const Color(0xFF6366F1) : Colors.grey[200],
          ),
        );
      }),
    );
  }

  Widget _buildLockUI() {
    if (_remainingSeconds > 0) return const SizedBox();
    
    switch (_activeType) {
      case 'pin': return _buildPinUI();
      case 'password': return _buildPasswordUI();
      case 'pattern': return _buildPatternUI();
      default: return _buildPinUI();
    }
  }

  Widget _buildPinUI() {
    return _buildNumericKeypad();
  }

  Widget _buildNumericKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var j = 1; j <= 3; j++) _buildKey(i * 3 + j),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              _buildKey(0),
              _buildDeleteKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(int number) {
    return GestureDetector(
      onTap: () {
        if (_input.length < 4) {
          setState(() => _input += number.toString());
          if (_input.length == 4) _submitInput(_input);
        }
      },
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
        child: Center(child: Text(number.toString(), style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return GestureDetector(
      onTap: () { if (_input.isNotEmpty) setState(() => _input = _input.substring(0, _input.length - 1)); },
      child: const SizedBox(width: 60, height: 60, child: Center(child: Icon(Icons.backspace_outlined))),
    );
  }

  // --- PASSWORD UI ---
  Widget _buildPasswordUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: Colors.grey[300]),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _submitInput(_passwordController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- PATTERN UI ---
  Widget _buildPatternUI() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 40, crossAxisSpacing: 40),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isSelected = _patternPoints.contains(index);
                return GestureDetector(
                  onTap: () {
                     setState(() {
                       if (!_patternPoints.contains(index)) {
                         _patternPoints.add(index);
                       }
                     });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200],
                      border: isSelected ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 8) : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_patternPoints.length >= 4)
          ElevatedButton(
            onPressed: () => _submitInput(_patternPoints.join()),
            child: const Text('Submit Pattern'),
          ),
        TextButton(onPressed: () => setState(() => _patternPoints.clear()), child: const Text('Clear')),
      ],
    );
  }
}
