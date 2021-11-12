// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:developer';

import 'package:jovial_svg/jovial_svg.dart';
import 'package:wsa_pacman/global_state.dart';
import 'package:wsa_pacman/proto/options.pb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:wsa_pacman/widget/adaptive_icon.dart';

import '/utils/string_utils.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:provider/provider.dart';

import '../theme.dart';

const List<String> accentColorNames = [
  'System',
  'Yellow',
  'Orange',
  'Red',
  'Magenta',
  'Purple',
  'Blue',
  'Teal',
  'Green',
];

class LateUpdater<E> {
  static const SETTINGS_UPDATE_TIMER = Duration(seconds:3);
  E initialValue;
  Timer? timer;
  Function(E value) callback;

  LateUpdater(this.initialValue, this.callback);
  update(E newValue) {
    initialValue = newValue;
    timer?.cancel();
    timer = Timer(SETTINGS_UPDATE_TIMER, (){if (initialValue == newValue) callback(initialValue);});
  }

  cancel() => timer?.cancel();

  instant(E newValue) {
    timer?.cancel();
    callback(newValue);
  }
}

class Settings extends StatefulWidget {
  Settings({Key? key, this.controller}) : super(key: key);
  final ScrollController? controller;

  @override
  State<StatefulWidget> createState() => SettingsState(controller: this.controller);
}

late final androidPortUpdater = LateUpdater<int>(GState.androidPort.$, (value){
  GState.androidPort..update((p0) => value)..persist();
  log("AGGIORNATO: ${GState.androidPort.$}");
});

class SettingsState extends State<Settings> {
  static const SETTINGS_UPDATE_TIMER = Duration(seconds:3);
  SettingsState({this.controller}) {
    loadExampleIcon();
  }
  final ScrollController? controller;

  //late final exBackground = ScalableImage.fromAvdAsset(rootBundle, "assets/icons/missing_icon_background.xml");
  //late final exForeground = ScalableImage.fromAvdAsset(rootBundle, "assets/icons/missing_icon_foreground.xml");
  ScalableImageWidget? _exBackground;
  ScalableImageWidget? _exForeground;

  void loadExampleIcon() async {
    var exBg = ScalableImage.fromAvdAsset(rootBundle, "assets/icons/missing_icon_background.xml");
    var exFg = ScalableImage.fromAvdAsset(rootBundle, "assets/icons/missing_icon_foreground.xml");
    var exBackground = await exBg; var exForeground = await exFg;
    setState(() {
      _exBackground = ScalableImageWidget(si: exBackground);
      _exForeground = ScalableImageWidget(si: exForeground);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final tooltipThemeData = TooltipThemeData(decoration: () {
      const radius = BorderRadius.zero;
      final shadow = [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(1, 1),
          blurRadius: 10.0,
        ),
      ];
      final border = Border.all(color: Colors.grey[100], width: 0.5);
      if (FluentTheme.of(context).brightness == Brightness.light) {
        return BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: border,
          boxShadow: shadow,
        );
      } else {
        return BoxDecoration(
          color: Colors.grey,
          borderRadius: radius,
          border: border,
          boxShadow: shadow,
        );
      }
    }());

    const hSpacer = SizedBox(width: 10.0);
    const spacer = SizedBox(height: 10.0);
    const biggerSpacer = SizedBox(height: 40.0);

    var theme = GState.theme.of(context).mode;
    var iconShape = GState.iconShape.of(context);

    var exampleIcon = AdaptiveIcon(background: _exBackground, foreground: _exForeground, radius: iconShape.radius);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Settings')),
      content: ListView(
        padding: EdgeInsets.only(
          bottom: kPageDefaultVerticalPadding,
          left: PageHeader.horizontalPadding(context),
          right: PageHeader.horizontalPadding(context),
        ),
        controller: controller,
        children: [
          Text('WSA Port',
              style: FluentTheme.of(context).typography.subtitle),
          spacer,
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextBox(
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  var androidPortVal = (newValue.text.isNumeric()) ? (newValue.text.length > 5 || (newValue.text.isEmpty ? 58526 : int.parse(newValue.text)) <= 65535 ? newValue : TextEditingValue(text: "65535", selection: newValue.selection)) : 
                  (oldValue.text.isNumeric() ? oldValue : TextEditingValue.empty);
                  GState.androidPortPending.$ = androidPortVal.text.isEmpty ? 58526.toString() : androidPortVal.text;
                  return androidPortVal;
                })
              ],
              maxLength: 5,
              maxLines: 1,
              maxLengthEnforced: true,
              controller: TextEditingController.fromValue(TextEditingValue(text: GState.androidPortPending.$)),
              autofocus: false,
              onChanged: (value)=>androidPortUpdater.update(value.isEmpty ? 58526 : int.parse(value)),
              enableSuggestions: false,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              prefix: const Padding(padding: EdgeInsets.only(left: 10), child: Text("127.0.0.1 :")),
              suffix: IconButton(
                icon: const Icon(FluentIcons.reset),
                onPressed: () {GState.androidPortPending.update((_) => 58526.toString()); androidPortUpdater.instant(58526); setState((){});},
              )
            ),
          ),
          biggerSpacer,
          Text('Theme mode',
              style: FluentTheme.of(context).typography.subtitle),
          spacer,
          ...List.generate(Options_Theme.values.length, (index) {
            final modeOpt = Options_Theme.values[index];
            final mode = modeOpt.mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RadioButton(
                checked: theme == mode,
                onChanged: (value) {
                  if (value) {
                    GState.theme..update((p0) => modeOpt)..persist();
                    theme = mode;
                  }
                },
                content: Text('$mode'.replaceAll('ThemeMode.', '').capitalized),
              ),
            );
          }),
          biggerSpacer,
          Row(children: [
            Flexible(child: SizedBox(width: 30.00, height: 30.00, child: exampleIcon)),
            hSpacer,
            Text('Adaptive icons Shape',
              style: FluentTheme.of(context).typography.subtitle),
          ]),
          spacer,
          ...List.generate(Options_IconShape.values.length, (index) {
            final shape = Options_IconShape.values[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RadioButton(
                checked: iconShape == shape,
                onChanged: (value) {
                  if (value) {
                    GState.iconShape..update((p0) => shape)..persist();
                    iconShape = shape;
                  }
                },
                content: Text('$shape'.normalized),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildColorBlock(AppTheme appTheme, AccentColor color) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Button(
        onPressed: () {
          appTheme.color = color;
        },
        style: ButtonStyle(padding: ButtonState.all(EdgeInsets.zero)),
        child: Container(
          height: 40,
          width: 40,
          color: color,
          alignment: Alignment.center,
          child: appTheme.color == color
              ? Icon(
                  FluentIcons.check_mark,
                  color: color.basedOnLuminance(),
                  size: 22.0,
                )
              : null,
        ),
      ),
    );
  }
}
