import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../home/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;
  bool passwordHidden = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> openAuthSheet(bool createAccount) async {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    passwordHidden = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> resetPassword() async {
              final email = emailController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter your email first.')),
                );
                return;
              }

              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent.')),
              );
            }

            Future<void> submit() async {
              setSheetState(() => loading = true);

              try {
                if (createAccount) {
                  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  await credential.user?.updateDisplayName(nameController.text.trim());
                } else {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );
                }

                if (sheetContext.mounted) Navigator.pop(sheetContext);

                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message ?? 'Authentication failed')),
                );
              } finally {
                if (context.mounted) setSheetState(() => loading = false);
              }
            }

            return SingleChildScrollView(
              child: Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 38,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    createAccount ? 'Create Free Account' : 'Login',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),

                  if (createAccount) ...[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: passwordController,
                    obscureText: passwordHidden,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordHidden
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setSheetState(() {
                            passwordHidden = !passwordHidden;
                          });
                        },
                      ),
                    ),
                  ),

                  if (!createAccount)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(createAccount ? 'Create Account' : 'Login'),
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _WelcomeContent(
      onCreate: () => openAuthSheet(true),
      onLogin: () => openAuthSheet(false),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onLogin;

  const _WelcomeContent({
    required this.onCreate,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _FlightPathPainter())),

            Positioned(
              left: 28,
              top: 80,
              child: Row(
                children: [
                  const Text(
                    'tyme',
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                  const Text(
                    'fly',
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.secondary),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    'assets/logo/butterfly.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            const Positioned(
              left: 30,
              top: 215,
              child: Text(
                'Capture now.\nDeliver later.\nMemories that\nmatter.',
                style: TextStyle(
                  fontSize: 22,
                  height: 1.42,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF26304F),
                ),
              ),
            ),

            Positioned(
              right: 18,
              top: 290,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Image.network(
                  'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?auto=format&fit=crop&w=1200&q=90',
                  width: 190,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Positioned(
              left: 82,
              top: 405,
              child: Transform.rotate(
                angle: -.12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?auto=format&fit=crop&w=1200&q=90',
                    width: 100,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 28,
              right: 28,
              bottom: 96,
              height: 56,
              child: ElevatedButton(
                onPressed: onCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Create Free Account', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),

            Positioned(
              left: 28,
              right: 28,
              bottom: 30,
              height: 56,
              child: OutlinedButton(
                onPressed: onLogin,
                child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width * .7, size.height * .22)
      ..cubicTo(size.width * .95, size.height * .12, size.width, size.height * .35, size.width * .76, size.height * .34);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 8), paint);
        distance += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}











