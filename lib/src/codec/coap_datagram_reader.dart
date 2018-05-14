/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the functionality to read raw network-ordered datagrams on bit-level.
class CoapDatagramReader {
  /// Initializes a new DatagramReader object
  CoapDatagramReader(typed.Uint8Buffer buffer) {
    _buffer = buffer;
    _currentByte = new ByteData(1);
    _currentBitIndex = -1;
  }

  typed.Uint8Buffer _buffer;

  bool get bytesAvailable => _buffer.length > 0;

  ByteData _currentByte;
  int _currentBitIndex;

  /// Reads a sequence of bits from the stream
  int read(int numBits) {
    int bits = 0; // initialize all bits to zero
    for (int i = numBits - 1; i >= 0; i--) {
      // Check whether a new byte needs to be read
      if (_currentBitIndex < 0) {
        _readCurrentByte();
      }

      // Test the current bit
      final bool bit = (_currentByte.getUint8(0) >> _currentBitIndex & 1) != 0;
      if (bit) {
        // Set the bit at i-th position
        bits |= (1 << i);
      }

      // decrease current bit index
      --_currentBitIndex;
    }
    return bits;
  }

  /// Reads a sequence of bytes from the stream
  typed.Uint8Buffer readBytes(int count) {
    // For negative count values, read all bytes left
    if (count < 0) {
      count = _buffer.length;
    }

    final typed.Uint8Buffer bytes = new typed.Uint8Buffer(count);

    // Are there bits left to read in buffer?
    if (_currentBitIndex >= 0) {
      for (int i = 0; i < count; i++) {
        bytes[i] = read(8);
      }
    } else {
      final List<int> removed = _buffer.getRange(0, bytes.length);
      bytes.insertAll(0, removed);
      _buffer.removeRange(0, bytes.length);
    }

    return bytes;
  }

  /// Reads the next byte from the stream.
  int readNextByte() {
    return readBytes(1)[0];
  }

  /// Reads the complete sequence of bytes left in the stream
  typed.Uint8Buffer readBytesLeft() {
    return readBytes(-1);
  }

  void _readCurrentByte() {
    int val = _buffer.removeAt(0);

    if (val >= 0) {
      _currentByte.setUint8(0, val);
    } else {
      // EOF
      _currentByte.setUint8(0, 0);
    }
    // Reset the current bit index
    _currentBitIndex = 7;
  }
}