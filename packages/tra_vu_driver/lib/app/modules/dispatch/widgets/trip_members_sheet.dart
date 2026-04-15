import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import '../dispatch_controller.dart';

class TripMembersBottomSheet extends StatelessWidget {
  final TripModel trip;
  final List<TripMemberModel> members;
  final DispatchController controller;

  const TripMembersBottomSheet({
    super.key,
    required this.trip,
    required this.members,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Manage Passengers",
            style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "${trip.availableSeats} of ${trip.totalSeats} seats available",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text("No passengers have joined yet."),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: members.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return _buildMemberItem(context, member);
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, TripMemberModel member) {
    final status = member.status;
    final name = member.user != null 
        ? "${member.user!.firstName} ${member.user!.lastName}"
        : "Passenger";

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(status.displayName),
          trailing: _buildActions(context, member),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, TripMemberModel member) {
    switch (member.status) {
      case TripMemberStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => controller.rejectMember(member.id),
              icon: const Icon(Icons.close, color: Colors.red),
            ),
            IconButton(
              onPressed: () => controller.approveMember(member.id),
              icon: const Icon(Icons.check, color: Colors.green),
            ),
          ],
        );
      case TripMemberStatus.approved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _showOTPDialog(context, member),
              child: const Text("BOARD"),
            ),
            TextButton(
              onPressed: () => controller.markNoShow(member.id),
              child: const Text("NO SHOW", style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showOTPDialog(BuildContext context, TripMemberModel member) {
    final otpController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Verify Boarding"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the 4-digit OTP shown on the passenger's screen."),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "0000",
                counterText: "",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (otpController.text.length == 4) {
                Get.back();
                controller.boardMember(member.id, otpController.text);
              }
            },
            child: const Text("VERIFY"),
          ),
        ],
      ),
    );
  }
}
