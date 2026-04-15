enum JobStatus {
  created,
  matched,
  accepted,
  enroute,
  arrived,
  in_progress,
  completed,
  cancelled,
  pending_payment,
}

extension JobStatusExtension on JobStatus {
  static JobStatus fromString(String status) {
    final sanitized = status.trim().toLowerCase();
    return JobStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == sanitized,
      orElse: () => JobStatus.created,
    );
  }

  // Display name for Customer tracking UI
  String get displayName {
    switch (this) {
      case JobStatus.created:
        return "Finding Driver...";
      case JobStatus.matched:
        return "Driver Found";
      case JobStatus.accepted:
        return "Driver Confirmed";
      case JobStatus.enroute:
        return "Driver En Route";
      case JobStatus.arrived:
        return "Driver Arrived";
      case JobStatus.in_progress:
        return "In Transit";
      case JobStatus.completed:
        return "Completed";
      case JobStatus.cancelled:
        return "Cancelled";
      case JobStatus.pending_payment:
        return "Payment Pending";
    }
  }

  // Progress logic for Timeline UI (0.0 to 1.0)
  double get progressValue {
    switch (this) {
      case JobStatus.created:
      case JobStatus.matched:
        return 0.1;
      case JobStatus.accepted:
        return 0.25;
      case JobStatus.enroute:
        return 0.45;
      case JobStatus.arrived:
        return 0.6;
      case JobStatus.in_progress:
        return 0.8;
      case JobStatus.completed:
        return 1.0;
      case JobStatus.cancelled:
        return 0.0;
      case JobStatus.pending_payment:
        return 0.95;
    }
  }

  // Consistent color mapping for UI badges and icons
  int get statusColorValue {
    switch (this) {
      case JobStatus.completed:
        return 0xFF027A48; // Emerald
      case JobStatus.cancelled:
        return 0xFFB42318; // Crimson
      case JobStatus.enroute:
      case JobStatus.arrived:
      case JobStatus.accepted:
      case JobStatus.in_progress:
      case JobStatus.pending_payment:
        return 0xFF2563EB; // Royal Blue
      case JobStatus.matched:
      case JobStatus.created:
      default:
        return 0xFFB54708; // Amber/Orange
    }
  }
}
