class BluetoothDeviceModel {
  final String name;
  final String address;
  bool isConnected;

  BluetoothDeviceModel({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  factory BluetoothDeviceModel.fromMap(Map<String, dynamic> map) {
    return BluetoothDeviceModel(
      name: map['name'] ?? 'Unknown',
      address: map['address'],
      isConnected: map['isConnected'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'isConnected': isConnected,
    };
  }
}