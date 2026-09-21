import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Shared Phosphor [IconData] tokens for Toukh apps (Regular + Fill).
abstract final class ToukhIcons {
  // Navigation
  static IconData get home => PhosphorIconsRegular.house;
  static IconData get homeSelected => PhosphorIconsFill.house;

  static IconData get orders => PhosphorIconsRegular.receipt;
  static IconData get ordersSelected => PhosphorIconsFill.receipt;

  static IconData get settings => PhosphorIconsRegular.gear;
  static IconData get settingsSelected => PhosphorIconsFill.gear;

  static IconData get menu => PhosphorIconsRegular.forkKnife;
  static IconData get menuSelected => PhosphorIconsFill.forkKnife;

  static IconData get gallery => PhosphorIconsRegular.images;
  static IconData get gallerySelected => PhosphorIconsFill.images;

  static IconData get profile => PhosphorIconsRegular.user;
  static IconData get profileSelected => PhosphorIconsFill.user;

  static IconData get qaima => PhosphorIconsRegular.listBullets;
  static IconData get qaimaSelected => PhosphorIconsFill.listBullets;

  // Actions
  static IconData get cart => PhosphorIconsRegular.shoppingCart;
  static IconData get cartSelected => PhosphorIconsFill.shoppingCart;

  static IconData get notifications => PhosphorIconsRegular.bell;
  static IconData get notificationsSelected => PhosphorIconsFill.bell;

  static IconData get back => PhosphorIconsRegular.arrowLeft;
  static IconData get forward => PhosphorIconsRegular.arrowRight;
  static IconData get close => PhosphorIconsRegular.x;
  static IconData get moreVertical => PhosphorIconsRegular.dotsThreeVertical;
  static IconData get moreHorizontal => PhosphorIconsRegular.dotsThree;

  static IconData get add => PhosphorIconsRegular.plus;
  static IconData get remove => PhosphorIconsRegular.minus;
  static IconData get delete => PhosphorIconsRegular.trash;
  static IconData get edit => PhosphorIconsRegular.pencilSimple;
  static IconData get check => PhosphorIconsRegular.check;
  static IconData get search => PhosphorIconsRegular.magnifyingGlass;

  static IconData get location => PhosphorIconsRegular.mapPin;
  static IconData get navigation => PhosphorIconsRegular.navigationArrow;

  static IconData get lock => PhosphorIconsRegular.lock;
  static IconData get visibility => PhosphorIconsRegular.eye;
  static IconData get visibilityOff => PhosphorIconsRegular.eyeSlash;

  // Status / feedback
  static IconData get info => PhosphorIconsRegular.info;
  static IconData get warning => PhosphorIconsRegular.warning;
  static IconData get error => PhosphorIconsRegular.warningCircle;
  static IconData get success => PhosphorIconsRegular.checkCircle;

  static IconData get star => PhosphorIconsRegular.star;
  static IconData get starFilled => PhosphorIconsFill.star;

  static IconData get heart => PhosphorIconsRegular.heart;
  static IconData get heartFilled => PhosphorIconsFill.heart;

  static IconData get clock => PhosphorIconsRegular.clock;
  static IconData get calendar => PhosphorIconsRegular.calendarBlank;

  static IconData get phone => PhosphorIconsRegular.phone;
  static IconData get email => PhosphorIconsRegular.envelopeSimple;
  static IconData get chat => PhosphorIconsRegular.chatCircle;
  static IconData get send => PhosphorIconsRegular.paperPlaneTilt;

  static IconData get camera => PhosphorIconsRegular.camera;
  static IconData get image => PhosphorIconsRegular.image;
  static IconData get upload => PhosphorIconsRegular.uploadSimple;

  static IconData get wallet => PhosphorIconsRegular.wallet;
  static IconData get delivery => PhosphorIconsRegular.truck;
  static IconData get store => PhosphorIconsRegular.storefront;

  static IconData get arrowCircleUp => PhosphorIconsRegular.arrowCircleUp;
  static IconData get refresh => PhosphorIconsRegular.arrowsClockwise;
  static IconData get logout => PhosphorIconsRegular.signOut;
  static IconData get language => PhosphorIconsRegular.translate;

  static IconData get document => PhosphorIconsRegular.fileText;
  static IconData get privacy => PhosphorIconsRegular.shield;
  static IconData get article => PhosphorIconsRegular.article;

  static IconData get category => PhosphorIconsRegular.squaresFour;
  static IconData get restaurant => PhosphorIconsRegular.forkKnife;

  static IconData get online => PhosphorIconsRegular.circle;
  static IconData get onlineFilled => PhosphorIconsFill.circle;

  static IconData get chevronDown => PhosphorIconsRegular.caretDown;
  static IconData get chevronUp => PhosphorIconsRegular.caretUp;
  static IconData get chevronRight => PhosphorIconsRegular.caretRight;
  static IconData get expand => PhosphorIconsRegular.caretDown;

  static IconData get attach => PhosphorIconsRegular.paperclip;
  static IconData get mic => PhosphorIconsRegular.microphone;
  static IconData get copy => PhosphorIconsRegular.copy;

  static IconData get history => PhosphorIconsRegular.clockCounterClockwise;
  static IconData get filter => PhosphorIconsRegular.funnel;
  static IconData get sort => PhosphorIconsRegular.sortAscending;

  static IconData get person => PhosphorIconsRegular.userCircle;
  static IconData get group => PhosphorIconsRegular.users;

  static IconData get lightMode => PhosphorIconsRegular.sun;
  static IconData get darkMode => PhosphorIconsRegular.moon;

  static IconData get permissions => PhosphorIconsRegular.shieldCheck;
  static IconData get locationPermission => PhosphorIconsRegular.mapPinLine;
  static IconData get notificationPermission => PhosphorIconsRegular.bellRinging;

  static IconData get vehicle => PhosphorIconsRegular.car;
  static IconData get motorcycle => PhosphorIconsRegular.motorcycle;
  static IconData get bicycle => PhosphorIconsRegular.bicycle;

  static IconData get qrCode => PhosphorIconsRegular.qrCode;
  static IconData get share => PhosphorIconsRegular.shareNetwork;

  static IconData get freeDelivery => PhosphorIconsRegular.gift;
  static IconData get rating => PhosphorIconsRegular.star;

  static IconData get empty => PhosphorIconsRegular.tray;
  static IconData get placeholder => PhosphorIconsRegular.image;
}
