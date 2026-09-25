import '../core/json_utils.dart';

class WorkflowStep {
  final int id;
  final String name;
  final int sequence;
  final String? roleName;
  final String status;
  final String? comments;
  final String? rejectionReason;
  final String? completedAt;

  WorkflowStep({
    required this.id,
    required this.name,
    required this.sequence,
    this.roleName,
    required this.status,
    this.comments,
    this.rejectionReason,
    this.completedAt,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) => WorkflowStep(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        sequence: asIntOrNull(json['sequence']) ?? 0,
        roleName: json['role_name']?.toString(),
        status: json['status']?.toString() ?? '',
        comments: json['comments']?.toString(),
        rejectionReason: json['rejection_reason']?.toString(),
        completedAt: json['completed_at']?.toString(),
      );
}

class WorkflowTimeline {
  final bool hasWorkflow;
  final List<WorkflowStep> steps;

  WorkflowTimeline({required this.hasWorkflow, required this.steps});

  factory WorkflowTimeline.fromJson(Map<String, dynamic>? json) {
    if (json == null) return WorkflowTimeline(hasWorkflow: false, steps: const []);
    final stepsJson = (json['steps'] as List?) ?? const [];
    return WorkflowTimeline(
      hasWorkflow: json['has_workflow'] == true,
      steps: stepsJson.map((s) => WorkflowStep.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}
