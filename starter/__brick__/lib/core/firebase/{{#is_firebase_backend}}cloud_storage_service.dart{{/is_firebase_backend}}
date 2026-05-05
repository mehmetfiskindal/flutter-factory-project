import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class CloudStorageService {
  const CloudStorageService(this._storage);

  final FirebaseStorage _storage;

  Reference ref(String path) {
    return _storage.ref(path);
  }

  Future<TaskSnapshot> uploadData(
    String path,
    Uint8List data, {
    SettableMetadata? metadata,
  }) {
    return ref(path).putData(data, metadata);
  }

  Future<TaskSnapshot> uploadString(
    String path,
    String data, {
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata? metadata,
  }) {
    return ref(path).putString(data, format: format, metadata: metadata);
  }

  Future<Uint8List?> getData(
    String path, {
    int maxSize = 10 * 1024 * 1024,
  }) {
    return ref(path).getData(maxSize);
  }

  Future<String> getDownloadUrl(String path) {
    return ref(path).getDownloadURL();
  }

  Future<void> delete(String path) {
    return ref(path).delete();
  }
}
