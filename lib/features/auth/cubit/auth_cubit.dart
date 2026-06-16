import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/core/utils/phone_auth_helpers.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_profile_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_state.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/models/registration_submit_data.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/settings/domain/provider_profile_draft_mapper.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required ProviderProfileRepository profileRepository,
    required MediaUploadService mediaUploadService,
    required ProviderGalleryRepository galleryRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        _media = mediaUploadService,
        _galleryRepository = galleryRepository,
        super(const AuthInitial());

  final AuthRepository _authRepository;
  final ProviderProfileRepository _profileRepository;
  final MediaUploadService _media;
  final ProviderGalleryRepository _galleryRepository;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<ProviderProfile?>? _profileSub;

  void _logAuth(String message) {
    debugPrint('[AuthFlow][AuthCubit] $message');
  }

  Future<void> subscribe() async {
    await _authSub?.cancel();
    _logAuth('subscribe() -> emit AuthLoading');
    emit(const AuthLoading());
    _authSub = _authRepository.authStateChanges().listen(_onFirebaseUserChanged);
  }

  Future<void> _onFirebaseUserChanged(User? user) async {
    await _profileSub?.cancel();
    _profileSub = null;
    if (user == null) {
      _logAuth('firebase user changed: null -> emit Unauthenticated');
      emit(const Unauthenticated());
      return;
    }
    _logAuth('firebase user changed: uid=${user.uid} -> emit AuthLoading');
    emit(const AuthLoading());
    _profileSub = _profileRepository
        .watchProfile(user.uid)
        .listen(_onProviderProfileChanged);
    unawaited(_bootstrapProfile(user.uid));
  }

  Future<void> _bootstrapProfile(String uid) async {
    try {
      final profile = await _profileRepository.getProfile(uid).timeout(
            const Duration(seconds: 25),
          );
      _onProviderProfileChanged(profile);
    } catch (e, st) {
      debugPrint('AuthCubit: profile bootstrap failed: $e\n$st');
      _onProviderProfileChanged(null);
    }
  }

  void _onProviderProfileChanged(ProviderProfile? profile) {
    final user = _authRepository.currentUser;
    if (user == null) {
      _logAuth('profile changed but currentUser is null -> Unauthenticated');
      emit(const Unauthenticated());
      return;
    }
    if (profile == null) {
      _logAuth('profile is null for uid=${user.uid} -> AuthenticatedNoProfile');
      emit(AuthenticatedNoProfile(user: user));
      return;
    }
    _logAuth(
      'profile for uid=${user.uid}: status=${profile.status.name}, '
      'phoneVerified=${profile.phoneVerified}, extrasComplete=${profile.registrationExtrasComplete}',
    );
    emit(Authenticated(user: user, profile: profile));
  }

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    _logAuth('signIn(phone=$phone) -> emit AuthLoading');
    emit(const AuthLoading());
    try {
      await _authRepository.signInWithPhonePassword(
        phone: phone,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? e.code));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  /// Creates Firebase user, uploads ID + brand to B2, writes `providers/{uid}`.
  Future<void> registerProviderInitial(RegistrationSubmitData data) async {
    _logAuth('registerProviderInitial(phone=${data.phone}) -> emit AuthLoading');
    emit(const AuthLoading());
    final uploaded = <UploadedMedia>[];
    try {
      final cred = await _authRepository.registerWithPhonePassword(
        phone: data.phone,
        password: data.password,
      );
      final user = cred.user;
      if (user == null) {
        throw StateError('Firebase did not return a user after registration.');
      }

      final base = 'providers/${user.uid}';
      final idFront = await _media.uploadImage(
        source: data.idFront,
        objectPath: '$base/id_front.jpg',
      );
      uploaded.add(idFront);
      final idBack = await _media.uploadImage(
        source: data.idBack,
        objectPath: '$base/id_back.jpg',
      );
      uploaded.add(idBack);
      final brand = await _media.uploadImage(
        source: data.brandImage,
        objectPath: '$base/brand.jpg',
      );
      uploaded.add(brand);

      final phoneDigits = displayDigits(data.phone);
      final now = DateTime.now();
      final email = syntheticEmailFromPhone(data.phone);

      final profile = ProviderProfile(
        uid: user.uid,
        phone: phoneDigits,
        email: email,
        password: data.password,
        phoneVerified: false,
        serviceType: data.kind,
        shopCategory: data.shopCategory,
        serviceCategoryId: data.serviceCategoryId,
        name: data.name.trim(),
        description: data.description.trim().isEmpty
            ? null
            : data.description.trim(),
        brandImageUrl: brand.url,
        idFrontUrl: idFront.url,
        idBackUrl: idBack.url,
        lat: data.lat,
        lng: data.lng,
        address: data.formattedAddress,
        workingHours: data.workingHours,
        deliveryConfig: data.deliveryConfig,
        avgPrepMinutes: data.avgPrepMinutes,
        status: ProviderAccountStatus.pending,
        b2FileIds: {
          'idFront': idFront.fileId,
          'idBack': idBack.fileId,
          'brand': brand.fileId,
        },
        registrationExtrasComplete: false,
        createdAt: now,
        updatedAt: now,
      );
      await _profileRepository.upsertProfile(profile);
      emit(Authenticated(user: user, profile: profile));
    } on FirebaseAuthException catch (e) {
      for (final u in uploaded) {
        await _media.deleteImage(u);
      }
      emit(AuthFailure(message: e.message ?? e.code));
    } catch (e) {
      for (final u in uploaded) {
        await _media.deleteImage(u);
      }
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> confirmRegistrationOtp() async {
    _logAuth('confirmRegistrationOtp() -> emit AuthLoading');
    emit(const AuthLoading());
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(AuthFailure(message: 'Not signed in.'));
        return;
      }
      final profile = await _profileRepository.getProfile(user.uid);
      if (profile == null) {
        emit(AuthFailure(message: 'Profile not found.'));
        return;
      }
      if (profile.phoneVerified) {
        emit(AuthFailure(message: 'Phone already verified.'));
        return;
      }
      final now = DateTime.now();
      final updated = profile.copyWith(
        phoneVerified: true,
        updatedAt: now,
      );
      await _profileRepository.upsertProfile(updated);
      emit(Authenticated(user: user, profile: updated));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? e.code));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> markMenuRegistrationComplete() async {
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(const AuthFailure(message: 'Not signed in.'));
        return;
      }
      final profile = await _profileRepository.getProfile(user.uid);
      if (profile == null) {
        emit(const AuthFailure(message: 'Profile not found.'));
        return;
      }
      final now = DateTime.now();
      final updated = profile.copyWith(
        registrationExtrasComplete: true,
        updatedAt: now,
      );
      await _profileRepository.upsertProfile(updated);

      emit(Authenticated(user: user, profile: updated));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> submitRegistrationPortfolio(List<File> files) async {
    emit(const AuthLoading());
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(const AuthFailure(message: 'Not signed in.'));
        return;
      }

      if (files.isNotEmpty) {
        await _galleryRepository.addImages(user.uid, files);
      }

      final profile = await _profileRepository.getProfile(user.uid);
      if (profile == null) {
        emit(const AuthFailure(message: 'Profile not found.'));
        return;
      }

      if (!profile.registrationExtrasComplete) {
        final updated = profile.copyWith(
          registrationExtrasComplete: true,
          updatedAt: DateTime.now(),
        );
        await _profileRepository.upsertProfile(updated);
        emit(Authenticated(user: user, profile: updated));
      } else {
        emit(Authenticated(user: user, profile: profile));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  /// Uploads a new brand/profile image, persists it, then deletes the previous
  /// B2 file when [b2FileIds]['brand'] is known.
  Future<void> updateBrandImage(File image) async {
    final current = state;
    if (current is! Authenticated) {
      throw StateError('Not signed in.');
    }

    final profile = current.profile;
    final uid = profile.uid;
    final objectPath = 'providers/$uid/brand.jpg';
    final oldFileId = profile.b2FileIds['brand'];

    final uploaded = await _media.uploadImage(
      source: image,
      objectPath: objectPath,
    );

    final updated = profile.copyWith(
      brandImageUrl: _cacheBustedImageUrl(uploaded.url, uploaded.fileId),
      b2FileIds: {...profile.b2FileIds, 'brand': uploaded.fileId},
      updatedAt: DateTime.now(),
    );

    try {
      await _profileRepository.upsertProfile(updated);
      emit(Authenticated(user: current.user, profile: updated));
    } catch (e) {
      await _media.deleteImage(uploaded);
      rethrow;
    }

    if (oldFileId != null && oldFileId.isNotEmpty) {
      await _media.deleteImage(
        UploadedMedia(
          url: profile.brandImageUrl ?? '',
          fileName: objectPath,
          fileId: oldFileId,
        ),
      );
    }
  }

  /// Persists a single profile field edited via account details.
  Future<void> updateProfileField(
    ReviewField field,
    RegistrationDraft draft,
  ) async {
    final current = state;
    if (current is! Authenticated) {
      throw StateError('Not signed in.');
    }
    final updated = ProviderProfileDraftMapper.applyDraft(
      current.profile,
      draft,
      field,
    );
    await _profileRepository.upsertProfile(updated);
    emit(Authenticated(user: current.user, profile: updated));
  }

  Future<void> signOut() => _authRepository.signOut();

  /// Appends a version query param so [Image.network] fetches the new file
  /// when the underlying B2 object path is unchanged.
  static String _cacheBustedImageUrl(String url, String version) {
    final uri = Uri.parse(url);
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'v': version,
      },
    ).toString();
  }

  Future<void> dismissFailure() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(const Unauthenticated());
      return;
    }
    emit(const AuthLoading());
    await _profileSub?.cancel();
    _profileSub = null;
    _profileSub = _profileRepository
        .watchProfile(user.uid)
        .listen(_onProviderProfileChanged);
    unawaited(_bootstrapProfile(user.uid));
  }

  @override
  Future<void> close() async {
    await _profileSub?.cancel();
    await _authSub?.cancel();
    return super.close();
  }
}
