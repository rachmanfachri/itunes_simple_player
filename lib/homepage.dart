import 'package:flutter/material.dart';
import 'package:itunes_simple_player/audio_common.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:rxdart/rxdart.dart';
import 'global_functions.dart';

class Homepage extends StatefulWidget {
  Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  /// controller for search keyword
  TextEditingController _keywordCtrl = TextEditingController();

  /// determine loading state when doing API request
  bool _isLoading = false;

  /// determine error state after doing API request
  bool _isError = false;

  /// list for contents of playlist from API request
  List<Map> _playlistData = [];

  /// data of currently playing track
  Map _nowPlaying = {};

  /// controller of audio player
  final AudioPlayer _player = AudioPlayer();

  /// duration of currently playing track
  var duration;

  @override
  void initState() {
    super.initState();

    // set up initial playlist
    _isLoading = true;
    _keywordCtrl.text = 'foster the people';
    _getPlaylist();
  }

  /// get contents for playlist from API request function
  _getPlaylist({String keyword = ''}) async {
    await getSongsData(keyword.isEmpty
            ? _keywordCtrl.text.isEmpty
                ? 'foster the people'
                : _keywordCtrl.text
            : keyword)
        .then((response) {
      if (response is bool) {
        _isError = response;
      } else {
        _playlistData = List.from(response);
      }
    });
    setState(() {});
  }

  /// set the playlist and its behaviour
  _initPlaylist(int index) async {
    _player.setShuffleModeEnabled(false);
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          for (int i = 0; i < _playlistData.length; i++) AudioSource.uri(Uri.parse(_playlistData[i]['previewUrl'])),
        ],
      ),
      initialIndex: index,
      initialPosition: Duration.zero,
    );
  }

  /// collects the data useful for displaying in a seekbar
  Stream<PositionData> get _positionDataStream {
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _player.positionStream,
      _player.bufferedPositionStream,
      _player.durationStream,
      (position, bufferedPosition, duration) => PositionData(position, bufferedPosition, duration ?? Duration.zero),
    );
  }

  /// appbar which contains search textfield
  _appBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.75),
      centerTitle: true,
      leading: const Icon(Icons.play_circle_fill_rounded, color: Colors.amberAccent),
      title: Container(
          decoration: BoxDecoration(
            color: Colors.white54,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            height: kToolbarHeight - 25,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 16,
              child: TextField(
                controller: _keywordCtrl,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.only(bottom: 12),
                  border: InputBorder.none,
                  hintText: 'Search',
                ),
                onChanged: (keyword) {
                  setState(() => _nowPlaying.clear());
                  _getPlaylist(keyword: keyword);
                },
              ),
            ),
          )),
    );
  }

  /// UI component for each item of playlist
  _playlistItemDisplay(int index) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => setState(() => _nowPlaying = Map.from(_playlistData[index])),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7.5),
              child: SizedBox(
                height: 50,
                width: 50,
                child: Image.network(
                  _playlistData[index]['artworkUrl60'],
                  height: 50,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: ((_playlistData[index]['trackName'].length) * 7.5) >= MediaQuery.of(context).size.width - 170
                      ? MediaQuery.of(context).size.width - 170
                      : ((_playlistData[index]['trackName'].length + 1) * 7.5),
                  height: 17,
                  child: _playlistData[index]['trackId'] == _nowPlaying['trackId']
                      ? Marquee(
                          text: _playlistData[index]['trackName'],
                          // maxLines: 1,
                          // overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          scrollAxis: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          blankSpace: 20,
                          velocity: 40.0,
                          startPadding: 10.0,
                          accelerationCurve: Curves.linear,
                          decelerationCurve: Curves.easeOut,
                        )
                      : Text(
                          _playlistData[index]['trackName'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 160,
                  child: Text(
                    _playlistData[index]['artistName'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Visibility(
              visible: _playlistData[index]['trackId'] == _nowPlaying['trackId'],
              child: const Icon(
                Icons.audiotrack_rounded,
                color: Colors.amberAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _playerBox() {
    return Container(
      height: 120,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: _nowPlaying['trackName'].length * 7.5 >= MediaQuery.of(context).size.width - 30
                ? MediaQuery.of(context).size.width - 30
                : (_nowPlaying['trackName'].length + 1) * 7.5,
            height: 18,
            child: _nowPlaying['trackId'].toString().length * 7.5 >= MediaQuery.of(context).size.width - 30
                ? Marquee(
                    text: _nowPlaying['trackName'],
                    // maxLines: 1,
                    // overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 20,
                    velocity: 40.0,
                    startPadding: 10.0,
                    accelerationCurve: Curves.linear,
                    decelerationCurve: Curves.easeOut,
                  )
                : Text(
                    _nowPlaying['trackName'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          SizedBox(
            width: _nowPlaying['artistName'].length * 6.5 >= MediaQuery.of(context).size.width - 30
                ? MediaQuery.of(context).size.width - 30
                : (_nowPlaying['artistName'].length + 1) * 6.5,
            child: Text(
              _nowPlaying['artistName'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
              ),
            ),
          ),
          StreamBuilder<PositionData>(
            stream: _positionDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return SeekBar(
                duration: positionData?.duration ?? Duration.zero,
                position: positionData?.position ?? Duration.zero,
                bufferedPosition: positionData?.bufferedPosition ?? Duration.zero,
                onChangeEnd: _player.seek,
              );
            },
          ),
        ],
      ),
    );
  }

  /// UI component to structure the playlist display
  _listStructure() {
    return Container(
      color: Colors.black54,
      child: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - (_nowPlaying.isEmpty ? 0 : 120),
            child: _playlistData.isEmpty
                ? _isError
                    ? Center()
                    : Center()
                : ListView(
                    children: [
                      const SizedBox(height: 5),
                      for (int i = 0; i < _playlistData.length; i++) _playlistItemDisplay(i),
                      const SizedBox(height: 5),
                    ],
                  ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              height: _nowPlaying.isEmpty ? 0 : 120,
              child: _nowPlaying.isNotEmpty ? _playerBox() : const SizedBox(),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
      body: _listStructure(),
    );
  }
}
