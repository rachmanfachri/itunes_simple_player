import 'dart:convert';
import 'package:http/http.dart' as http;

/// function for API request to get playlist data based on search keyword
getSongsData(String keyword) async {
  List<Map> data = [];
  int? resultCount;
  bool error = false;

  // for every space in keyword string changed to '+'
  await http.get(Uri.parse('https://itunes.apple.com/search?term=' + keyword.replaceAll(' ', '+'))).then(
    (response) {
      // get data when the request's status code is 200
      if (response.statusCode == 200) {
        resultCount = json.decode(response.body)['resultCount'];
        data = List.from(json.decode(response.body)['results']);
        for (var element in data) {
          print(element['collectionName']);
        }
      } else {
        // set [_isError] as true to then later be used as snackbar parameter and/or any action related to retry etc.
        error = true;
      }
    },
  );

  return resultCount != null ? data : error;
}
