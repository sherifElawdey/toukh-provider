import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

const _tag = '[ToukhProvider][ImagePick]';

void _log(String message, [Object? error, StackTrace? stack]) {
  final buf = StringBuffer('$_tag $message');
  if (error != null) buf.write(' | error=$error');
  debugPrint(buf.toString());
  if (stack != null) debugPrint('$_tag stack:\n$stack');
}

/// Install once from [main] so picker / platform failures are visible in console.
void installImagePickErrorLogging() {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint('$_tag FlutterError: ${details.exceptionAsString()}');
    debugPrint('$_tag FlutterError stack:\n${details.stack}');
    previousFlutter?.call(details);
  };

  final previousPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('$_tag PlatformDispatcher error: $error');
    debugPrint('$_tag PlatformDispatcher stack:\n$stack');
    return previousPlatform?.call(error, stack) ?? true;
  };
  debugPrint('$_tag error logging installed');
}

/// Picks an image from [source] with logging. No Flutter modal underneath.
Future<File?> pickImageFromSource(
  BuildContext context,
  ImageSource source,
) async {
  _log('pickImageFromSource start source=$source mounted=${context.mounted}');
  if (!context.mounted) {
    _log('aborted: context not mounted before pick');
    return null;
  }

  try {
    _log('calling ImagePicker.pickImage…');
    final res = await ImagePicker().pickImage(
      source: source,
      // Avoid aggressive re-encode on pick; compress later on upload if needed.
      // Some iOS versions crash while scaling HEIC during pick.
      requestFullMetadata: false,
    );
    _log('pickImage returned path=${res?.path}');
    if (res == null) {
      _log('user cancelled or null result');
      return null;
    }
    final file = File(res.path);
    final exists = await file.exists();
    final length = exists ? await file.length() : -1;
    _log('file exists=$exists bytes=$length');
    if (!exists) {
      _log('picked path does not exist on disk');
      if (context.mounted) {
        AppSnack.show(
          context,
          message: 'Could not read the selected image. Please try again.',
          state: AppSnackState.error,
          icon: PhosphorIconsRegular.imageBroken,
        );
      }
      return null;
    }
    return file;
  } on PlatformException catch (e, st) {
    _log(
      'PlatformException code=${e.code} message=${e.message} details=${e.details}',
      e,
      st,
    );
    if (context.mounted) {
      AppSnack.show(
        context,
        message: e.message?.isNotEmpty == true
            ? e.message!
            : appFirebaseError(e),
        state: AppSnackState.error,
        icon: PhosphorIconsRegular.imageBroken,
      );
    }
    return null;
  } catch (e, st) {
    _log('unexpected error', e, st);
    if (context.mounted) {
      AppSnack.show(
        context,
        message: appFirebaseError(e),
        state: AppSnackState.error,
        icon: PhosphorIconsRegular.imageBroken,
      );
    }
    return null;
  }
}

/// Chooses camera/gallery via a Flutter [showMenu] overlay (not a modal sheet).
///
/// Modal bottom sheets map to UIKit presentations; opening PHPicker while that
/// sheet is dismissing races and can kill the app on modern iOS (UIScene).
Future<File?> pickImageWithSourceSheet(BuildContext context) async {
  _log('pickImageWithSourceSheet start');
  if (!context.mounted) {
    _log('aborted: context not mounted');
    return null;
  }

  final box = context.findRenderObject();
  RelativeRect position;
  if (box is RenderBox && box.hasSize) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;
    position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + size.height * 0.35,
      (overlay?.size.width ?? size.width) - topLeft.dx - size.width,
      (overlay?.size.height ?? size.height) - topLeft.dy - size.height * 0.35,
    );
    _log('menu position=$position');
  } else {
    position = const RelativeRect.fromLTRB(64, 200, 64, 200);
    _log('menu fallback position (no RenderBox)');
  }

  ImageSource? source;
  try {
    source = await showMenu<ImageSource>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: ImageSource.camera,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(ToukhIcons.camera),
            title: CustomText(AppStrings.Settings.takePhoto),
          ),
        ),
        PopupMenuItem(
          value: ImageSource.gallery,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(ToukhIcons.gallery),
            title: CustomText(AppStrings.Settings.pickFromGallery),
          ),
        ),
      ],
    );
  } catch (e, st) {
    _log('showMenu failed', e, st);
    return null;
  }

  _log('menu closed source=$source');
  if (source == null || !context.mounted) return null;

  // Overlay menus usually need no delay; still yield a frame so the menu
  // route is fully gone before UIKit presents PHPicker/UIImagePicker.
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) {
    _log('aborted: context unmounted after menu');
    return null;
  }

  return pickImageFromSource(context, source);
}

/// Convenience for registration cards that pass an [onPicked] callback.
Future<void> pickImageInto(
  BuildContext context,
  void Function(File) onPicked,
) async {
  _log('pickImageInto');
  final file = await pickImageWithSourceSheet(context);
  if (file != null) {
    _log('invoking onPicked path=${file.path}');
    onPicked(file);
  } else {
    _log('onPicked skipped (null file)');
  }
}
