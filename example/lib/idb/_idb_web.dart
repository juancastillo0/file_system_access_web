import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:file_system_access/file_system_access.dart';

// void initIndexedDB() {
//   html;
// }

Object jsObjectFromMap(Object map) {
  // final v = (js.context['Object'] as js.JsObject)
  //     .callMethod('getOwnPropertySymbols', [map]);
  // print('jsObjectFromMap v $v');
  // final s = (v as js.JsArray)[0];
  // return js.JsObject.fromBrowserObject(map)[s];
  return js_util.jsify(map);
}

Object jsObjectFromMap2(Object map) {
  return js.JsObject.jsify(map);
}

Future<void Function(Object)> createDBWindow() {
  final comp = Completer<void Function(Object)>();

  final v = (js.context['createDB'] as js.JsFunction).apply([]);
  print('v $v');
  final then = js.JsObject.fromBrowserObject(v)['then'] as js.JsFunction;
  print('then $then');
  then.apply(
    [
      js.allowInterop((db) {
        final _db = db as js.JsObject;
        comp.complete((v) {
          print('v ${v.runtimeType} $v ${v is FileSystemHandle}');
          return _db.callMethod('put', [v]);
        });
      }),
    ],
    thisArg: v,
  );

  return comp.future;
}
