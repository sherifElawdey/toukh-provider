import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:toukh_provider/core/media/picked_media.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/core/util/city_key.dart';
import 'package:toukh_provider/core/utils/phone_auth_helpers.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/brand_info.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_profile_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_state.dart';
import 'package:toukh_provider/features/delivery_company/registration/delivery_company_registration_cubit.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/models/registration_submit_data.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/settings/domain/provider_profile_draft_mapper.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:get/get.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required ProviderProfileRepository profileRepository,
    required MediaUploadService mediaUploadService,
    required ProviderGalleryRepository galleryRepository,
    required DeliveryCompanyRepository companyRepository,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _media = mediaUploadService,
       _galleryRepository = galleryRepository,
       _companyRepository = companyRepository,
       super(const AuthInitial());

  final AuthRepository _authRepository;
  final ProviderProfileRepository _profileRepository;
  final MediaUploadService _media;
  final ProviderGalleryRepository _galleryRepository;
  final DeliveryCompanyRepository _companyRepository;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<ProviderProfile?>? _profileSub;
  StreamSubscription<DeliveryCompany?>? _companySub;

  /// A uid is either a provider or a delivery company. Until the company doc
  /// has been read once, a missing provider profile is not yet conclusive.
  DeliveryCompany? _company;
  bool _companyResolved = false;

  /// Suppresses [AuthenticatedNoProfile] between creating the Firebase user
  /// and writing the provider / company doc.
  bool _registeringAccount = false;

  void _logAuth(String message) {
    debugPrint('[AuthFlow][AuthCubit] $message');
  }

  Future<void> subscribe() async {
    await _authSub?.cancel();
    _logAuth('subscribe() -> emit AuthLoading');
    emit(const AuthLoading());
    _authSub = _authRepository.authStateChanges().listen(
      _onFirebaseUserChanged,
    );
  }

  Future<void> _onFirebaseUserChanged(User? user) async {
    await _profileSub?.cancel();
    _profileSub = null;
    await _companySub?.cancel();
    _companySub = null;
    if (user == null) {
      _company = null;
      _companyResolved = false;
      // Sign-up emits its own outcome; a rollback must not leave the wizard.
      if (_registeringAccount) return;
      _logAuth('firebase user changed: null -> emit Unauthenticated');
      emit(const Unauthenticated());
      return;
    }
    if (!_registeringAccount) {
      _logAuth('firebase user changed: uid=${user.uid} -> emit AuthLoading');
      emit(const AuthLoading());
    }
    _watchAccount(user.uid);
  }

  void _watchAccount(String uid) {
    if (_company?.uid != uid) {
      _company = null;
      _companyResolved = false;
    }
    _companySub = _companyRepository
        .watchCompany(uid)
        .listen(
          _onCompanyChanged,
          onError: (Object e) {
            debugPrint('AuthCubit: company watch failed: $e');
            _onCompanyChanged(null);
          },
        );
    _profileSub = _profileRepository
        .watchProfile(uid)
        .listen(_onProviderProfileChanged);
    unawaited(_bootstrapProfile(uid));
  }

  void _onCompanyChanged(DeliveryCompany? company) {
    final user = _authRepository.currentUser;
    if (user == null) return;
    if (company != null && company.uid != user.uid) return;
    final hadCompany = _company != null;
    _company = company;
    _companyResolved = true;
    if (_registeringAccount) return;
    if (company != null) {
      _logAuth(
        'company for uid=${user.uid}: status=${company.status.name}, '
        'phoneVerified=${company.phoneVerified}',
      );
      emit(AuthenticatedCompany(user: user, company: company));
      return;
    }
    // Company doc gone (or never existed): fall back to the provider flow.
    if (hadCompany || state is AuthLoading) {
      unawaited(_bootstrapProfile(user.uid));
    }
  }

  Future<void> _bootstrapProfile(String uid) async {
    try {
      final profile = await _profileRepository
          .getProfile(uid)
          .timeout(const Duration(seconds: 25));
      _onProviderProfileChanged(profile);
    } catch (e, st) {
      debugPrint('AuthCubit: profile bootstrap failed: $e\n$st');
      _onProviderProfileChanged(null);
    }
  }

  void _onProviderProfileChanged(ProviderProfile? profile) {
    // While signing up, an existing account found for the phone must not route
    // the user away from the review step (sign-up emits its own outcome).
    if (_registeringAccount) return;
    final user = _authRepository.currentUser;
    if (user == null) {
      _logAuth('profile changed but currentUser is null -> Unauthenticated');
      emit(const Unauthenticated());
      return;
    }
    final company = _company;
    if (company != null && company.uid == user.uid) {
      return;
    }
    if (profile == null) {
      if (!_companyResolved || _registeringAccount) {
        _logAuth('profile is null for uid=${user.uid}; waiting for company');
        return;
      }
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

  Future<void> signIn({required String phone, required String password}) async {
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
      emit(AuthFailure(message: appFirebaseError(e)));
    }
  }

  /// Creates Firebase user, uploads ID + brand to B2, writes `providers/{uid}`.
  ///
  /// Returns the failure (also emitted) or null on success. Callers should use
  /// the return value: a rollback sign-out can replace the emitted failure.
  Future<AuthFailure?> registerProviderInitial(
    RegistrationSubmitData data,
  ) async {
    _logAuth(
      'registerProviderInitial(phone=${data.phone}) -> emit AuthLoading',
    );
    emit(const AuthLoading());
    final uploaded = <UploadedMedia>[];
    var authUserCreated = false;
    _registeringAccount = true;
    AuthFailure? failure;
    try {
      final area = await getIt<GeofenceService>().findContaining(
        lat: data.lat,
        lng: data.lng,
      );
      if (area == null) {
        failure = AuthFailure(
          message: AppStrings.Registration.locationOutsideServiceArea,
          code: AuthFailure.outsideServiceArea,
        );
        emit(failure);
        return failure;
      }

      final user = await _createOrResumeAuthUser(
        phone: data.phone,
        password: data.password,
      );
      authUserCreated = true;

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
      final fcmToken = await _currentFcmToken();
      final city = data.city?.trim().isNotEmpty == true
          ? data.city!.trim()
          : await resolveUserCityKey(
              lat: data.lat,
              lng: data.lng,
              formattedAddress: data.formattedAddress,
            );

      final profile = ProviderProfile(
        uid: user.uid,
        phone: phoneDigits,
        email: email,
        password: data.password,
        phoneVerified: false,
        serviceType: data.kind,
        shopCategory: data.shopCategory,
        serviceCategoryId: data.serviceCategoryId,
        serviceCategoryTitle: data.serviceCategoryTitle,
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
        city: city,
        serviceAreaId: area.id,
        workingHours: data.workingHours,
        deliveryConfig: data.deliveryConfig,
        avgPrepMinutes: data.avgPrepMinutes,
        cuisineTags: data.cuisineTags,
        preServiceQuestions: data.kind == ServiceType.homeService
            ? data.preServiceQuestions
            : const [],
        status: ProviderAccountStatus.pending,
        b2FileIds: {
          'idFront': idFront.fileId,
          'idBack': idBack.fileId,
          'brand': brand.fileId,
        },
        registrationExtrasComplete: false,
        fcmTokens: fcmToken == null ? const [] : [fcmToken],
        createdAt: now,
        updatedAt: now,
      );
      await _profileRepository.upsertProfile(profile);
      final savedToken = fcmToken ?? await _currentFcmToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        await _profileRepository.addFcmToken(uid: user.uid, token: savedToken);
      }
      final storedTokens = savedToken == null || savedToken.isEmpty
          ? profile.fcmTokens
          : ToukhFcmTokenSync.mergeFcmToken(profile.fcmTokens, savedToken);
      emit(
        Authenticated(
          user: user,
          profile: profile.copyWith(fcmTokens: storedTokens),
        ),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      for (final u in uploaded) {
        await _media.deleteImage(u);
      }
      if (authUserCreated) await _rollbackAuthUser();
      failure = AuthFailure(
        message: e.code == AuthFailure.phoneAlreadyRegistered
            ? AppStrings.Auth.phoneAlreadyRegistered
            : e.message ?? e.code,
        code: e.code,
      );
      emit(failure);
      return failure;
    } catch (e) {
      for (final u in uploaded) {
        await _media.deleteImage(u);
      }
      if (authUserCreated) await _rollbackAuthUser();
      failure = AuthFailure(message: appFirebaseError(e));
      emit(failure);
      return failure;
    } finally {
      _registeringAccount = false;
    }
  }

  /// Creates the Firebase login for a new account. When the phone already has
  /// a login but no `providers/` or `deliveryCompanies/` doc (an earlier
  /// sign-up that failed half-way) and the password matches, that login is
  /// reused so the phone is not locked out forever.
  Future<User> _createOrResumeAuthUser({
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _authRepository.registerWithPhonePassword(
        phone: phone,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw StateError('Firebase did not return a user after registration.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      final User? user;
      try {
        user = (await _authRepository.signInWithPhonePassword(
          phone: phone,
          password: password,
        )).user;
      } on FirebaseAuthException {
        throw e;
      }
      if (user == null) rethrow;
      final hasProfile = await _profileRepository.getProfile(user.uid) != null;
      var hasCompany = false;
      if (!hasProfile) {
        try {
          hasCompany = await _companyRepository.getCompany(user.uid) != null;
        } catch (readError) {
          debugPrint('AuthCubit: company read on resume failed: $readError');
        }
      }
      if (hasProfile || hasCompany) {
        await _authRepository.signOut();
        rethrow;
      }
      _logAuth('resuming orphan login uid=${user.uid} (no account doc)');
      return user;
    }
  }

  /// Deletes the login created by a sign-up that failed before its account
  /// doc was written, so the phone can register again.
  Future<void> _rollbackAuthUser() async {
    try {
      await _authRepository.deleteAccount();
    } catch (e) {
      debugPrint('AuthCubit: registration rollback failed: $e');
      await _authRepository.signOut();
    }
  }

  /// Creates the Firebase user and `deliveryCompanies/{uid}` (unverified).
  Future<void> registerDeliveryCompany(
    DeliveryCompanyRegistrationData data,
  ) async {
    _logAuth('registerDeliveryCompany(phone=${data.phone}) -> AuthLoading');
    emit(const AuthLoading());
    _registeringAccount = true;
    var authUserCreated = false;
    try {
      final area = await getIt<GeofenceService>().findContaining(
        lat: data.lat,
        lng: data.lng,
      );
      if (area == null) {
        emit(
          AuthFailure(
            message: AppStrings.Registration.locationOutsideServiceArea,
          ),
        );
        return;
      }

      final user = await _createOrResumeAuthUser(
        phone: data.phone,
        password: data.password,
      );
      authUserCreated = true;

      final city = data.city?.trim().isNotEmpty == true
          ? data.city!.trim()
          : await resolveUserCityKey(
              lat: data.lat,
              lng: data.lng,
              formattedAddress: data.formattedAddress,
            );
      final company = DeliveryCompany(
        uid: user.uid,
        companyName: data.companyName.trim(),
        managerName: data.managerName.trim(),
        phone: displayDigits(data.phone),
        email: syntheticEmailFromPhone(data.phone),
        phoneVerified: false,
        status: ProviderAccountStatus.unverified,
        lat: data.lat,
        lng: data.lng,
        address: data.formattedAddress,
        city: city,
        serviceAreaId: area.id,
        serviceAreaName: area.name,
      );
      await _companyRepository.createCompany(company);
      _company = company;
      _companyResolved = true;
      emit(AuthenticatedCompany(user: user, company: company));
    } on FirebaseAuthException catch (e) {
      if (authUserCreated) await _rollbackAuthUser();
      emit(AuthFailure(message: e.message ?? e.code));
    } catch (e) {
      if (authUserCreated) await _rollbackAuthUser();
      emit(AuthFailure(message: appFirebaseError(e)));
    } finally {
      _registeringAccount = false;
    }
  }

  /// After a successful OTP: marks the phone verified and asks the server to
  /// activate the company. Activation failures leave the company on the
  /// status screen, which can retry via [activateCompany].
  Future<void> confirmCompanyOtp() async {
    final current = state;
    if (current is! AuthenticatedCompany) {
      emit(AuthFailure(message: AppStrings.Common.notSignedIn.tr));
      return;
    }
    try {
      final uid = current.company.uid;
      if (!current.company.phoneVerified) {
        await _companyRepository.markPhoneVerified(uid);
        _company = current.company.copyWith(phoneVerified: true);
        emit(AuthenticatedCompany(user: current.user, company: _company!));
      }
      await _companyRepository.activate();
    } catch (e) {
      debugPrint('AuthCubit: company activation failed: $e');
    }
  }

  /// Retries server activation for a verified, still-unverified company.
  Future<bool> activateCompany() async {
    try {
      await _companyRepository.activate();
      return true;
    } catch (e) {
      debugPrint('AuthCubit: company activation retry failed: $e');
      return false;
    }
  }

  Future<void> confirmRegistrationOtp() async {
    _logAuth('confirmRegistrationOtp() -> emit AuthLoading');
    emit(const AuthLoading());
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(AuthFailure(message: AppStrings.Common.notSignedIn.tr));
        return;
      }
      final profile = await _profileRepository.getProfile(user.uid);
      if (profile == null) {
        emit(AuthFailure(message: AppStrings.Common.profileNotFound.tr));
        return;
      }
      if (profile.phoneVerified) {
        emit(AuthFailure(message: AppStrings.Auth.phoneAlreadyVerified.tr));
        return;
      }
      final now = DateTime.now();
      final updated = profile.copyWith(phoneVerified: true, updatedAt: now);
      await _profileRepository.upsertProfile(updated);
      emit(Authenticated(user: user, profile: updated));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? e.code));
    } catch (e) {
      emit(AuthFailure(message: appFirebaseError(e)));
    }
  }

  Future<void> markMenuRegistrationComplete() async {
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(AuthFailure(message: AppStrings.Common.notSignedIn.tr));
        return;
      }
      final profile = await _profileRepository.getProfile(user.uid);
      if (profile == null) {
        emit(AuthFailure(message: AppStrings.Common.profileNotFound.tr));
        return;
      }
      final now = DateTime.now();
      final updated = profile.copyWith(
        registrationExtrasComplete: true,
        updatedAt: now,
      );
      await _profileRepository.upsertProfile(updated);

      emit(
        Authenticated(user: user, profile: await _afterSignUpFinished(updated)),
      );
    } catch (e) {
      emit(AuthFailure(message: appFirebaseError(e)));
    }
  }

  Future<void> submitRegistrationPortfolio(List<PickedMedia> files) async {
    emit(const AuthLoading());
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(AuthFailure(message: AppStrings.Common.notSignedIn.tr));
        return;
      }

      if (files.isNotEmpty) {
        await _galleryRepository.addImages(user.uid, files);
      }

      final profile = await _profileRepository.getProfile(user.uid);
      if (profile == null) {
        emit(AuthFailure(message: AppStrings.Common.profileNotFound.tr));
        return;
      }

      if (!profile.registrationExtrasComplete) {
        final updated = profile.copyWith(
          registrationExtrasComplete: true,
          updatedAt: DateTime.now(),
        );
        await _profileRepository.upsertProfile(updated);
        emit(
          Authenticated(
            user: user,
            profile: await _afterSignUpFinished(updated),
          ),
        );
      } else {
        emit(Authenticated(user: user, profile: profile));
      }
    } catch (e) {
      emit(AuthFailure(message: appFirebaseError(e)));
    }
  }

  /// Asks the server to activate the account when admin review is turned off
  /// for providers. Returns the fresh profile so the router skips the
  /// "under review" screen; on failure the account stays pending and
  /// [completeVerification] retries from that screen.
  Future<ProviderProfile> _afterSignUpFinished(ProviderProfile profile) async {
    try {
      await _profileRepository.completeVerification();
      return await _profileRepository.getProfile(profile.uid) ?? profile;
    } catch (e) {
      debugPrint('AuthCubit: completeVerification failed: $e');
      return profile;
    }
  }

  /// Re-checks activation from the "under review" screen (e.g. admin turned
  /// review off after this provider signed up). The profile stream picks up
  /// the new status.
  Future<void> completeVerification() async {
    final current = state;
    if (current is! Authenticated ||
        current.profile.status == ProviderAccountStatus.active) {
      return;
    }
    try {
      await _profileRepository.completeVerification();
    } catch (e) {
      debugPrint('AuthCubit: completeVerification retry failed: $e');
    }
  }

  /// Uploads a new brand/profile image, persists it, then deletes the previous
  /// B2 file when [b2FileIds]['brand'] is known.
  Future<void> updateBrandImage(PickedMedia image) async {
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
    var updated = ProviderProfileDraftMapper.applyDraft(
      current.profile,
      draft,
      field,
    );
    if (field == ReviewField.location &&
        draft.lat != null &&
        draft.lng != null) {
      final city = draft.city?.trim().isNotEmpty == true
          ? draft.city!.trim()
          : await resolveUserCityKey(
              lat: draft.lat!,
              lng: draft.lng!,
              formattedAddress: draft.formattedAddress,
            );
      // Draft coordinates are the pin just saved, not the previous profile point.
      final area = await getIt<GeofenceService>().findContaining(
        lat: draft.lat!,
        lng: draft.lng!,
      );
      if (area == null) {
        throw StateError('location_outside_service_area');
      }
      updated = updated.copyWith(city: city, serviceAreaId: area.id);
    }
    await _profileRepository.upsertProfile(updated);
    emit(Authenticated(user: current.user, profile: updated));
  }

  /// Persists public brand contacts from the brand information screen.
  Future<void> updateBrandInfo(BrandInfo brandInfo) async {
    final current = state;
    if (current is! Authenticated) {
      throw StateError('Not signed in.');
    }
    final updated = current.profile.copyWith(
      brandInfo: brandInfo.normalized(),
      updatedAt: DateTime.now(),
    );
    await _profileRepository.upsertProfile(updated);
    emit(Authenticated(user: current.user, profile: updated));
  }

  /// Updates restaurant cuisine tags from the Menu tab editor.
  Future<void> updateCuisineTags(List<String> tags) async {
    final current = state;
    if (current is! Authenticated) {
      throw StateError('Not signed in.');
    }
    final updated = current.profile.copyWith(
      cuisineTags: RestaurantCuisineTaxonomy.sanitize(tags),
      updatedAt: DateTime.now(),
    );
    await _profileRepository.upsertProfile(updated);
    emit(Authenticated(user: current.user, profile: updated));
  }

  Future<String?> _currentFcmToken() async {
    try {
      return await ToukhPushMessaging.instance.getToken().timeout(
        const Duration(seconds: 4),
      );
    } catch (e, st) {
      debugPrint('AuthCubit: FCM token unavailable during register: $e\n$st');
      return null;
    }
  }

  Future<void> signOut() async {
    final uid = _authRepository.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await ToukhPushMessaging.instance.removeDeviceTokenOnSignOut(uid);
      } catch (_) {
        // Never block sign-out on FCM cleanup.
      }
    }
    await _authRepository.signOut();
  }

  /// Appends a version query param so [Image.network] fetches the new file
  /// when the underlying B2 object path is unchanged.
  static String _cacheBustedImageUrl(String url, String version) {
    final uri = Uri.parse(url);
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'v': version})
        .toString();
  }

  /// Re-fetch the provider profile without dropping the current state.
  Future<void> refreshProfile() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(const Unauthenticated());
      return;
    }
    if (_company != null) {
      try {
        _onCompanyChanged(await _companyRepository.getCompany(user.uid));
      } catch (e) {
        debugPrint('AuthCubit: company refresh failed: $e');
      }
      return;
    }
    await _bootstrapProfile(user.uid);
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
    await _companySub?.cancel();
    _companySub = null;
    _watchAccount(user.uid);
  }

  @override
  Future<void> close() async {
    await _companySub?.cancel();
    await _profileSub?.cancel();
    await _authSub?.cancel();
    return super.close();
  }
}
