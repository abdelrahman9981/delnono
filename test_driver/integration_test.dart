// Driver for browser end-to-end tests (flutter drive -d web-server), e.g. the dashboard:
//   scripts/dashboard_e2e.sh
// On a failure the test's report data (each Flutter error in full) is still written to
// build/integration_response_data.json.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(writeResponseOnFailure: true);
