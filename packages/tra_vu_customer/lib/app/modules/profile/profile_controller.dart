import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import 'package:tra_vu_customer/app/modules/home/home_controller.dart';

class ProfileController extends GetxController {
  final CustomerApi _customerApi = Get.find<CustomerApi>();
  
  final formKey = GlobalKey<FormState>();
  
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    try {
      final HomeController homeController = Get.find<HomeController>();
      final user = homeController.profile.value;
      if (user != null) {
        firstNameController.text = user.firstName;
        lastNameController.text = user.lastName;
        phoneController.text = user.phoneNumber ?? '';
        emailController.text = user.email ?? '';
      }
    } catch (_) {
      // Ignore if HomeController is not found
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final updatedUser = await _customerApi.updateProfile({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'email': emailController.text.trim(),
      });
      
      try {
        final HomeController homeController = Get.find<HomeController>();
        homeController.profile.value = updatedUser;
      } catch (_) {}

      Get.back();
      Get.snackbar('Success', 'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
