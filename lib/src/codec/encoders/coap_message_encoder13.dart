/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: avoid_returning_this
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: prefer_null_aware_operators
// ignore_for_file: avoid_annotating_with_dynamic

/// Message encoder 13
class CoapMessageEncoder13 extends CoapMessageEncoder {

  @override
  void serialize(CoapDatagramWriter writer, CoapMessage message, int code) {
    // Write fixed-size CoAP headers
    writer.write(CoapDraft13.version, CoapDraft13.versionBits);
    writer.write(message.type, CoapDraft13.typeBits);
    writer.write(message.token == null ? 0 : message.token.length,
        CoapDraft13.tokenLengthBits);
    writer.write(code, CoapDraft13.codeBits);
    writer.write(message.id, CoapDraft13.idBits);

    // Write token, which may be 0 to 8 bytes, given by token length field
    writer.writeBytes(message.token);

    int lastOptionNumber = 0;
    final List<CoapOption> options = message.getAllOptions();
    CoapUtil.insertionSort(
        options, (dynamic a, dynamic b) => a.type.compareTo(b.type));

    for (final CoapOption opt in options) {
      if (opt.type == optionTypeToken) {
        continue;
      }
      if (opt.isDefault()) {
        continue;
      }

      // Write 4-bit option delta
      final int optNum = CoapDraft13.getOptionNumber(opt.type);
      final int optionDelta = optNum - lastOptionNumber;
      final int optionDeltaNibble = CoapDraft13.getOptionNibble(optionDelta);
      writer.write(optionDeltaNibble, CoapDraft13.optionDeltaBits);

      // Write 4-bit option length
      final int optionLength = opt.length;
      final int optionLengthNibble = CoapDraft13.getOptionNibble(optionLength);
      writer.write(optionLengthNibble, CoapDraft13.optionLengthBits);

      // Write extended option delta field (0 - 2 bytes)
      if (optionDeltaNibble == 13) {
        writer.write(optionDelta - 13, 8);
      } else if (optionDeltaNibble == 14) {
        writer.write(optionDelta - 269, 16);
      }

      // Write extended option length field (0 - 2 bytes)
      if (optionLengthNibble == 13) {
        writer.write(optionLength - 13, 8);
      } else if (optionLengthNibble == 14) {
        writer.write(optionLength - 269, 16);
      }

      // Write option value
      writer.writeBytes(opt.valueBytes);

      lastOptionNumber = optNum;
    }

    if (message.payload != null && message.payload.isNotEmpty) {
      // If payload is present and of non-zero length, it is prefixed by
      // an one-byte Payload Marker (0xFF) which indicates the end of
      // options and the start of the payload
      writer.writeByte(CoapDraft13.payloadMarker);
    }
    // Write payload
    writer.writeBytes(message.payload);
  }
}
