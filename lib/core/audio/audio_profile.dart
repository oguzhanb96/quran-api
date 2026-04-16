enum AudioProfile {
  female('female'),
  male('male');

  const AudioProfile(this.value);
  final String value;

  static AudioProfile fromValue(String? value) {
    return value == AudioProfile.female.value ? AudioProfile.female : AudioProfile.male;
  }
}
