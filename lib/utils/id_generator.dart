import 'dart:math';


class IdGenerator {


  static String generate(){


    return DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        +
        Random()
            .nextInt(999)
            .toString();


  }


}