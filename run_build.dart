import 'dart:io';

void main() async {
  print('Starting build_runner...');
  final result = await Process.run('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
  print('Stdout: ${result.stdout}');
  print('Stderr: ${result.stderr}');
}
