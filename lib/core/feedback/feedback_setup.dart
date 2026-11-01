import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/core/media/picked_media.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Wires the shared complaints & suggestions screens (toukh_ui ToukhFeedback).
void configureFeedback() {
  ToukhFeedback.configure(
    app: ToukhAccountApp.provider,
    uploadImage: (file, path) async {
      final media = PickedMedia(bytes: await file.readAsBytes(), name: file.name, filePath: file.path);
      return (await getIt<MediaUploadService>().uploadImage(source: media, objectPath: path)).url;
    },
    currentUser: () {
      final auth = getIt<AuthCubit>().state;
      return auth is Authenticated
          ? (name: auth.profile.name, phone: auth.profile.phone)
          : (name: null, phone: null);
    },
    errorMessage: appFirebaseError,
  );
}
