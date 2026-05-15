import 'package:flutter/services.dart';

class BrValueMasks {
  const BrValueMasks._();

  static final phoneFormatter = _BrMaskTextInputFormatter(
    normalize: onlyDigits,
    format: formatPhone,
  );

  static final cpfFormatter = _BrMaskTextInputFormatter(
    normalize: onlyDigits,
    format: formatCpf,
  );

  static final cpfCnpjFormatter = _BrMaskTextInputFormatter(
    normalize: onlyDigits,
    format: formatCpfCnpj,
  );

  static final licensePlateFormatter = _BrMaskTextInputFormatter(
    normalize: normalizeLicensePlate,
    format: formatLicensePlate,
  );

  static String onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String normalizeLicensePlate(String value) {
    return _take(value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''), 7);
  }

  static String formatPhone(String value) {
    final digits = _take(onlyDigits(value), 11);
    final length = digits.length;
    if (length == 0) {
      return '';
    }
    if (length <= 2) {
      return '($digits';
    }
    if (length <= 6) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    }
    if (length <= 10) {
      return '(${digits.substring(0, 2)}) '
          '${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 3)} '
        '${digits.substring(3, 7)}-${digits.substring(7)}';
  }

  static String formatCpf(String value) {
    final digits = _take(onlyDigits(value), 11);
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index == 3 || index == 6) {
        buffer.write('.');
      } else if (index == 9) {
        buffer.write('-');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  static String formatCpfCnpj(String value) {
    final digits = onlyDigits(value);
    if (digits.length <= 11) {
      return formatCpf(digits);
    }
    return formatCnpj(digits);
  }

  static String formatCnpj(String value) {
    final digits = _take(onlyDigits(value), 14);
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index == 2 || index == 5) {
        buffer.write('.');
      } else if (index == 8) {
        buffer.write('/');
      } else if (index == 12) {
        buffer.write('-');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  static String formatLicensePlate(String value) {
    final plate = normalizeLicensePlate(value);
    if (plate.length <= 3) {
      return plate;
    }
    return '${plate.substring(0, 3)}-${plate.substring(3)}';
  }

  static String _take(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }
}

class _BrMaskTextInputFormatter extends TextInputFormatter {
  const _BrMaskTextInputFormatter({
    required this.normalize,
    required this.format,
  });

  final String Function(String value) normalize;
  final String Function(String value) format;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = format(normalize(newValue.text));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
