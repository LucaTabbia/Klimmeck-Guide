import 'dart:convert';

/// Id Android stabile per [key] (FNV-1a 32 bit, ridotto a 31 bit non negativi):
/// `String.hashCode` non è garantito uguale tra isolate e versioni della VM. Lo
/// stesso evento consegnato due volte sostituisce la notifica invece di
/// duplicarla.
int stableNotificationId(String key) {
  var hash = _fnvOffsetBasis;
  for (final byte in utf8.encode(key)) {
    hash ^= byte;
    hash = (hash * _fnvPrime) & _uint32Mask;
  }
  return hash & _positiveInt31Mask;
}

const int _fnvOffsetBasis = 0x811c9dc5;
const int _fnvPrime = 0x01000193;
const int _uint32Mask = 0xffffffff;
const int _positiveInt31Mask = 0x7fffffff;
