import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String supabaseUrl = '';
  String supabaseKey = '';

  for (final line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.split('=')[1];
    }
    if (line.startsWith('SUPABASE_ANON_KEY=')) {
      supabaseKey = line.split('=')[1];
    }
  }

  try {
    print("Fetching broadcasts via raw HTTP API...");
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/broadcasts?select=*'),
      headers: {'apikey': supabaseKey, 'Authorization': 'Bearer $supabaseKey'},
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");
  } catch (e) {
    print("Error querying broadcasts: $e");
  }
}
