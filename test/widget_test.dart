// Tests unitarios de las funciones puras de Transferencias Flash.
// (Un widget test completo requeriría mockear varios plugins de plataforma,
//  así que aquí se prueban las utilidades sin dependencias de plataforma.)

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flash/main.dart';

void main() {
  group('Crc32 (R1: integridad)', () {
    test('vector conocido "123456789" = 0xCBF43926', () {
      final crc = Crc32()..update(utf8.encode('123456789'));
      expect(crc.value, 0xCBF43926);
    });

    test('cadena vacía = 0', () {
      expect(Crc32().value, 0);
    });

    test('actualización por partes equivale a una sola pasada', () {
      final whole = Crc32()..update(utf8.encode('hola mundo flash'));
      final parts = Crc32()
        ..update(utf8.encode('hola '))
        ..update(utf8.encode('mundo '))
        ..update(utf8.encode('flash'));
      expect(parts.value, whole.value);
    });

    test('un byte distinto cambia el CRC', () {
      final a = Crc32()..update(utf8.encode('archivo.dat'));
      final b = Crc32()..update(utf8.encode('archivo.dao'));
      expect(a.value == b.value, false);
    });
  });

  group('safeFileName (S1: anti path traversal)', () {
    test('deja pasar un nombre normal', () {
      expect(safeFileName('foto.jpg'), 'foto.jpg');
    });

    test('descarta rutas con separadores Unix y Windows', () {
      expect(safeFileName('../../etc/passwd'), 'passwd');
      expect(safeFileName(r'..\..\windows\system32\evil.dll'), 'evil.dll');
    });

    test('nunca devuelve vacío ni "."', () {
      expect(safeFileName('').isNotEmpty, true);
      expect(safeFileName('..').contains('..'), false);
    });
  });

  group('humanSize (U1: tamaños legibles)', () {
    test('bytes', () => expect(humanSize(512), '512 B'));
    test('kilobytes', () => expect(humanSize(2048), '2.0 KB'));
    test('megabytes', () => expect(humanSize(5 * 1024 * 1024), '5.0 MB'));
    test('gigabytes', () => expect(humanSize(3 * 1024 * 1024 * 1024), '3.0 GB'));
  });

  group('humanSpeed / humanEta (U1)', () {
    test('velocidad cero no muestra nada', () => expect(humanSpeed(0), ''));
    test('velocidad en MB/s', () {
      expect(humanSpeed(2 * 1024 * 1024), '2.0 MB/s');
    });
    test('ETA cero no muestra nada', () {
      expect(humanEta(Duration.zero), '');
    });
    test('ETA en segundos y minutos', () {
      expect(humanEta(const Duration(seconds: 45)), '45s');
      expect(humanEta(const Duration(seconds: 90)), '1m 30s');
    });
  });
}
