import '../../services/firebase/crash_report_service.dart' as service;

/// Process-wide diagnostics use the same configured destination as unhandled
/// errors. UI code depends on this repository, never on the Firebase service.
class FailureReportRepository {
  const FailureReportRepository();

  void record(Object error, StackTrace stack) =>
      service.reportHandledError(error, stack);
}

/// Shared entry point for recoverable failures. No Firebase types cross this API.
void reportHandledError(Object error, StackTrace stack) =>
    const FailureReportRepository().record(error, stack);
