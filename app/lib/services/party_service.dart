import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/storage_keys.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/party.dart';

final partyServiceProvider = Provider<PartyService>((ref) {
  return PartyService(ApiClient());
});

class PartyService {
  final ApiClient _client;

  PartyService(this._client);

  Future<String?> _getPlayerUUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.playerUUID);
  }

  Future<String?> _getPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.playerName);
  }

  Future<Party> createParty({
    required String mode,
    required int targetScore,
  }) async {
    try {
      final uuid = await _getPlayerUUID();
      final name = await _getPlayerName();

      final data = await _client.post('/party', {
        'player_uuid': uuid,
        'player_name': name,
        'mode': mode,
        'target_score': targetScore,
      });

      // Create gibt nur party_id + party_code zurück → Status laden
      final partyId = data['party_id'];
      final status = await _client.get('/party/$partyId');
      return Party.fromJson(status);
    } on Exception catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Party> joinParty({required String code}) async {
    try {
      final uuid = await _getPlayerUUID();
      final name = await _getPlayerName();

      final data = await _client.post('/party/join/$code', {
        'player_uuid': uuid,
        'player_name': name,
      });

      return Party.fromJson(data);
    } on Exception catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Party> getPartyStatus(int partyId) async {
    try {
      final data = await _client.get('/party/$partyId');
      return Party.fromJson(data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> startParty(int partyId) async {
    try {
      final uuid = await _getPlayerUUID();
      await _client.post('/party/$partyId/start', {'player_uuid': uuid});
    } on Exception catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<int> reportWinner(int partyId) async {
    try {
      final uuid = await _getPlayerUUID();
      final data = await _client.post('/party/$partyId/round/winner', {
        'player_uuid': uuid,
      });
      return data['round_id'];
    } on Exception catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Map<String, dynamic>> submitScore({
    required int partyId,
    required int roundId,
    required int points,
    String? imageBase64,
  }) async {
    try {
      final uuid = await _getPlayerUUID();
      final body = {
        'player_uuid': uuid,
        'round_id': roundId,
        'points': points,
        // ignore: use_null_aware_elements
        if (imageBase64 != null) 'image_base64': imageBase64,
      };
      return await _client.post('/party/$partyId/round/score', body);
    } on Exception catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Party> restartParty(int partyId) async {
    try {
      final uuid = await _getPlayerUUID();

      // Restart gibt nur party_id + party_code zurück → Status laden
      final data = await _client.post('/party/$partyId/restart', {
        'player_uuid': uuid,
      });
      final newPartyId = data['party_id'];
      final status = await _client.get('/party/$newPartyId');
      return Party.fromJson(status);
    } on Exception catch (e) {
      throw AppException(e.toString());
    }
  }
}
