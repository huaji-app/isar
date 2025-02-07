import 'package:isar_generator/src/code_gen/type_adapter_generator_common.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

class _GetPropResult {
  _GetPropResult({
    required this.code,
    required this.value,
    required this.dynamicSize,
  });
  final String code;
  final String value;
  final String? dynamicSize;
}

_GetPropResult _generateGetPropertyValue(
  ObjectProperty property,
  ObjectInfo object,
) {
  var code = '';
  var value = 'object.${property.dartName}';
  String? dynamicSize;

  if (property.converter != null) {
    final convertedValue = '${property.dartName}\$Converted';
    code += 'final $convertedValue = ${property.toIsar(value, object)};';
    value = convertedValue;
  }

  switch (property.isarType) {
    case IsarType.string:
      final stringBytes = '${property.dartName}\$Bytes';
      if (property.nullable) {
        final stringValue = '${property.dartName}\$Value';
        code += '''
          IsarUint8List? $stringBytes;
          final $stringValue = $value;
          if ($stringValue != null) {
            $stringBytes = IsarBinaryWriter.utf8Encoder.convert($stringValue);
          }
          ''';
        dynamicSize = '($stringBytes != null ? 3 + $stringBytes.length : 0)';
      } else {
        code += 'final $stringBytes = IsarBinaryWriter.utf8Encoder '
            '.convert($value);';
        dynamicSize = '(3 + $stringBytes.length)';
      }
      value = stringBytes;
      break;
    case IsarType.stringList:
      final stringBytesList = '${property.dartName}\$BytesList';
      dynamicSize = '${property.dartName}\$BytesCount';
      if (property.nullable) {
        final stringValue = '${property.dartName}\$Value';
        code += '''
          List<IsarUint8List?>? $stringBytesList;
          var $dynamicSize = 0;
          final $stringValue = $value;
          if ($stringValue != null) {
            $dynamicSize = 3 + $stringValue.length * 3;
            $stringBytesList = [];
            for (final str in $stringValue) {''';
      } else {
        code += '''
          final $stringBytesList = <IsarUint8List?>[];
          var $dynamicSize = 3 + $value.length * 3;
          for (final str in $value) {''';
      }
      if (property.elementNullable) {
        code += 'if (str != null) {';
      }
      code += '''
        final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
        $stringBytesList.add(bytes);
        $dynamicSize += bytes.length as int;''';
      if (property.elementNullable) {
        code += '''
          } else {
            $stringBytesList.add(null);
          }''';
      }
      if (property.nullable) {
        code += '}';
      }
      code += '}';
      value = stringBytesList;
      break;
    case IsarType.byteList:
    case IsarType.boolList:
    case IsarType.intList:
    case IsarType.floatList:
    case IsarType.longList:
    case IsarType.doubleList:
    case IsarType.dateTimeList:
      if (property.nullable) {
        dynamicSize = '($value != null ? 3 + $value!.length * '
            '${property.isarType.elementSize} : 0)';
      } else {
        dynamicSize = '(3 + $value.length * ${property.isarType.elementSize})';
      }
      break;
    // ignore: no_default_cases
    default:
      break;
  }

  return _GetPropResult(code: code, value: value, dynamicSize: dynamicSize);
}

