import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/driver_auth_controller.dart';

class DocumentVerificationView extends GetView<DriverAuthController> {
  const DocumentVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.backToProfileDetails();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: controller.backToProfileDetails,
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
                stepLabel: 'Step 2 of 2',
                title: 'Vehicle and License',
                description:
                    'Finish your driver onboarding with the vehicle and license details needed for dispatch.',
              ),
              const SizedBox(height: 32),
              _buildDocumentCard(
                icon: Icons.badge,
                title: 'Driving License',
                subtitle: 'Required',
                child: TextField(
                  onChanged: (value) => controller.licenseNumber.value = value,
                  decoration: const InputDecoration(
                    hintText: 'License number',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDocumentCard(
                icon: Icons.directions_car,
                title: 'Vehicle Registration',
                subtitle: 'Required',
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => controller.vehicleMake.value = value,
                      decoration: const InputDecoration(
                        hintText: 'Vehicle make',
                        border: InputBorder.none,
                      ),
                    ),
                    TextField(
                      onChanged: (value) => controller.vehicleModel.value = value,
                      decoration: const InputDecoration(
                        hintText: 'Vehicle model',
                        border: InputBorder.none,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) =>
                                controller.vehiclePlate.value = value,
                            decoration: const InputDecoration(
                              hintText: 'Plate number',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            onChanged: (value) =>
                                controller.vehicleYear.value = value,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Year',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDocumentCard(
                icon: Icons.shield,
                title: 'Insurance Certificate',
                subtitle: 'Optional',
                child: const Text(
                  'We can collect insurance details later. The required fields above are enough to continue setup.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: controller.backToProfileDetails,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back to Basic Information'),
              ),
              const SizedBox(height: 12),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitDocuments,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Finish Driver Setup',
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

  Widget _buildDocumentCard({
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
