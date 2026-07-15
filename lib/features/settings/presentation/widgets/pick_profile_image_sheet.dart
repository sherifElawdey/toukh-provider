import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toukh_provider/core/media/safe_image_pick.dart';

/// Shows a camera/gallery picker sheet and returns the chosen image file.
Future<File?> pickProfileImage(BuildContext context) =>
    pickImageWithSourceSheet(context);
