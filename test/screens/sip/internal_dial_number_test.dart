import 'package:crm_task_manager/screens/sip/calling_codes.dart';
import 'package:crm_task_manager/screens/sip/internal_dial_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calling code table covers every region we ship to', () {
    expect(kCallingCodeNationalLength.length, greaterThanOrEqualTo(200));
    expect(kCallingCodeNationalLength['992'], 9);
    expect(kCallingCodeNationalLength['998'], 9);
    expect(kCallingCodeNationalLength['996'], 9);
    expect(kCallingCodeNationalLength['7'], 10);
    expect(kCallingCodeNationalLength['1'], 10);
    expect(kCallingCodeNationalLength['49'], 11);
    expect(kCallingCodeNationalLength['880'], 10);
    expect(kCallingCodeNationalLength['852'], 8);
    expect(kCallingCodeNationalLength['380'], 9);
    expect(kCallingCodeNationalLength['971'], 9);
  });

  test('strips Tajik country code before an internal call', () {
    expect(
      stripCountryCodeForInternalCall('+992927777777', homeDialCode: '+992'),
      '927777777',
    );
    expect(
      stripCountryCodeForInternalCall('992927777777', homeDialCode: '+992'),
      '927777777',
    );
    expect(
      stripCountryCodeForInternalCall('00992927777777', homeDialCode: '+992'),
      '927777777',
    );
    expect(
      stripCountryCodeForInternalCall(
        '+992 (92) 777-77-77',
        homeDialCode: '+992',
      ),
      '927777777',
    );
    expect(
      stripCountryCodeForInternalCall(
        '+992992927777777',
        homeDialCode: '+992',
      ),
      '927777777',
    );
  });

  test('keeps a local Tajik number that only looks like +92', () {
    expect(
      stripCountryCodeForInternalCall('927777777', homeDialCode: '+992'),
      '927777777',
    );
    expect(
      stripCountryCodeForInternalCall('927777777'),
      '927777777',
    );
  });

  test('strips the organization code for other countries', () {
    expect(
      stripCountryCodeForInternalCall('+998901234567', homeDialCode: '+998'),
      '901234567',
    );
    expect(
      stripCountryCodeForInternalCall('+4915112345678', homeDialCode: '+49'),
      '15112345678',
    );
    expect(
      stripCountryCodeForInternalCall('+7 (916) 123-45-67', homeDialCode: '+7'),
      '9161234567',
    );
    expect(
      stripCountryCodeForInternalCall('79161234567', homeDialCode: '7'),
      '9161234567',
    );
    expect(
      stripCountryCodeForInternalCall('+12025550123', homeDialCode: '+1'),
      '2025550123',
    );
    expect(
      stripCountryCodeForInternalCall('+8801712345678', homeDialCode: '+880'),
      '1712345678',
    );
    expect(
      stripCountryCodeForInternalCall('+85291234567', homeDialCode: 'HK'),
      '91234567',
    );
  });

  test('does not eat a local number that starts with the country digit', () {
    expect(
      stripCountryCodeForInternalCall('9161234567', homeDialCode: '+7'),
      '9161234567',
    );
    expect(
      stripCountryCodeForInternalCall('7011234567', homeDialCode: '+7'),
      '7011234567',
    );
    expect(
      stripCountryCodeForInternalCall('+77011234567', homeDialCode: '+7'),
      '7011234567',
    );
    expect(
      stripCountryCodeForInternalCall('100', homeDialCode: '+992'),
      '100',
    );
    expect(
      stripCountryCodeForInternalCall('100', homeDialCode: '+1'),
      '100',
    );
  });

  test('leaves sip targets and feature codes unchanged', () {
    expect(
      stripCountryCodeForInternalCall('sip:100@pbx.local', homeDialCode: '+992'),
      'sip:100@pbx.local',
    );
    expect(
      stripCountryCodeForInternalCall('*100', homeDialCode: '+992'),
      '*100',
    );
    expect(stripCountryCodeForInternalCall(''), '');
  });

  test('does not turn a foreign number into a local one', () {
    expect(
      stripCountryCodeForInternalCall('+998901234567', homeDialCode: '+992'),
      '998901234567',
    );
  });

  test('resolves organization code from settings', () {
    expect(resolveHomeCallingCode('+992'), '992');
    expect(resolveHomeCallingCode('992'), '992');
    expect(resolveHomeCallingCode('TJ'), '992');
    expect(resolveHomeCallingCode('Tajikistan'), '992');
    expect(resolveHomeCallingCode(''), isNull);
  });
}
