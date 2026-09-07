import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Reson'**
  String get appTitle;

  /// No description provided for @publisher.
  ///
  /// In en, this message translates to:
  /// **'By TheDarkingStudios'**
  String get publisher;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your identity. Every connection.'**
  String get tagline;

  /// No description provided for @introEyebrow.
  ///
  /// In en, this message translates to:
  /// **'CONNECTIONS WITH IDENTITY'**
  String get introEyebrow;

  /// No description provided for @introTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next connection\nstarts with you.'**
  String get introTitle;

  /// No description provided for @introBody.
  ///
  /// In en, this message translates to:
  /// **'Every side of your professional life, in one place. Share who you are and leave a lasting impression.'**
  String get introBody;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get start;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @introFoot.
  ///
  /// In en, this message translates to:
  /// **'Designed for people who connect.'**
  String get introFoot;

  /// No description provided for @featureOne.
  ///
  /// In en, this message translates to:
  /// **'One account. Every side of you.'**
  String get featureOne;

  /// No description provided for @featureOneBody.
  ///
  /// In en, this message translates to:
  /// **'Your corporate, freelance and personal profiles, each with its own identity.'**
  String get featureOneBody;

  /// No description provided for @featureTwo.
  ///
  /// In en, this message translates to:
  /// **'Make it uniquely yours.'**
  String get featureTwo;

  /// No description provided for @featureTwoBody.
  ///
  /// In en, this message translates to:
  /// **'Colors, logos and details that speak for your brand.'**
  String get featureTwoBody;

  /// No description provided for @featureThree.
  ///
  /// In en, this message translates to:
  /// **'Connect without friction.'**
  String get featureThree;

  /// No description provided for @featureThreeBody.
  ///
  /// In en, this message translates to:
  /// **'Share your card with a QR code. No app installation needed.'**
  String get featureThreeBody;

  /// No description provided for @sampleName.
  ///
  /// In en, this message translates to:
  /// **'Alex Morgan'**
  String get sampleName;

  /// No description provided for @sampleRole.
  ///
  /// In en, this message translates to:
  /// **'Product designer'**
  String get sampleRole;

  /// No description provided for @sampleCompany.
  ///
  /// In en, this message translates to:
  /// **'STUDIO NORTH'**
  String get sampleCompany;

  /// No description provided for @sampleLabel.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW · SAMPLE CARD'**
  String get sampleLabel;

  /// No description provided for @samplePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get samplePersonal;

  /// No description provided for @sampleWork.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get sampleWork;

  /// No description provided for @sampleFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get sampleFreelance;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Good to see\nyou again.'**
  String get loginTitle;

  /// No description provided for @loginBody.
  ///
  /// In en, this message translates to:
  /// **'Step into your space and keep making connections.'**
  String get loginBody;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next chapter\nstarts here.'**
  String get registerTitle;

  /// No description provided for @registerBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account for every side of your professional identity.'**
  String get registerBody;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you\nconnected again.'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a link to choose a new password.'**
  String get resetBody;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@company.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get nameHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get register;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get reset;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgot;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Reson?'**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyAccount;

  /// No description provided for @backLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backLogin;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @passwordHelp.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordHelp;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Please fill in this field.'**
  String get required;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @shortPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get shortPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get passwordMismatch;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use no more than 80 characters.'**
  String get nameTooLong;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, you\'ll receive a password reset link. Check your spam folder too.'**
  String get resetSuccess;

  /// No description provided for @authInvalid.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you in. Check your email and password.'**
  String get authInvalid;

  /// No description provided for @authEmailUsed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create an account with this email. Try signing in or resetting your password.'**
  String get authEmailUsed;

  /// No description provided for @authWeak.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get authWeak;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check your connection and try again.'**
  String get authNetwork;

  /// No description provided for @authRate.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authRate;

  /// No description provided for @authDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is unavailable. Contact the administrator.'**
  String get authDisabled;

  /// No description provided for @authGeneric.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete your request. Please try again.'**
  String get authGeneric;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t available yet. Please try again later.'**
  String get authUnavailable;

  /// No description provided for @setupNotice.
  ///
  /// In en, this message translates to:
  /// **'We\'re preparing access to Reson. You can explore the screens; registration and sign-in will be available soon.'**
  String get setupNotice;

  /// No description provided for @authSideTitle.
  ///
  /// In en, this message translates to:
  /// **'More than a card.\nYour way to connect.'**
  String get authSideTitle;

  /// No description provided for @authSideBody.
  ///
  /// In en, this message translates to:
  /// **'A presence for every side of your professional life.'**
  String get authSideBody;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your space, your connections.'**
  String get homeTitle;

  /// No description provided for @homeBody.
  ///
  /// In en, this message translates to:
  /// **'You now have a Reson account. This is where we\'ll start building your digital cards.'**
  String get homeBody;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your first card is on its way'**
  String get homeEmpty;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The profile editor is the next step. Your session is ready.'**
  String get homeEmptyBody;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'SIGNED IN'**
  String get signedIn;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Opening your space…'**
  String get loading;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get language;

  /// No description provided for @emailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Your email isn\'t verified yet.'**
  String get emailUnverified;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Send verification'**
  String get verifyEmail;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification link sent. Check your email.'**
  String get verificationSent;

  /// No description provided for @refreshVerification.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified it'**
  String get refreshVerification;

  /// No description provided for @secureNote.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email and password.'**
  String get secureNote;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email\nto continue.'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is awaiting activation. Open the verification link we sent to:'**
  String get verifyBody;

  /// No description provided for @verifyPending.
  ///
  /// In en, this message translates to:
  /// **'Your email is still unverified. Open the link and check again.'**
  String get verifyPending;

  /// No description provided for @verifySpam.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder too. If you entered the wrong email, sign out and register with the correct address.'**
  String get verifySpam;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resendEmail;

  /// No description provided for @myCards.
  ///
  /// In en, this message translates to:
  /// **'My cards'**
  String get myCards;

  /// No description provided for @cardsIntro.
  ///
  /// In en, this message translates to:
  /// **'An identity for every way you connect.'**
  String get cardsIntro;

  /// No description provided for @newCard.
  ///
  /// In en, this message translates to:
  /// **'Create card'**
  String get newCard;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get editCard;

  /// No description provided for @saveCard.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get saveCard;

  /// No description provided for @cardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardLabel;

  /// No description provided for @cardLabelHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Corporate or Freelance'**
  String get cardLabelHint;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Role or specialty'**
  String get jobTitle;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @brandColor.
  ///
  /// In en, this message translates to:
  /// **'Your brand color'**
  String get brandColor;

  /// No description provided for @previewCard.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get previewCard;

  /// No description provided for @cardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first impression starts here.'**
  String get cardEmptyTitle;

  /// No description provided for @cardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first card with your details and your brand color.'**
  String get cardEmptyBody;

  /// No description provided for @cardLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your cards. Please try again in a moment.'**
  String get cardLoadError;

  /// No description provided for @cardSaveError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your changes. Check your connection and try again.'**
  String get cardSaveError;

  /// No description provided for @cardNotFound.
  ///
  /// In en, this message translates to:
  /// **'This card is no longer available.'**
  String get cardNotFound;

  /// No description provided for @invalidWebsite.
  ///
  /// In en, this message translates to:
  /// **'Use an address starting with https:// or http://.'**
  String get invalidWebsite;

  /// No description provided for @invalidColor.
  ///
  /// In en, this message translates to:
  /// **'Use a hex color, for example #7860E9.'**
  String get invalidColor;

  /// No description provided for @maxLength.
  ///
  /// In en, this message translates to:
  /// **'This text is too long.'**
  String get maxLength;

  /// No description provided for @activeCard.
  ///
  /// In en, this message translates to:
  /// **'Active card'**
  String get activeCard;

  /// No description provided for @activateCard.
  ///
  /// In en, this message translates to:
  /// **'Use this card'**
  String get activateCard;

  /// No description provided for @privateCard.
  ///
  /// In en, this message translates to:
  /// **'Private · Only you can see it'**
  String get privateCard;

  /// No description provided for @savedCard.
  ///
  /// In en, this message translates to:
  /// **'Card saved'**
  String get savedCard;

  /// No description provided for @backCards.
  ///
  /// In en, this message translates to:
  /// **'Back to my cards'**
  String get backCards;

  /// No description provided for @savingCard.
  ///
  /// In en, this message translates to:
  /// **'Saving changes…'**
  String get savingCard;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get cardDetails;

  /// No description provided for @cardEditorBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the side of yourself you want to present. You can edit it later.'**
  String get cardEditorBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes haven\'t been saved yet.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @designChooseAJPGPNGOrWebP.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG or WebP image up to 3 MB.'**
  String get designChooseAJPGPNGOrWebP;

  /// No description provided for @designPhotoUploadFailedTryAgainOr.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed. Try again or remove it to save your card without a photo.'**
  String get designPhotoUploadFailedTryAgainOr;

  /// No description provided for @designAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get designAboutYou;

  /// No description provided for @designForWorkFeatureYourRoleCompany.
  ///
  /// In en, this message translates to:
  /// **'For work: feature your role, company and work email. Use a photo with a clean background.'**
  String get designForWorkFeatureYourRoleCompany;

  /// No description provided for @designForFreelanceExplainYourServicesIn.
  ///
  /// In en, this message translates to:
  /// **'For freelance: explain your services in one sentence and add your portfolio. Show a contact channel.'**
  String get designForFreelanceExplainYourServicesIn;

  /// No description provided for @designForPersonalUseShareOnlyWhat.
  ///
  /// In en, this message translates to:
  /// **'For personal use: share only what is needed. You can hide your company and phone.'**
  String get designForPersonalUseShareOnlyWhat;

  /// No description provided for @designYourStyle.
  ///
  /// In en, this message translates to:
  /// **'01 / Your style'**
  String get designYourStyle;

  /// No description provided for @designWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get designWork;

  /// No description provided for @designSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get designSignature;

  /// No description provided for @designMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get designMinimal;

  /// No description provided for @designBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get designBold;

  /// No description provided for @designPhotograph.
  ///
  /// In en, this message translates to:
  /// **'02 / Photograph'**
  String get designPhotograph;

  /// No description provided for @designChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get designChoosePhoto;

  /// No description provided for @designRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get designRemovePhoto;

  /// No description provided for @designShowPortrait.
  ///
  /// In en, this message translates to:
  /// **'Show portrait'**
  String get designShowPortrait;

  /// No description provided for @designYourInformation.
  ///
  /// In en, this message translates to:
  /// **'03 / Your information'**
  String get designYourInformation;

  /// No description provided for @designUseTheEyeIconToChoose.
  ///
  /// In en, this message translates to:
  /// **'Use the eye icon to choose what appears. Hiding a field does not delete it.'**
  String get designUseTheEyeIconToChoose;

  /// No description provided for @designHideOnCard.
  ///
  /// In en, this message translates to:
  /// **'Hide on card'**
  String get designHideOnCard;

  /// No description provided for @designShowOnCard.
  ///
  /// In en, this message translates to:
  /// **'Show on card'**
  String get designShowOnCard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
