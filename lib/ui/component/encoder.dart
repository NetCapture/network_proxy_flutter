import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_toastr/flutter_toastr.dart';

///编码类型
enum EncoderType {
  url,
  base64,
  md5;

  static EncoderType nameOf(String name) {
    for (var value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return url;
  }
}

class EncoderWidget extends StatefulWidget {
  final EncoderType type;
  final WindowController? windowController;
  final String? text;

  const EncoderWidget({super.key, required this.type, this.windowController, this.text});

  @override
  State<EncoderWidget> createState() => _EncoderState();
}

class _EncoderState extends State<EncoderWidget> with SingleTickerProviderStateMixin {
  var tabs = const [
    Tab(text: 'URL'),
    Tab(text: 'Base64'),
    Tab(text: 'MD5'),
  ];

  late EncoderType type;
  late TabController tabController;

  AppLocalizations get localizations => AppLocalizations.of(context)!;

  String inputText = '';
  TextEditingController outputTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    type = widget.type;
    inputText = widget.text ?? '';

    tabController = TabController(initialIndex: type.index, length: tabs.length, vsync: this);
    RawKeyboard.instance.addListener(onKeyEvent);
  }

  @override
  void dispose() {
    tabController.dispose();
    RawKeyboard.instance.removeListener(onKeyEvent);
    super.dispose();
  }

  void onKeyEvent(RawKeyEvent event) async {
    if ((event.isKeyPressed(LogicalKeyboardKey.metaLeft) || event.isControlPressed) &&
        event.isKeyPressed(LogicalKeyboardKey.keyW)) {
      RawKeyboard.instance.removeListener(onKeyEvent);
      tabController.dispose();
      widget.windowController?.close();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          title: Text('${type.name.toUpperCase()}${localizations.encode}', style: const TextStyle(fontSize: 16)),
          centerTitle: true,
          bottom: TabBar(
            controller: tabController,
            tabs: tabs,
            onTap: (index) {
              setState(() {
                type = EncoderType.values[index];
                outputTextController.clear();
              });
            },
          )),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Text(localizations.encodeInput),
            const SizedBox(height: 5),
            TextFormField(
                initialValue: inputText,
                minLines: 5,
                maxLines: 10,
                onChanged: (text) => inputText = text,
                decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                FilledButton(onPressed: encode, child: Text('${type.name.toUpperCase()}${localizations.encode}')),
                const SizedBox(width: 20),
                type == EncoderType.md5
                    ? const SizedBox()
                    : OutlinedButton(
                        onPressed: decode, child: Text('${type.name.toUpperCase()}${localizations.encode}')),
              ],
            ),
            Text(localizations.encodeResult),
            const SizedBox(height: 5),
            TextFormField(
              controller: outputTextController,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: outputTextController.text));
                FlutterToastr.show(localizations.copied, context);
              },
              child: Text(localizations.copy),
            ),
          ],
        ),
      ),
    );
  }

  ///编码
  void encode() {
    var result = '';
    try {
      switch (type) {
        case EncoderType.url:
          result = Uri.encodeFull(inputText);
        case EncoderType.base64:
          result = base64.encode(utf8.encode(inputText));
        case EncoderType.md5:
          result = md5.convert(inputText.codeUnits).toString();
      }
    } catch (e) {
      FlutterToastr.show(localizations.encodeFail, context);
    }
    outputTextController.text = result;
  }

  ///解码
  void decode() {
    var result = '';
    try {
      switch (type) {
        case EncoderType.url:
          result = Uri.decodeFull(inputText);
        case EncoderType.base64:
          result = utf8.decode(base64Decode(inputText));
        case EncoderType.md5:
      }
    } catch (e) {
      FlutterToastr.show(localizations.decodeFail, context);
    }
    outputTextController.text = result;
  }
}
