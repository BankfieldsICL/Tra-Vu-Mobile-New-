import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/driver_auth_controller.dart';

class ProfileCompletionView extends StatefulWidget {
  const ProfileCompletionView({super.key});

  @override
  State<ProfileCompletionView> createState() => _ProfileCompletionViewState();
}

class _ProfileCompletionViewState extends State<ProfileCompletionView> {
  late final DriverAuthController controller;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final Worker profileFieldsWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DriverAuthController>();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    _syncControllersFromState();

    firstNameController.addListener(() {
      controller.firstName.value = firstNameController.text;
    });
    lastNameController.addListener(() {
      controller.lastName.value = lastNameController.text;
    });
    emailController.addListener(() {
      controller.emailAddress.value = emailController.text;
    });
    phoneController.addListener(() {
      controller.profilePhoneNumber.value = phoneController.text;
    });

    profileFieldsWorker = everAll([
      controller.firstName,
      controller.lastName,
      controller.emailAddress,
      controller.profilePhoneNumber,
    ], (_) {
      _syncControllersFromState();
    });
  }

  @override
  void dispose() {
    profileFieldsWorker.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _syncControllersFromState() {
    _setIfChanged(firstNameController, controller.firstName.value);
    _setIfChanged(lastNameController, controller.lastName.value);
    _setIfChanged(emailController, controller.emailAddress.value);
    _setIfChanged(phoneController, controller.profilePhoneNumber.value);
  }

  void _setIfChanged(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: null,
          ),
          title: const Text('Driver Onboarding'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildStepHeader(
                stepLabel: 'Step 1 of 2',
                title: 'Basic Information',
                description:
                    'Fill in your personal details first, then continue to your vehicle and license information.',
              ),
              const SizedBox(height: 32),
              _buildCard(
                icon: Icons.person_outline,
                title: 'Basic Information',
                subtitle: 'Required',
                child: Column(
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        hintText: 'First name',
                        border: InputBorder.none,
                      ),
                    ),
                    TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        hintText: 'Last name',
                        border: InputBorder.none,
                      ),
                    ),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        border: InputBorder.none,
                      ),
                    ),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Phone number',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitProfileDetails,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Continue to Vehicle and License',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader({
    required String stepLabel,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitle == 'Required'
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
