import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_localizations.dart';
import '../utils/theme_provider.dart';
import 'personal_info_screen.dart';
import '../passenger/passenger_home_screen.dart';
import 'dart:async';
class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const VerificationScreen({Key? key, required this.phoneNumber}) : super(key: key);
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}
class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _textFocusNodes = List.generate(6, (_) => FocusNode());
  final List<FocusNode> _listenerFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 30;
  Timer? _timer;
  bool _canResend = false;
  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(() {
        setState(() {});
      });
    }
  }
  void _startResendTimer() {
    setState(() {
      _resendSeconds = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 1) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        setState(() {
          _resendSeconds = 0;
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }
  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _textFocusNodes) {
      f.dispose();
    }
    for (final f in _listenerFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }
  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _textFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _textFocusNodes[index - 1].requestFocus();
    }
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }
  Future<void> _verifyCode() async {
    if (_controllers.any((c) => c.text.isEmpty)) return;
    setState(() => _isLoading = true);
    final code = _controllers.map((c) => c.text).join();
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: code,
        type: OtpType.sms,
      );
      if (response.user != null) {
        final user = response.user!;
        final userRow = await Supabase.instance.client
            .from('passenger')
            .select()
            .eq('uid', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (userRow != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PassengerHomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code invalide'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _resendCode() async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: widget.phoneNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code renvoyé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final phoneMasked = widget.phoneNumber.length > 4
        ? widget.phoneNumber.replaceRange(widget.phoneNumber.length - 6, widget.phoneNumber.length - 2, '****')
        : widget.phoneNumber;
    return Scaffold(
      backgroundColor: RydyColors.darkBg,
      appBar: AppBar(
        backgroundColor: RydyColors.darkBg,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: RydyColors.darkBg,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: RydyColors.textColor),
              onPressed: () => Navigator.pop(context),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
          ),
        ),
        toolbarHeight: 56,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Text(
                  localizations.translate('enter_code'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: RydyColors.textColor),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  localizations.translate('sms_sent_to').replaceAll('{phone}', phoneMasked),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: RydyColors.subText),
                ),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final margin = 7.0;
                  final minBox = 40.0;
                  final maxBox = 56.0;
                  double boxWidth = ((totalWidth - (margin * 2 * 6)) / 6).clamp(minBox, maxBox);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final isFocused = _textFocusNodes[i].hasFocus;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        width: boxWidth,
                        height: boxWidth,
                        decoration: BoxDecoration(
                          color: RydyColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused ? RydyColors.textColor : RydyColors.textColor.withOpacity(0.18),
                            width: isFocused ? 2.2 : 1.2,
                          ),
                        ),
                        child: RawKeyboardListener(
                          focusNode: _listenerFocusNodes[i],
                          onKey: (event) {
                            if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                              if (_controllers[i].text.isEmpty && i > 0) {
                                _textFocusNodes[i - 1].requestFocus();
                                _controllers[i - 1].clear();
                              }
                            }
                          },
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _textFocusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(fontSize: boxWidth * 0.38, fontWeight: FontWeight.bold, color: RydyColors.textColor, letterSpacing: 2),
                            decoration: InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.only(bottom: 8, top: 2),
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) {
                              if (v.length > 1) {
                                final chars = v.split("");
                                for (int j = 0; j < chars.length && (i + j) < 6; j++) {
                                  _controllers[i + j].text = chars[j];
                                }
                                if ((i + chars.length - 1) < 5) {
                                  _textFocusNodes[i + chars.length].requestFocus();
                                } else {
                                  _textFocusNodes[5].unfocus();
                                }
                              } else {
                                if (v.isNotEmpty && i < 5) {
                                  _textFocusNodes[i + 1].requestFocus();
                                }
                              }
                              if (_controllers.every((c) => c.text.isNotEmpty)) {
                                _verifyCode();
                              }
                            },
                            onTap: () {
                              _controllers[i].selection = TextSelection(baseOffset: 0, extentOffset: _controllers[i].text.length);
                            },
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: _canResend
                    ? GestureDetector(
                        onTap: () {
                          _resendCode();
                          _startResendTimer();
                        },
                        child: Text(
                          localizations.translate('resend_code'),
                          style: const TextStyle(fontSize: 16, color: RydyColors.textColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 16, color: RydyColors.subText),
                          children: [
                            TextSpan(text: localizations.translate('resend_code_in') + ' '),
                            TextSpan(text: _resendSeconds.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: RydyColors.textColor)),
                          ],
                        ),
                      ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator()),
              ],
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: RydyColors.cardBg,
        child: const Icon(Icons.bug_report, color: RydyColors.textColor),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PersonalInfoScreen(),
            ),
          );
        },
        tooltip: localizations.translate('test_personal_info'),
      ),
    );
  }
}
