class GstIndianState {
  const GstIndianState({required this.code, required this.name});

  final String code;
  final String name;

  String get label => '$name ($code)';
}

abstract final class GstIndianStates {
  static const all = <GstIndianState>[
    GstIndianState(code: '01', name: 'Jammu & Kashmir'),
    GstIndianState(code: '02', name: 'Himachal Pradesh'),
    GstIndianState(code: '03', name: 'Punjab'),
    GstIndianState(code: '04', name: 'Chandigarh'),
    GstIndianState(code: '05', name: 'Uttarakhand'),
    GstIndianState(code: '06', name: 'Haryana'),
    GstIndianState(code: '07', name: 'Delhi'),
    GstIndianState(code: '08', name: 'Rajasthan'),
    GstIndianState(code: '09', name: 'Uttar Pradesh'),
    GstIndianState(code: '10', name: 'Bihar'),
    GstIndianState(code: '11', name: 'Sikkim'),
    GstIndianState(code: '12', name: 'Arunachal Pradesh'),
    GstIndianState(code: '13', name: 'Nagaland'),
    GstIndianState(code: '14', name: 'Manipur'),
    GstIndianState(code: '15', name: 'Mizoram'),
    GstIndianState(code: '16', name: 'Tripura'),
    GstIndianState(code: '17', name: 'Meghalaya'),
    GstIndianState(code: '18', name: 'Assam'),
    GstIndianState(code: '19', name: 'West Bengal'),
    GstIndianState(code: '20', name: 'Jharkhand'),
    GstIndianState(code: '21', name: 'Odisha'),
    GstIndianState(code: '22', name: 'Chhattisgarh'),
    GstIndianState(code: '23', name: 'Madhya Pradesh'),
    GstIndianState(code: '24', name: 'Gujarat'),
    GstIndianState(
      code: '26',
      name: 'Dadra and Nagar Haveli and Daman and Diu',
    ),
    GstIndianState(code: '27', name: 'Maharashtra'),
    GstIndianState(code: '29', name: 'Karnataka'),
    GstIndianState(code: '30', name: 'Goa'),
    GstIndianState(code: '31', name: 'Lakshadweep'),
    GstIndianState(code: '32', name: 'Kerala'),
    GstIndianState(code: '33', name: 'Tamil Nadu'),
    GstIndianState(code: '34', name: 'Puducherry'),
    GstIndianState(code: '35', name: 'Andaman and Nicobar Islands'),
    GstIndianState(code: '36', name: 'Telangana'),
    GstIndianState(code: '37', name: 'Andhra Pradesh'),
    GstIndianState(code: '38', name: 'Ladakh'),
    GstIndianState(code: '97', name: 'Other Territory'),
  ];

  static GstIndianState? match(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final lower = value.toLowerCase();
    for (final state in all) {
      if (state.name.toLowerCase() == lower ||
          state.label.toLowerCase() == lower ||
          state.code == value) {
        return state;
      }
    }
    return null;
  }
}
