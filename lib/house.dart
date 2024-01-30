import 'package:cloud_firestore/cloud_firestore.dart';

class House {
  final String? objectId;
  List<dynamic>? distanceTime;
  final String? district;
  final String? images;
  final Map<String, dynamic>? location;
  final int? max;
  final String? name;
  final bool? status;
  final String? owner;
  final String? lastdate;
  final String? prefergender;
  final double? price;
  int? quota;
  final String? type;

  House({
    this.objectId,
    this.distanceTime,
    this.district,
    this.images,
    this.location,
    this.max,
    this.name,
    this.status,
    this.owner,
    this.lastdate,
    this.prefergender,
    this.price,
    this.quota,
    this.type,
  });

  factory House.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,) {
    final data = snapshot.data();
    return House(
      objectId: snapshot.id,
      district: data?['district'],
      location: data?['location'],
      max: data?['max'],
      name: data?['name'],
      status: data?['status'],
      owner: data?['owner'],
      lastdate: data?['lastDate'],
      prefergender: data?['preffered gender'],
      price: (data?['price'] as num?)?.toDouble(),
      quota: data?['quota'],
      type: data?['type'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (district != null) "district": district,
      if (location != null) "location": location,
      if (max != null) "max": max,
      if (name != null) "name": name,
      if (owner != null) "owner": owner,
      if (lastdate != null) "lastDate": lastdate,
      if (prefergender != null) "preffered gender": prefergender,
      if (price != null) "price": price,
      if (quota != null) "quota": quota,
      if (type != null) "type": type,
    };
  }
}
