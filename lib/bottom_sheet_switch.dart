import 'package:flutter/material.dart';
import 'package:safehouse_timer/colors.dart';

class BottomSheetSwitch extends StatefulWidget {
  BottomSheetSwitch(
      {@required this.switchValue,
      @required this.valueChanged,
      @required this.labelText,
      @required this.icon});

  final bool switchValue;
  final ValueChanged valueChanged;
  final String labelText;
  final Icon icon;

  @override
  _BottomSheetSwitch createState() => _BottomSheetSwitch();
}

class _BottomSheetSwitch extends State<BottomSheetSwitch> {
  bool _switchValue;
  String _labelText;
  Icon _icon;

  @override
  void initState() {
    _switchValue = widget.switchValue;
    _labelText = widget.labelText;
    _icon = widget.icon;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SwitchListTile(
        title: Text(_labelText),
        value: _switchValue,
        onChanged: (bool value) {
          setState(() {
            _switchValue = value;
            widget.valueChanged(value);
          });
        },
        secondary: _icon,
        activeColor: aYellow,
        activeTrackColor: Colors.yellow[700],
      ),
    );
  }
}
