// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockTransactionAdapter extends TypeAdapter<StockTransaction> {
  @override
  final int typeId = 1;

  @override
  StockTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockTransaction(
      id: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      type: fields[3] as String,
      quantity: fields[4] as int,
      user: fields[5] as String,
      warehouse: fields[6] as String,
      timestamp: fields[7] as DateTime,
      previousQuantity: fields[8] as int,
      newQuantity: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StockTransaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.user)
      ..writeByte(6)
      ..write(obj.warehouse)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.previousQuantity)
      ..writeByte(9)
      ..write(obj.newQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