String generateSerializeNative(ObjectInfo object) {
  var code =
      'void ${object.serializeNativeName}(IsarCollection<${object.dartName}>'
      ' collection, IsarCObject cObj, ${object.dartName} object, '
      'int staticSize, List<int> offsets, AdapterAlloc alloc) {';

  final values = <String>[];
  final sizes = <String>['staticSize'];
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    final serialize = _generateGetPropertyValue(property, object);

    code += serialize.code;
    values.add(serialize.value);
    if (serialize.dynamicSize != null) {
      sizes.add(serialize.dynamicSize!);
    }
  }

  code += '''
    final size = (${sizes.join(' + ')}) as int;
    cObj.buffer = alloc(size);
    cObj.buffer_length = size;

    final buffer = IsarNative.bufAsBytes(cObj.buffer, size);
    final writer = IsarBinaryWriter(buffer, staticSize);
    writer.writeHeader();
  ''';
  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    switch (property.isarType) {
      case IsarType.id:
        throw UnimplementedError();
      case IsarType.bool:
        code += 'writer.writeBool(offsets[$i], ${values[i]});';
        break;
      case IsarType.byte:
        code += 'writer.writeByte(offsets[$i], ${values[i]});';
        break;
      case IsarType.int:
        code += 'writer.writeInt(offsets[$i], ${values[i]});';
        break;
      case IsarType.float:
        code += 'writer.writeFloat(offsets[$i], ${values[i]});';
        break;
      case IsarType.long:
        code += 'writer.writeLong(offsets[$i], ${values[i]});';
        break;
      case IsarType.double:
        code += 'writer.writeDouble(offsets[$i], ${values[i]});';
        break;
      case IsarType.dateTime:
        code += 'writer.writeDateTime(offsets[$i], ${values[i]});';
        break;
      case IsarType.string:
      case IsarType.byteList:
        code += 'writer.writeByteList(offsets[$i], ${values[i]});';
        break;
      case IsarType.boolList:
        code += 'writer.writeBoolList(offsets[$i], ${values[i]});';
        break;
      case IsarType.stringList:
        code += 'writer.writeByteLists(offsets[$i], ${values[i]});';
        break;
      case IsarType.intList:
        code += 'writer.writeIntList(offsets[$i], ${values[i]});';
        break;
      case IsarType.longList:
        code += 'writer.writeLongList(offsets[$i], ${values[i]});';
        break;
      case IsarType.floatList:
        code += 'writer.writeFloatList(offsets[$i], ${values[i]});';
        break;
      case IsarType.doubleList:
        code += 'writer.writeDoubleList(offsets[$i], ${values[i]});';
        break;
      case IsarType.dateTimeList:
        code += 'writer.writeDateTimeList(offsets[$i], ${values[i]});';
        break;
    }
  }

  code += 'writer.validate();';

  return '$code}';
}

String generateDeserializeNative(ObjectInfo object) {
  String deserProp(ObjectProperty p) {
    final index = object.objectProperties.indexOf(p);
    return _deserializeProperty(object, p, 'offsets[$index]');
  }

  var code = '''
  ${object.dartName} ${object.deserializeNativeName}(IsarCollection<${object.dartName}> collection, int id, IsarBinaryReader reader, List<int> offsets) {
    ${deserializeMethodBody(object, deserProp)}''';

  if (object.links.isNotEmpty) {
    code += '${object.attachLinksName}(collection, id, object);';
  }

  // ignore: leading_newlines_in_multiline_strings
  return '''$code
    return object;
  }''';
}

String generateDeserializePropNative(ObjectInfo object) {
  var code = '''
  P ${object.deserializePropNativeName}<P>(int id, IsarBinaryReader reader, int propertyIndex, int offset) {
    switch (propertyIndex) {
      case -1:
        return id as P;''';

  for (var i = 0; i < object.objectProperties.length; i++) {
    final property = object.objectProperties[i];
    final deser = _deserializeProperty(object, property, 'offset');
    code += 'case $i: return ($deser) as P;';
  }

  return '''
      $code
      default:
        throw IsarError('Illegal propertyIndex');
      }
    }
    ''';
}

String _deserializeProperty(
  ObjectInfo object,
  ObjectProperty property,
  String propertyOffset,
) {
  final orNull = property.nullable ? 'OrNull' : '';
  final orNullList = property.nullable ? '' : '?? []';
  final orElNull = property.elementNullable ? 'OrNull' : '';

  String? deser;
  switch (property.isarType) {
    case IsarType.id:
      return 'id';
    case IsarType.bool:
      deser = 'reader.readBool$orNull($propertyOffset)';
      break;
    case IsarType.byte:
      deser = 'reader.readByte($propertyOffset)';
      break;
    case IsarType.int:
      deser = 'reader.readInt$orNull($propertyOffset)';
      break;
    case IsarType.float:
      deser = 'reader.readFloat$orNull($propertyOffset)';
      break;
    case IsarType.long:
      deser = 'reader.readLong$orNull($propertyOffset)';
      break;
    case IsarType.double:
      deser = 'reader.readDouble$orNull($propertyOffset)';
      break;
    case IsarType.dateTime:
      deser = 'reader.readDateTime$orNull($propertyOffset)';
      break;
    case IsarType.string:
      deser = 'reader.readString$orNull($propertyOffset)';
      break;
    case IsarType.byteList:
      deser = 'reader.readByteList$orNull($propertyOffset)';
      break;
    case IsarType.boolList:
      deser = 'reader.readBool${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.stringList:
      deser = 'reader.readString${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.intList:
      deser = 'reader.readInt${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.floatList:
      deser = 'reader.readFloat${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.longList:
      deser = 'reader.readLong${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.doubleList:
      deser = 'reader.readDouble${orElNull}List($propertyOffset) $orNullList';
      break;
    case IsarType.dateTimeList:
      deser = 'reader.readDateTime${orElNull}List($propertyOffset) $orNullList';
      break;
  }

  return property.fromIsar(deser, object);
}
