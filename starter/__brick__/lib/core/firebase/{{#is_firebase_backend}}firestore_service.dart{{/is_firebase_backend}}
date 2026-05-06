import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  const FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  CollectionReference<T> typedCollection<T>({
    required String path,
    required T Function(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
    ) fromFirestore,
    required Map<String, Object?> Function(T value, SetOptions? options)
        toFirestore,
  }) {
    return collection(path).withConverter<T>(
      fromFirestore: fromFirestore,
      toFirestore: toFirestore,
    );
  }

  DocumentReference<T> typedDocument<T>({
    required String path,
    required T Function(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
    ) fromFirestore,
    required Map<String, Object?> Function(T value, SetOptions? options)
        toFirestore,
  }) {
    return document(path).withConverter<T>(
      fromFirestore: fromFirestore,
      toFirestore: toFirestore,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(String path) {
    return document(path).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument(String path) {
    return document(path).snapshots();
  }

  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = true,
  }) {
    return document(path).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) {
    return document(path).update(data);
  }

  Future<void> deleteDocument(String path) {
    return document(path).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    String path, {
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )? queryBuilder,
  }) {
    final query = queryBuilder?.call(collection(path)) ?? collection(path);
    return query.get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection(
    String path, {
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )? queryBuilder,
  }) {
    final query = queryBuilder?.call(collection(path)) ?? collection(path);
    return query.snapshots();
  }
}
