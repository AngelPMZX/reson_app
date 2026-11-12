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
  /// **'Use a hex color, for example #C8102E.'**
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
  /// **'ID card'**
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

  /// No description provided for @saveUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'We cannot confirm the save yet. You can keep editing or go back; another save will be available when this request finishes to avoid duplicates.'**
  String get saveUnconfirmed;

  /// No description provided for @saveTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection took too long. Your draft is still here; please try again.'**
  String get saveTimeout;

  /// No description provided for @savePermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to save this card. Check that your email is verified and contact support if it persists.'**
  String get savePermission;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get uploadingPhoto;

  /// No description provided for @confirmingSave.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation…'**
  String get confirmingSave;

  /// No description provided for @styleAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get styleAurora;

  /// No description provided for @styleExecutive.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get styleExecutive;

  /// No description provided for @styleEditorial.
  ///
  /// In en, this message translates to:
  /// **'Editorial'**
  String get styleEditorial;

  /// No description provided for @lateSaveConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your submitted version was saved. If you edited it afterwards, save those changes again.'**
  String get lateSaveConfirmed;

  /// No description provided for @professionalTitle.
  ///
  /// In en, this message translates to:
  /// **'04 / Your journey'**
  String get professionalTitle;

  /// No description provided for @professionalHint.
  ///
  /// In en, this message translates to:
  /// **'Choose what to show. Add up to 8 entries in total and 4 per section.'**
  String get professionalHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma-separated)'**
  String get skills;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Work experience'**
  String get experience;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @careerRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get careerRole;

  /// No description provided for @careerDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree or course'**
  String get careerDegree;

  /// No description provided for @careerSchool.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get careerSchool;

  /// No description provided for @careerPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period (e.g. 2022 – present)'**
  String get careerPeriod;

  /// No description provided for @careerDetails.
  ///
  /// In en, this message translates to:
  /// **'Achievements or description'**
  String get careerDetails;

  /// No description provided for @removeEntry.
  ///
  /// In en, this message translates to:
  /// **'Remove entry'**
  String get removeEntry;

  /// No description provided for @addExperience.
  ///
  /// In en, this message translates to:
  /// **'Add experience'**
  String get addExperience;

  /// No description provided for @addEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get addEducation;

  /// No description provided for @professionalProfile.
  ///
  /// In en, this message translates to:
  /// **'Professional profile'**
  String get professionalProfile;

  /// No description provided for @exploreProfile.
  ///
  /// In en, this message translates to:
  /// **'Explore my background'**
  String get exploreProfile;

  /// No description provided for @openLinkedin.
  ///
  /// In en, this message translates to:
  /// **'Open LinkedIn'**
  String get openLinkedin;

  /// No description provided for @invalidLinkedin.
  ///
  /// In en, this message translates to:
  /// **'Use an https://www.linkedin.com/... link'**
  String get invalidLinkedin;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @orEmail.
  ///
  /// In en, this message translates to:
  /// **'or with your email'**
  String get orEmail;

  /// No description provided for @googlePopup.
  ///
  /// In en, this message translates to:
  /// **'Allow pop-ups to sign in with Google.'**
  String get googlePopup;

  /// No description provided for @googleSetup.
  ///
  /// In en, this message translates to:
  /// **'Google is not configured for this device yet.'**
  String get googleSetup;

  /// No description provided for @googleConflict.
  ///
  /// In en, this message translates to:
  /// **'Use your existing sign-in method to keep access to your account.'**
  String get googleConflict;

  /// No description provided for @authEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MEANINGFUL CONNECTIONS'**
  String get authEyebrow;

  /// No description provided for @authPromise.
  ///
  /// In en, this message translates to:
  /// **'Your next opportunity starts with you.'**
  String get authPromise;

  /// No description provided for @authPromiseBody.
  ///
  /// In en, this message translates to:
  /// **'An identity that tells your story. Share what you do, what you know and where you are going.'**
  String get authPromiseBody;

  /// No description provided for @authBenefit1.
  ///
  /// In en, this message translates to:
  /// **'Designed for your brand'**
  String get authBenefit1;

  /// No description provided for @authBenefit2.
  ///
  /// In en, this message translates to:
  /// **'Your story, your way'**
  String get authBenefit2;

  /// No description provided for @authBenefit3.
  ///
  /// In en, this message translates to:
  /// **'You choose what to share'**
  String get authBenefit3;

  /// No description provided for @styleNoir.
  ///
  /// In en, this message translates to:
  /// **'Noir'**
  String get styleNoir;

  /// No description provided for @styleStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get styleStudio;

  /// No description provided for @replayAnimation.
  ///
  /// In en, this message translates to:
  /// **'Replay animation'**
  String get replayAnimation;

  /// No description provided for @authVisualTitle.
  ///
  /// In en, this message translates to:
  /// **'Less noise.\nMore identity.'**
  String get authVisualTitle;

  /// No description provided for @photoUploadsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo uploads are not available yet. You can save your card and add a photo later.'**
  String get photoUploadsUnavailable;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not upload the photo. Your card has not been saved yet. Retry or save without the new photo.'**
  String get photoUploadFailed;

  /// No description provided for @saveWithoutNewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Save without the new photo'**
  String get saveWithoutNewPhoto;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeWelcome;

  /// No description provided for @homeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Your identity workspace'**
  String get homeWorkspace;

  /// No description provided for @homeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MADE FOR CONNECTION'**
  String get homeEyebrow;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your identity.\nA lasting impression.'**
  String get homeHeadline;

  /// No description provided for @homeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAll;

  /// No description provided for @homeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get homeWork;

  /// No description provided for @homeFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get homeFreelance;

  /// No description provided for @homePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get homePersonal;

  /// No description provided for @homeFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'A new side of you to discover'**
  String get homeFilterEmpty;

  /// No description provided for @homeFilterHint.
  ///
  /// In en, this message translates to:
  /// **'No cards of this type yet. Explore your collection or create a new one.'**
  String get homeFilterHint;

  /// No description provided for @homeProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Completed professional details'**
  String get homeProfileDetails;

  /// No description provided for @homeReady.
  ///
  /// In en, this message translates to:
  /// **'An identity with more context'**
  String get homeReady;

  /// No description provided for @homeImprove.
  ///
  /// In en, this message translates to:
  /// **'Make your introduction count'**
  String get homeImprove;

  /// No description provided for @homeNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Role, bio, skills and LinkedIn: you choose what to share.'**
  String get homeNudgeBody;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @profileIntro.
  ///
  /// In en, this message translates to:
  /// **'Your information, in one place. Use it as a starting point for your cards. Every field in this profile is optional.'**
  String get profileIntro;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved. New cards will use these details.'**
  String get profileSaved;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Sign-in email verified'**
  String get profileVerified;

  /// No description provided for @profileEmailNote.
  ///
  /// In en, this message translates to:
  /// **'Your card contact email can be different. Changing it here does not change your sign-in account.'**
  String get profileEmailNote;

  /// No description provided for @profileUrlError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http:// or https:// address.'**
  String get profileUrlError;

  /// No description provided for @profileEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get profileEmailError;

  /// No description provided for @profileDiscard.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving changes?'**
  String get profileDiscard;

  /// No description provided for @profileStay.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get profileStay;

  /// No description provided for @profileLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get profileLeave;

  /// No description provided for @walletPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous card'**
  String get walletPrevious;

  /// No description provided for @walletNext.
  ///
  /// In en, this message translates to:
  /// **'Next card'**
  String get walletNext;

  /// No description provided for @profileCareerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your background'**
  String get profileCareerTitle;

  /// No description provided for @profileCareerHint.
  ///
  /// In en, this message translates to:
  /// **'Choose what to show. Add up to 8 entries in total and 4 per section.'**
  String get profileCareerHint;

  /// No description provided for @profileStudio.
  ///
  /// In en, this message translates to:
  /// **'YOUR PERSONAL IDENTITY'**
  String get profileStudio;

  /// No description provided for @profileTagline.
  ///
  /// In en, this message translates to:
  /// **'An introduction that feels like you'**
  String get profileTagline;

  /// No description provided for @profileUseGoogle.
  ///
  /// In en, this message translates to:
  /// **'Use Google photo'**
  String get profileUseGoogle;

  /// No description provided for @profilePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Private profile photo. Change or remove it whenever you want. Save your profile to apply changes.'**
  String get profilePhotoHint;

  /// No description provided for @profileAvailability.
  ///
  /// In en, this message translates to:
  /// **'Your availability'**
  String get profileAvailability;

  /// No description provided for @profileStatusPrivate.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get profileStatusPrivate;

  /// No description provided for @profileStatusProjects.
  ///
  /// In en, this message translates to:
  /// **'Open to projects'**
  String get profileStatusProjects;

  /// No description provided for @profileStatusEmployment.
  ///
  /// In en, this message translates to:
  /// **'Open to opportunities'**
  String get profileStatusEmployment;

  /// No description provided for @profileStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get profileStatusUnavailable;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profileDetails;

  /// No description provided for @profileLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileLanguages;

  /// No description provided for @profileServices.
  ///
  /// In en, this message translates to:
  /// **'Services or specialties'**
  String get profileServices;

  /// No description provided for @careerSector.
  ///
  /// In en, this message translates to:
  /// **'Industry or field'**
  String get careerSector;

  /// No description provided for @careerSectorHint.
  ///
  /// In en, this message translates to:
  /// **'Technology, healthcare, education, construction, hospitality, arts, trades… Enter your field.'**
  String get careerSectorHint;

  /// No description provided for @careerSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialties and services'**
  String get careerSpecialty;

  /// No description provided for @careerWorkMode.
  ///
  /// In en, this message translates to:
  /// **'Work mode · on-site, hybrid or remote'**
  String get careerWorkMode;

  /// No description provided for @careerProjects.
  ///
  /// In en, this message translates to:
  /// **'Featured projects'**
  String get careerProjects;

  /// No description provided for @careerCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications and licenses'**
  String get careerCertifications;

  /// No description provided for @careerItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Project or certification name'**
  String get careerItemTitle;

  /// No description provided for @careerOrganization.
  ///
  /// In en, this message translates to:
  /// **'Company, client or issuer'**
  String get careerOrganization;

  /// No description provided for @addCareerItem.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addCareerItem;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How Reson looks and sounds on this device.'**
  String get settingsSubtitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceNote.
  ///
  /// In en, this message translates to:
  /// **'Pick a side, or let Reson follow your device.'**
  String get settingsAppearanceNote;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Your public card shows in the language of whoever opens it.'**
  String get settingsLanguageNote;

  /// No description provided for @settingsFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsFollowSystem;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @networkRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get networkRequests;

  /// No description provided for @networkConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get networkConversations;

  /// No description provided for @networkPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get networkPaused;

  /// No description provided for @networkWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a reply'**
  String get networkWaiting;

  /// No description provided for @networkNoConversations.
  ///
  /// In en, this message translates to:
  /// **'When you accept a connection, the conversation shows up here.'**
  String get networkNoConversations;

  /// No description provided for @networkNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get networkNoMessages;

  /// No description provided for @networkYouPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: '**
  String get networkYouPrefix;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @connectionSound.
  ///
  /// In en, this message translates to:
  /// **'Sound when accepting a connection'**
  String get connectionSound;

  /// No description provided for @connectionSoundNote.
  ///
  /// In en, this message translates to:
  /// **'A soft Reson chime. You can turn it off at any time.'**
  String get connectionSoundNote;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get navNetwork;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @messagesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search a conversation'**
  String get messagesSearch;

  /// No description provided for @messagesClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get messagesClearSearch;

  /// No description provided for @messagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get messagesEmptyTitle;

  /// No description provided for @messagesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once you accept a connection you can write here.'**
  String get messagesEmptyBody;

  /// No description provided for @messagesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No conversation matches that search.'**
  String get messagesNoMatch;

  /// No description provided for @networkConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get networkConnections;

  /// No description provided for @networkSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get networkSaved;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get profileSkills;

  /// No description provided for @profileEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is empty'**
  String get profileEmptyTitle;

  /// No description provided for @profileEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tell people what you do. Whatever you write here becomes the starting point for every card you create.'**
  String get profileEmptyBody;

  /// No description provided for @walletSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name, company or place'**
  String get walletSearch;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is empty'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When somebody hands you their card and you keep it, you will find it here whenever you need it.'**
  String get walletEmptyBody;

  /// No description provided for @walletNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No card matches that filter.'**
  String get walletNoMatch;

  /// No description provided for @walletUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Its owner took this card down'**
  String get walletUnavailable;

  /// No description provided for @walletRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from my wallet'**
  String get walletRemove;

  /// No description provided for @messagesAndNewRequestsBetween.
  ///
  /// In en, this message translates to:
  /// **'Messages and new requests between these accounts will be stopped.'**
  String get messagesAndNewRequestsBetween;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reportRecorded.
  ///
  /// In en, this message translates to:
  /// **'Report recorded.'**
  String get reportRecorded;

  /// No description provided for @thisConversationIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This conversation is unavailable.'**
  String get thisConversationIsUnavailable;

  /// No description provided for @viewCard.
  ///
  /// In en, this message translates to:
  /// **'View card'**
  String get viewCard;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @aGoodConversationStartsWith.
  ///
  /// In en, this message translates to:
  /// **'A good conversation starts with hello.'**
  String get aGoodConversationStartsWith;

  /// No description provided for @writeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get writeAMessage;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @aMeaningfulConnection.
  ///
  /// In en, this message translates to:
  /// **'A meaningful connection'**
  String get aMeaningfulConnection;

  /// No description provided for @youCanNowChatAnd.
  ///
  /// In en, this message translates to:
  /// **'You can now chat and explore each other’s cards.'**
  String get youCanNowChatAnd;

  /// No description provided for @openConversation.
  ///
  /// In en, this message translates to:
  /// **'Open conversation'**
  String get openConversation;

  /// No description provided for @peopleYouKnowCardsYou.
  ///
  /// In en, this message translates to:
  /// **'People you know. Cards you kept.'**
  String get peopleYouKnowCardsYou;

  /// No description provided for @noConnectionsYetShareYour.
  ///
  /// In en, this message translates to:
  /// **'No connections yet. Share your QR to get started.'**
  String get noConnectionsYetShareYour;

  /// No description provided for @wantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect'**
  String get wantsToConnect;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @youBlockedThisPerson.
  ///
  /// In en, this message translates to:
  /// **'You blocked this person'**
  String get youBlockedThisPerson;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @acceptAfterAll.
  ///
  /// In en, this message translates to:
  /// **'Accept after all'**
  String get acceptAfterAll;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @aNewConnection.
  ///
  /// In en, this message translates to:
  /// **'A new connection'**
  String get aNewConnection;

  /// No description provided for @saveThisCardOrIntroduce.
  ///
  /// In en, this message translates to:
  /// **'Save this card or introduce yourself with one of yours.'**
  String get saveThisCardOrIntroduce;

  /// No description provided for @retry2.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry2;

  /// No description provided for @saveToMyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Save to my network'**
  String get saveToMyNetwork;

  /// No description provided for @viewContactOptions.
  ///
  /// In en, this message translates to:
  /// **'View contact options'**
  String get viewContactOptions;

  /// No description provided for @exchangeCards.
  ///
  /// In en, this message translates to:
  /// **'Exchange cards'**
  String get exchangeCards;

  /// No description provided for @chooseWhichPublishedCardTo.
  ///
  /// In en, this message translates to:
  /// **'Choose which published card to send. Your private profile is not shared.'**
  String get chooseWhichPublishedCardTo;

  /// No description provided for @publishACardFromMy.
  ///
  /// In en, this message translates to:
  /// **'Publish a card from My cards to request connections.'**
  String get publishACardFromMy;

  /// No description provided for @yourCard.
  ///
  /// In en, this message translates to:
  /// **'Your card'**
  String get yourCard;

  /// No description provided for @requestConnection.
  ///
  /// In en, this message translates to:
  /// **'Request connection'**
  String get requestConnection;

  /// No description provided for @shareYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Share your identity'**
  String get shareYourIdentity;

  /// No description provided for @publishOnlyWhatYouWant.
  ///
  /// In en, this message translates to:
  /// **'Publish only what you want to share. Anyone with the link can view and forward it.'**
  String get publishOnlyWhatYouWant;

  /// No description provided for @cardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Card unavailable'**
  String get cardUnavailable;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get contactEmail;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @experience2.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience2;

  /// No description provided for @industry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industry;

  /// No description provided for @specialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get specialties;

  /// No description provided for @workMode.
  ///
  /// In en, this message translates to:
  /// **'Work mode'**
  String get workMode;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @net1ChoosePublicFields.
  ///
  /// In en, this message translates to:
  /// **'1 · Choose public fields'**
  String get net1ChoosePublicFields;

  /// No description provided for @nameAndLabelAlwaysAppear.
  ///
  /// In en, this message translates to:
  /// **'Name and label always appear. Fields hidden on your card are not published.'**
  String get nameAndLabelAlwaysAppear;

  /// No description provided for @allowWhatsappContact.
  ///
  /// In en, this message translates to:
  /// **'Allow WhatsApp contact'**
  String get allowWhatsappContact;

  /// No description provided for @usesThePublishedNumberIncluding.
  ///
  /// In en, this message translates to:
  /// **'Uses the published number including country code.'**
  String get usesThePublishedNumberIncluding;

  /// No description provided for @net2DataPreview.
  ///
  /// In en, this message translates to:
  /// **'2 · Data preview'**
  String get net2DataPreview;

  /// No description provided for @thePublicPageAdaptsThese.
  ///
  /// In en, this message translates to:
  /// **'The public page adapts these details to the browser. Changes only reach your link when you publish again.'**
  String get thePublicPageAdaptsThese;

  /// No description provided for @yourLinkIsLive.
  ///
  /// In en, this message translates to:
  /// **'Your link is live'**
  String get yourLinkIsLive;

  /// No description provided for @publicCardQr.
  ///
  /// In en, this message translates to:
  /// **'Public card QR'**
  String get publicCardQr;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @unpublishCard.
  ///
  /// In en, this message translates to:
  /// **'Unpublish card'**
  String get unpublishCard;

  /// No description provided for @unpublishingDisablesTheLinkAnd.
  ///
  /// In en, this message translates to:
  /// **'Unpublishing disables the link and QR. Previously downloaded contacts cannot be revoked.'**
  String get unpublishingDisablesTheLinkAnd;

  /// No description provided for @blockConnection.
  ///
  /// In en, this message translates to:
  /// **'Block connection'**
  String get blockConnection;

  /// No description provided for @reportConnection.
  ///
  /// In en, this message translates to:
  /// **'Report connection'**
  String get reportConnection;

  /// No description provided for @cardSavedInNetwork.
  ///
  /// In en, this message translates to:
  /// **'Card saved in your network.'**
  String get cardSavedInNetwork;

  /// No description provided for @requestSentChatLater.
  ///
  /// In en, this message translates to:
  /// **'Request sent. Chat becomes available after acceptance.'**
  String get requestSentChatLater;

  /// No description provided for @publishAndCreateQr.
  ///
  /// In en, this message translates to:
  /// **'Publish and create QR'**
  String get publishAndCreateQr;

  /// No description provided for @updatePublication.
  ///
  /// In en, this message translates to:
  /// **'Update publication'**
  String get updatePublication;

  /// No description provided for @netErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This card is no longer available.'**
  String get netErrorNotFound;

  /// No description provided for @netErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Please wait before trying again.'**
  String get netErrorRateLimited;

  /// No description provided for @netErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'This action is unavailable for this connection.'**
  String get netErrorPermission;

  /// No description provided for @netErrorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Sign in and verify your email.'**
  String get netErrorUnauthenticated;

  /// No description provided for @netErrorPrecondition.
  ///
  /// In en, this message translates to:
  /// **'Publish your card first. This connection may also have been closed.'**
  String get netErrorPrecondition;

  /// No description provided for @netErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm the action. Check your connection and retry.'**
  String get netErrorGeneric;

  /// No description provided for @cardYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get cardYourName;

  /// No description provided for @cardKindProfessional.
  ///
  /// In en, this message translates to:
  /// **'PROFESSIONAL'**
  String get cardKindProfessional;

  /// No description provided for @credentialProfessionalIdentity.
  ///
  /// In en, this message translates to:
  /// **'PROFESSIONAL IDENTITY'**
  String get credentialProfessionalIdentity;

  /// No description provided for @credentialIndependentTalent.
  ///
  /// In en, this message translates to:
  /// **'INDEPENDENT TALENT'**
  String get credentialIndependentTalent;

  /// No description provided for @credentialPersonalConnections.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL CONNECTIONS'**
  String get credentialPersonalConnections;

  /// No description provided for @shareOrQr.
  ///
  /// In en, this message translates to:
  /// **'Share / QR'**
  String get shareOrQr;

  /// No description provided for @switchTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch theme'**
  String get switchTheme;

  /// No description provided for @credentialTagline.
  ///
  /// In en, this message translates to:
  /// **'Your identity. Your essence.'**
  String get credentialTagline;

  /// No description provided for @cardYourNewIdentity.
  ///
  /// In en, this message translates to:
  /// **'Your new identity'**
  String get cardYourNewIdentity;

  /// No description provided for @theirCard.
  ///
  /// In en, this message translates to:
  /// **'Their card'**
  String get theirCard;
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
