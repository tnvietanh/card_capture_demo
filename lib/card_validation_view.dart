import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:card_capture/card_overlay_shape.dart';

import 'package:flutter/material.dart';

import 'app_themes/app_colors.dart';
import 'app_themes/app_text_styles.dart';

enum CardValidationStep { CARDFRONT, CARDBACK }

// ignore: must_be_immutable
class CardValidationView extends StatefulWidget {
  const CardValidationView({Key? key}) : super(key: key);
  @override
  _CardValidationViewState createState() => _CardValidationViewState();
}

class _CardValidationViewState extends State<CardValidationView> {
  CameraController? cameraController;
  bool isCameraReady = false;

  bool isCapture = false;
  late CameraImage currentImage;

  late double screenWidth, screenHeight;
  late double _cardAreaLeft, _cardAreaTop, _cardAreaHeight, _cardAreaWidth;

  bool isInit = false;
  CameraDescription? choosenCamera;

  @override
  void initState() {
    super.initState();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    isCapture = false;
    print("Init camera");
    if (cameraController != null) cameraController!.dispose();
    final cameras = await availableCameras();
    choosenCamera = cameras[0];
    print(choosenCamera!.sensorOrientation);

    cameraController = CameraController(choosenCamera!, ResolutionPreset.high,
        enableAudio: false);

    cameraController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController!.value.hasError) {
      print('Camera Error ${cameraController!.value.errorDescription}');
    }

    try {
      await cameraController!.initialize().then((_) => {
            setState(() {
              isCameraReady = true;
            })
          });
    } catch (e) {
      print('Camera Error $e');
    }

    if (mounted) {
      setState(() {});
    }
    if (cameraController != null && cameraController!.value.isInitialized) {
      cameraController!.startImageStream((CameraImage image) {
        currentImage = image;
      });
    }
  }

  Future<void> _disposeCamera() async {
    setState(() {
      isCameraReady = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (cameraController != null) {
        cameraController!.dispose();
        cameraController = null;
      }
    });
  }

  @override
  void dispose() {
    if (cameraController != null) {
      cameraController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInit && choosenCamera != null) {
      isInit = true;
      screenHeight = MediaQuery.of(context).size.height;
      screenWidth = MediaQuery.of(context).size.width;
      getScannerSize();
    }
    return buildBody();
  }

  void getScannerSize() {
    const CARD_ASPECT_RATIO = 1 / 1.5;
    const OFFSET_X_FACTOR = 0.05;

    _cardAreaLeft = OFFSET_X_FACTOR * screenWidth.round();
    _cardAreaWidth = screenWidth.round() - _cardAreaLeft * 2;
    _cardAreaHeight = _cardAreaWidth * CARD_ASPECT_RATIO;
    _cardAreaTop = (screenHeight.round() - _cardAreaHeight) / 2;
  }

  Widget cameraWidget(context) {
    var camera = cameraController!.value;
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * camera.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(cameraController!),
      ),
    );
  }

  Widget buildBody() {
    if (isCameraReady) {
      var camera = cameraController!.value;
      final size = MediaQuery.of(context).size;
      var scale = size.aspectRatio * camera.aspectRatio;
      if (scale < 1) scale = 1 / scale;
      return Container(
        color: Colors.white,
        child: SafeArea(
          child: Scaffold(
            body: SizedBox(
                height: size.height,
                width: size.width,
                child: Stack(
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Center(
                        child: CameraPreview(cameraController!),
                      ),
                    ),
                    Container(
                      decoration: const ShapeDecoration(
                        shape: CardOverlayShape(
                            // overlayColor: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: size.width,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [_buildButtonUsePhotoOrNot()],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        color: ColorsPrimary.Lv1,
                        child: Text(
                          'Vui lòng đặt CCCD/CMND nằm trong vùng chọn. Ảnh chụp trong điều kiện đủ sáng, rõ nét.',
                          style: AppTextStyle.textStyle.s12().w700().cW5(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )),
          ),
        ),
      );
    }
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: ColorsLight.Lv1),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildButtonUsePhotoOrNot() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 42),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Chụp mặt trước của CCCD/CMND',
            style: AppTextStyle.textStyle.s16().w500().cN5(),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: ColorsPrimary.Lv5,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: ColorsPrimary.Lv1,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
