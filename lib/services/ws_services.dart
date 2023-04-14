import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:socket_rocket/constants/snackbar.dart';
import 'package:web_socket_channel/io.dart';

class WSServices {
  late IOWebSocketChannel channel;
  final String _baseurl = "wss://api-snappio.onrender.com/ws/";

//   connectPrivateSocket(BuildContext context, String userid, String token,
//       ScrollController scroll) {
//     try {
//       channel =
//           IOWebSocketChannel.connect("${_baseurl}user/$userid/", headers: {
//         "Authorization": "Bearer $token",
//       });
//       channel.stream.listen((message) {
//         var jsonData = jsonDecode(message);
//         MessageData msgdata =
//             MessageData(message: jsonData["message"], isme: false);
//         // Provider.of<MsgProvider>(context, listen: false).addMsg(msgdata);
//         scroll.jumpTo(scroll.position.maxScrollExtent);
//       }, onError: (error) {
//         showSnackBar(context, "Something went wrong...check username");
//         Navigator.of(context).pop();
//         log(error.toString());
//       });
//     } catch (e) {
//       showSnackBar(context, "Something went wrong...check username");
//       Navigator.of(context).pop();
//       log(e.toString());
//     }
//   }

  connectRoomSocket(
    BuildContext context,
    String roomId,
    // ScrollController scroll,
  ) {
    try {
      channel =
        IOWebSocketChannel.connect(Uri.parse("${_baseurl}rooms/$roomId/"));
      channel.stream.listen((message) {
        debugPrint("Socket Message: $message");
        //   var jsonData = jsonDecode(message);
        //   MessageData msgdata =
        //   MessageData(message: jsonData["message"], isme: false);
        // Provider.of<MsgProvider>(context, listen: false).addMsg(msgdata);
        // scroll.jumpTo(scroll.position.maxScrollExtent);
      }, onError: (error) {
        showSnackBar(context, "Something went wrong...check connection");
        //   Navigator.of(context).pop();
        log(error.toString());
      });
    } catch (e) {
      showSnackBar(context, "Something went wrong...");
      log(e.toString());
    }
  }

  Future<void> sendMsg(
    // BuildContext context,
    String userId,
	String lat,
    String long,
  ) async {
    String message =
        '{ "message" : { "userId" : "$userId", "latitude":"$lat", "longitude" : "$long", "location": [ "$lat", "$long" ] }}';
    debugPrint(message);
    // MessageData msgdata = MessageData(
    //   message: message,
    //   isme: true,
    // );
    // Provider.of<MsgProvider>(context, listen: false).addMsg(msgdata);
    channel.sink.add(message);
  }
}
