import 'dart:async';

import 'package:isolation/src/constant.dart';

import 'unit/echo.dart' as echo;
import 'unit/pow.dart' as pow;

void main() => runZoned(
      () {
        echo.main();
        pow.main();
      },
      zoneValues: {kLogEnabled: true},
    );
