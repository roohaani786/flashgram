import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techstagram/ComeraV/gallery.dart';
import 'package:techstagram/ComeraV/video_timer.dart';
import 'package:flutter/services.dart';
import 'package:torch_compat/torch_compat.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:techstagram/ui/HomePage.dart';
import 'package:thumbnails/thumbnails.dart';
import 'package:lamp/lamp.dart';
import 'package:torch/torch.dart';
import 'package:holding_gesture/holding_gesture.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key key}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen>
    with AutomaticKeepAliveClientMixin {
  CameraController _controller;
  List<CameraDescription> _cameras;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRecordingMode = false;
  bool _isRecording = false;
  bool _isButtonPressed = false;
  final _timerKey = GlobalKey<VideoTimerState>();
  bool _hasFlash = false;

  @override
  void initState() {
    _initCamera();
    super.initState();
    initPlatformState();
  }

  initPlatformState() async {
    bool hasFlash = await Lamp.hasLamp;
    print("Device has flash ? $hasFlash");
    setState(() { _hasFlash = hasFlash; });
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.veryHigh);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onHorizontalDrag(DragEndDetails details,context) {
    if (details.primaryVelocity == 0)
      // user have just tapped on screen (no dragging)
      return;

    if (details.primaryVelocity.compareTo(0) == -1) {
//      dispose();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage(initialindexg: 1)),
      );


    }
    else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen()),
      );
//      Navigator.push(
//          context,
//          MaterialPageRoute(
//              builder: (BuildContext context) => HomePage())).then((res) {
//        setState(() {
//          cameraon = true;
//        });
//      }
//      );
    }
  }

  bool flashOn=true;


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    super.build(context);
    if (_controller != null) {
      if (!_controller.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container();
    }
    return GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) =>
            _onHorizontalDrag(details,context),
      child: Scaffold(
        // floatingActionButton: HoldDetector(
        //   onHold: startVideoRecording,
        //   holdTimeout: Duration(milliseconds: 200),
        //   enableHapticFeedback: true,
        //   child: FloatingActionButton(
        //     child: Icon(Icons.camera),
        //     onPressed: _captureImage,
        //   ),
        // ),
        backgroundColor: Theme.of(context).backgroundColor,
        key: _scaffoldKey,
        extendBody: true,
        body: Stack(
          children: <Widget>[
            _buildCameraPreview(),
            Positioned(
              top: 24.0,
              left: 12.0,
              child: IconButton(
                icon: Icon(
                  Icons.switch_camera,
                  color: Colors.white,
                ),
                onPressed: () {
                  _onCameraSwitch();
                },
              ),
            ),
            Positioned(
              top: 24.0,
              right: 12.0,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage(initialindexg: 1)),
                  );
                },
              ),
            ),
          Positioned(
            top: 340.0,
            right: 12.0,
            child: IconButton(
              icon: Icon(
                (flashOn) ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  flashOn = !flashOn;
                });

                // setState(() {
                //   flashOn = !flashOn;
                // });
                // if (!flashOn) {
                //   //Lamp.turnOff();
                //   TorchCompat.turnOff();
                // } else {
                //   TorchCompat.turnOn();
                //   //Lamp.turnOn();
                // }
              },
              //onPressed: () => TorchCompat.turnOff(),
            ),
          ),


            if (_isRecordingMode)
              Positioned(
                left: 0,
                right: 0,
                top: 32.0,
                child: VideoTimer(
                  key: _timerKey,
                ),
              )
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    return ClipRect(
      child: Container(
        child: Transform.scale(
          scale: _controller.value.aspectRatio / size.aspectRatio,
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: CameraPreview(_controller),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: Colors.transparent,
      height: 100.0,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          FutureBuilder(
            future: getLastImage(),
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return Container(
                  width: 40.0,
                  height: 40.0,
                );
              }
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Gallery(),
                  ),
                ),
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.file(
                      snapshot.data,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),

          FlatButton(
            color: Colors.transparent,
          onPressed: () async => await Lamp.flash(new Duration(seconds: 2)),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 28.0,
                child: IconButton(
                  icon: Icon(
                    (_isRecordingMode)
                        ? (_isRecording) ? Icons.stop : Icons.videocam
                        : Icons.camera_alt,
                    size: 28.0,
                    color: (_isRecording) ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    if (!_isRecordingMode) {
                      _captureImage();
                      if(flashOn){
                        _turnFlash();
                      }
                    } else {
                      if (_isRecording) {
                        stopVideoRecording();
                      } else {
                        startVideoRecording();
                      }
                    }
                  },
                ),

            ),
          ),
          IconButton(
            icon: Icon(
              (_isRecordingMode) ? Icons.camera_alt : Icons.videocam,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isRecordingMode = !_isRecordingMode;
              });
            },
          ),
        ],
      ),
    );
  }

  Future _turnFlash() async {
    bool hasTorch = await Torch.hasTorch;
    if(hasTorch){
      flashOn ? Torch.turnOn() : Torch.turnOff();
      var f = await Torch.hasTorch;
      Torch.flash(Duration(milliseconds: 300));
      setState((){
        _hasFlash = f;
        //flashOn = !flashOn;
      });
    }
  }

  Future<FileSystemEntity> getLastImage() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/media';
    final myDir = Directory(dirPath);
    List<FileSystemEntity> _images;
    _images = myDir.listSync(recursive: true, followLinks: false);
    _images.sort((a, b) {
      return b.path.compareTo(a.path);
    });
    var lastFile = _images[0];
    var extension = path.extension(lastFile.path);
    if (extension == '.jpeg') {
      return lastFile;
    } else {
      String thumb = await Thumbnails.getThumbnail(
          videoFile: lastFile.path, imageType: ThumbFormat.PNG, quality: 30);
      return File(thumb);
    }
  }

  Future<void> _onCameraSwitch() async {
    final CameraDescription cameraDescription =
        (_controller.description == _cameras[0]) ? _cameras[1] : _cameras[0];
    if (_controller != null) {
      await _controller.dispose();
    }
    _controller = CameraController(cameraDescription, ResolutionPreset.medium);
    _controller.addListener(() {
      if (mounted) setState(() {});
      if (_controller.value.hasError) {
        showInSnackBar('Camera error ${_controller.value.errorDescription}');
      }
    });

    try {
      await _controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _captureImage() async {
    print('_captureImage');
    if (_controller.value.isInitialized) {
      SystemSound.play(SystemSoundType.click);
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/media';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${_timestamp()}.jpeg';
      print('path: $filePath');
      await _controller.takePicture(filePath);
      setState(() {});
    }
  }

  Future<String> startVideoRecording() async {
    print('startVideoRecording');
    if (!_controller.value.isInitialized) {
      return null;
    }
    setState(() {
      _isRecording = true;
    });
    _timerKey.currentState.startTimer();

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/media';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${_timestamp()}.mp4';

    if (_controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
//      videoPath = filePath;
      await _controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return null;
    }
    _timerKey.currentState.stopTimer();
    setState(() {
      _isRecording = false;
    });

    try {
      await _controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');

  @override
  bool get wantKeepAlive => true;
}