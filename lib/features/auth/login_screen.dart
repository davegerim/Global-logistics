import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AppRole role) async {
    final phone = _phone.text.trim();
    final password = _password.text;
    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter phone and password.'), backgroundColor: AppColors.error),
      );
      return;
    }
    await ref.read(authProvider.notifier).login(
          phone: phone,
          password: password,
          intendedRole: role,
        );
    if (!mounted) return;
    final err = ref.read(authProvider).errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final role = roleParam == 'driver' ? AppRole.driver : AppRole.consignor;
    final t = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        // Using a subtly warm background so the pure white login box becomes distinctly visible
        backgroundColor: AppColors.backgroundWarm, 
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Back Button Only
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 16.0),
                    child: GestureDetector(
                      onTap: () => context.go('/role'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Animated Truck firmly anchored over the road
                const Center(child: DrivingTruck()),
                
                // Form Card - Shrunk to provide maximum whitespace
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 20.0),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white, // Pure white makes it pop against backgroundWarm
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.borderLight, width: 1.0),
                      // Added a very soft, elegant shadow so the box is clearly visible and floating
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Greeting
                        Text(
                          'Welcome Back',
                          style: t.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role == AppRole.driver
                              ? 'Sign in to access your routes.'
                              : 'Sign in to manage shipments.',
                          style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Form
                        Text(
                          'Phone Number',
                          style: t.labelMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: t.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Enter phone',
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 18),
                            filled: true,
                            fillColor: AppColors.backgroundWarm, // Slight contrast inside the white box
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Password',
                          style: t.labelMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          style: t.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 18),
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundWarm, // Slight contrast inside the white box
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => context.push(
                                      '/forgot-password',
                                      extra: {'phone': _phone.text.trim()},
                                    ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: t.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        GlPrimaryButton(
                          label: 'Sign In',
                          isLoading: auth.isLoading,
                          showShadow: true, // Bringing the button shadow back to make it pop
                          onPressed: () => _submit(role),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: t.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                if (role == AppRole.driver) {
                                  context.push('/register-driver');
                                } else {
                                  context.push('/register-consignor');
                                }
                              },
                              child: Text(
                                'Create Account',
                                style: t.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A widget that animates the truck image so it is exactly anchored on top of the road
class DrivingTruck extends StatefulWidget {
  const DrivingTruck({super.key});

  @override
  State<DrivingTruck> createState() => _DrivingTruckState();
}

class _DrivingTruckState extends State<DrivingTruck> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Truck bounces up and down
        final bounce = math.sin(_controller.value * math.pi * 4) * 3.5;
        // Subtle rocking/wobbling back and forth
        final wobble = math.cos(_controller.value * math.pi * 4) * 0.015;
        // Shadow scales inversely to bounce
        final shadowScale = 1.0 - (bounce.clamp(0, 4) / 15.0);
        
        return SizedBox(
          height: 230, // Taller bounds to contain the overlap
          width: double.infinity,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // 1. Realistic Moving Road elevated so the car can cover it
              Positioned(
                bottom: 20, // Pushed the road higher up in the stack
                child: SizedBox(
                  height: 40, // Taller road
                  width: 340,
                  child: CustomPaint(
                    painter: _RealisticRoadPainter(_controller.value),
                  ),
                ),
              ),
              
              // 2. Dynamic shadow anchored directly ON the road
              Positioned(
                bottom: 20, // Exact same level as the road
                child: Transform.scale(
                  scale: shadowScale,
                  child: Container(
                    width: 140,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.all(Radius.elliptical(140, 6)),
                    ),
                  ),
                ),
              ),
              
              // 3. The moving truck pushed DOWN relative to the road to firmly anchor it
              Positioned(
                bottom: -8 + bounce, // Negative value physically forces the tires over the road
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()..rotateZ(wobble),
                  child: Image.asset(
                    'assets/images/Gemini_Generated_Image.png',
                    height: 200, // Slightly larger truck
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_shipping_rounded,
                      size: 100,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for a more realistic 3D-ish moving road
class _RealisticRoadPainter extends CustomPainter {
  final double animationValue;
  _RealisticRoadPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Asphalt background (trapezoid to give a sense of depth/perspective)
    final roadPath = Path()
      ..moveTo(30, 0)
      ..lineTo(size.width - 30, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    final roadPaint = Paint()
      ..color = const Color(0xFFE8ECEB) // Light asphalt matching the app theme
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(roadPath, roadPaint);

    // 2. Draw Moving dashed line in the center
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dashWidth = 28.0;
    const dashSpace = 24.0;
    const totalDash = dashWidth + dashSpace;
    
    // Animate moving to the left (assuming the truck is facing right)
    final startX = -(animationValue * totalDash);
    final centerY = size.height / 2;

    canvas.save();
    canvas.clipPath(roadPath);

    // Draw lines covering the entire width of the road
    for (double x = startX - totalDash; x < size.width + totalDash; x += totalDash) {
      canvas.drawLine(
        Offset(x, centerY), 
        Offset(x + dashWidth, centerY), 
        dashPaint
      );
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RealisticRoadPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}
