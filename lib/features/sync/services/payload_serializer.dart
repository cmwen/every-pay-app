import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:everypay/domain/entities/sync_payload.dart';

class PayloadSerializer {
  Uint8List serialize(SyncPayload payload) {
    final json = jsonEncode(payload.toJson());
    final utf8Bytes = utf8.encode(json);
    final gzipped = gzip.encode(utf8Bytes);
    return Uint8List.fromList(gzipped);
  }

  SyncPayload deserialize(Uint8List bytes) {
    final decompressed = gzip.decode(bytes);
    final json = utf8.decode(decompressed);
    final map = jsonDecode(json) as Map<String, dynamic>;
    return SyncPayload.fromJson(map);
  }
}
