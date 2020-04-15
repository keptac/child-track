class CoordinatesValue {
  final int id;
  final int vehicleId;
  final double currentLocationLatitude;
  final double currentLocationLongitude;
  final String time;

  CoordinatesValue(
      {this.id,
      this.vehicleId,
      this.currentLocationLatitude,
      this.currentLocationLongitude,
      this.time});

  factory CoordinatesValue.fromJson(Map<String, dynamic> json) {
    return CoordinatesValue(
        id: json['id'],
        vehicleId: json['vehicleId'],
        currentLocationLatitude: json['currentLocationLatitude'],
        currentLocationLongitude: json['currentLocationLongitude'],
        time: json['time']);
  }
}
