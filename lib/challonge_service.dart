import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ChallongeService {
  // Fetches participants and returns a map of ID to name
  Future<Map<int, String>> fetchParticipantNames(String tournamentId) async {
    final url = Uri.parse(
        'https://api.challonge.com/v1/tournaments/$tournamentId/participants.json?api_key=$challongeApiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> participants = json.decode(response.body);
        Map<int, String> participantNames = {};
        for (var participant in participants) {
          int id = participant['participant']['id'];
          String name = participant['participant']['name'];
          participantNames[id] = name;
        }
        return participantNames;
      } else {
        throw Exception('Failed to load participants: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching participants: $e');
    }
  }

  // Fetch matches and group them by rounds
  Future<Map<int, List<dynamic>>> fetchMatchesGroupedByRounds(
      String tournamentId) async {
    final url = Uri.parse(
        'https://api.challonge.com/v1/tournaments/$tournamentId/matches.json?api_key=$challongeApiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> matches = json.decode(response.body);

        // Group matches by rounds
        Map<int, List<dynamic>> rounds = {};
        for (var match in matches) {
          int round = match['match']['round'];
          if (!rounds.containsKey(round)) {
            rounds[round] = [];
          }
          rounds[round]!.add(match);
        }

        return rounds;
      } else {
        throw Exception('Failed to load matches: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching matches: $e');
    }
  }
}
