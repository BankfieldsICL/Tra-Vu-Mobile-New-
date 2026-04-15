import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';

class HistoryController extends GetxController {
  final CustomerApi _customerApi = Get.find<CustomerApi>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<JobModel> jobs = <JobModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadJobs();
  }

  Future<void> loadJobs() async {
    isLoading.value = true;
    error.value = null;

    try {
      final fetchedJobs = await _customerApi.getJobs();
      // Sort: newest first
      fetchedJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      jobs.assignAll(fetchedJobs);
    } catch (e) {
      error.value = _readableErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void trackJob(JobModel job) {
    Get.toNamed('/tracking', arguments: {'jobId': job.id, 'job': job});
  }

  String _readableErrorMessage(dynamic e) {
    // Simple error mapper similar to wallet_controller
    return e.toString().contains('401')
        ? 'Session expired. Please log in again.'
        : 'Failed to load history. Please try again.';
  }

  String formatPrice(int? amountMinor, String currency) {
    if (amountMinor == null) return '---';
    final symbol = currency == 'NGN' ? '₦' : '\$';
    return '$symbol${(amountMinor / 100).toStringAsFixed(2)}';
  }
}
