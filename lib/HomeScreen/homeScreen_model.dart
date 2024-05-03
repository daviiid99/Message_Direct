import 'package:flutter/material.dart';
import 'package:message_direct/Data/codesData.dart';
import 'package:stacked/stacked.dart';
import '../exports.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreenModel extends BaseViewModel implements Initialisable{

  List<CountryCodes> codes = [];
  List<NumberHistory> numbers  = [];
  bool isDialerSelected = true;
  bool isHistoryEdited =  false;
  bool isNumberHistoryEmpty = true;
  bool isWhatsAppUrl = true;
  bool isKeyboardEnabled = false;
  bool isFlagSelection = false;
  bool isMessageFieldActive = false;
  bool enabledEasterEgg = false;
  bool chooseDetailsScreen = false;
  bool isEditingMessage = false;
  bool isEditedCountryCode =  false;
  bool isSettingsScreen = false;
  TextEditingController numberField = TextEditingController(text: "");
  TextEditingController messageField = TextEditingController(text: "");
  int tempCountryCode = 0;
  int choosedCountryCode = 0;
  int choosedNumberHistory = 0;
  int exitCounter = 0;
  List<BasicConfig> config = [];

  @override
  void initialise(){
    getCountryCodes();
    getLatestCurrentCode();
    getNumbersHistory();
  }

  void getLatestCurrentCode() async {
    // A method that retrieves last user selected country code
    try {
      config =  await BasicConfig.retrieveRequestedFlag("countryCode");
      choosedCountryCode =  int.parse(config[0].flagValue);
      notifyListeners();
    } catch (e){
      BasicConfig.createBasicConfigTable();
    }
  }

   String getBannerAsset() {
    // A method that allow us to identify it
    if (enabledEasterEgg && !isSettingsScreen){
      return "assets/logo/logo_easter.png";
    } else if (isSettingsScreen && !enabledEasterEgg){
      return "assets/logo/logo_settings.png";
    } else if (isSettingsScreen && enabledEasterEgg) {
      return "assets/logo/logo_settings_easter.png";
    } else {
      return "assets/logo/logo.png";
    }
  }

  bool getEasterState() => enabledEasterEgg;

  void getCountryCodes() async {
    // A method that retrieves existing country codes
    // Inserts new ones if missing
    try {
      codes = await CountryCodes.retrieveCurrentCodes();
      notifyListeners();
    } catch (e){
      CodesData.insertCodesValues();
      codes = await CountryCodes.retrieveCurrentCodes();
      notifyListeners();
    }
  }

  double getKeyBoardTop(BuildContext context)  {
    if (isKeyboardEnabled){
      return getDeviceHeight(context) * 0.5;
    } else {
      return getDeviceHeight(context) * 0.72;
    }
  }


  double getKeyBoardBottom(BuildContext context) {
    if (isKeyboardEnabled){
      return getDeviceHeight(context) * 0.4;
    } else {
      return getDeviceHeight(context) * 0.1;
    }
  }

  void getNumbersHistory() async {
    // A method that gets the numbers history
    try {
      numbers = await NumberHistory.retrieveExistingNumbers();
      notifyListeners();
    } catch (e){
      NumberHistory.createNumberHistoryTable();
    }

    if (numbers.isNotEmpty){
      isNumberHistoryEmpty = false;
      numbers = numbers.reversed.toList();
      notifyListeners();
    }

  }

  getUriWhatsAppString(){
    if (isDialerSelected){
      return (Uri.parse('whatsapp://send?phone="${codes[choosedCountryCode].countryCode}${numberField.text}"&text=${messageField.text}'));
    } else if (isHistoryEdited){
      return (Uri.parse('whatsapp://send?phone="${isEditedCountryCode ? codes[tempCountryCode].countryCode : numbers[choosedNumberHistory].numberCountryCode}${numberField.text}"&text=${messageField.text}'));
    } else {
        return (Uri.parse('whatsapp://send?phone="${numbers[choosedNumberHistory].numberCountryCode}${numbers[choosedNumberHistory].numberText}"&text=${messageField.text}'));
      }
  }

  getUriTelegramString(){
    if (isDialerSelected){
      return (Uri.parse('https://t.me/${codes[choosedCountryCode].countryCode}${numberField.text.replaceAll(" ", "")}?chat_id=&text=${messageField.text}'));
    } else if (isHistoryEdited){
      return (Uri.parse('https://t.me/${isEditedCountryCode ? codes[tempCountryCode].countryCode : numbers[choosedNumberHistory].numberCountryCode}${numberField.text.replaceAll(" ", "")}?chat_id=&text=${messageField.text}'));
    } else{
      return (Uri.parse('https://t.me/${numbers[choosedNumberHistory].numberCountryCode}${numbers[choosedNumberHistory].numberText.replaceAll(" ", "")}?chat_id=&text=${messageField.text}'));
    }
  }

  Uri getWhatsAppUri() => getUriWhatsAppString();

  Uri getTelegramUri() => getUriTelegramString();

  void openNumberChat() async {
    // A method that opens a whatsapp requested number
    launchUrl(isWhatsAppUrl ? getWhatsAppUri() : getTelegramUri(), mode: LaunchMode.externalNonBrowserApplication);
  }

  String getNumberDateTime() => "${DateTime.now().year}/${DateTime.now().month < 10 ? "0${DateTime.now().month}" : DateTime.now().month}/${DateTime.now().day < 10 ? "0${DateTime.now().day}" : DateTime.now().day} - ${DateTime.now().hour < 10 ? "0${DateTime.now().hour}" : DateTime.now().hour}:${DateTime.now().minute < 10 ? "0${DateTime.now().minute}" : DateTime.now().minute}:${DateTime.now().second< 10 ? "0${DateTime.now().second}" : DateTime.now().second }";

  void addNumberToHistory() async {
    // A method that adds a number into the app history
      NumberHistory.insertNumberIntoTable(
        NumberHistory(
            numberText: numberField.text,
            numberCountryCode: isEditedCountryCode ? codes[tempCountryCode].countryCode : codes[choosedCountryCode].countryCode,
            numberCountryFlag: isEditedCountryCode ? codes[tempCountryCode].countryFlag : codes[choosedCountryCode].countryFlag,
            numberDate: getNumberDateTime(),
            numberMessage : messageField.text.isEmpty ? " " :  messageField.text
        ));

    // Clear App Attributes
    clearAppFields();

    // Reload History
    getNumbersHistory();

  }

  void modifyExistingNumber(int index) async {
    // A method that allow us to modify current number

    // Modify the number
    NumberHistory number = NumberHistory(
        numberText: numbers[choosedNumberHistory].numberText,
        numberCountryCode: codes[index].countryCode,
        numberCountryFlag: codes[index].countryFlag,
        numberDate: numbers[choosedNumberHistory].numberDate,
        numberMessage: messageField.text == numbers[choosedNumberHistory].numberText ? numbers[choosedNumberHistory].numberText : messageField.text );

    // Update the number
    NumberHistory.updateExistingNumber(number);

    // Refresh and call listeners
    getNumbersHistory();

    print("New Number Code : ${number.numberCountryCode}");
  }

  void clearAppFields() async {
    messageField.text = "";
    numberField.text = "";
    notifyListeners();
  }

  void saveCurrentCountryCode() async {
    // A method that saves latest selected country code with persistence

    if (config.isEmpty) {
      BasicConfig.insertConfigIntoTable(
          BasicConfig(
              flagName: "countryCode",
              flagValue: choosedCountryCode.toString()));
    } else {
      BasicConfig.updateExistingFlag(
          BasicConfig(
              flagName: "countryCode",
              flagValue: choosedCountryCode.toString()));
    }
  }

  void dropExistingHistory() async {
    // A method that erase all history
    for (NumberHistory number in numbers){
      NumberHistory.removeExistingHistory(number);
    }

    numbers.clear();
    notifyListeners();
  }

  void dropSingleNumber() async {
    // A method that removes an specified number
    NumberHistory.removeExistingHistory(numbers[choosedNumberHistory]);
    numbers.removeAt(choosedNumberHistory);
    notifyListeners();
  }

  void notifyUserRequiredValue(String message, BuildContext context){
    // This method allow us to notify user about an empty value
    SnackBar bar = SnackBar(content: Text(message, style: TextStyle(color: Colors.white, fontSize: getDeviceWidth(context) * 0.06, fontWeight: FontWeight.bold ), textAlign: TextAlign.center,), behavior: SnackBarBehavior.floating ,);
    ScaffoldMessenger.of(context).showSnackBar(bar);
  }

  void navigateToDesiredView(BuildContext context, String viewName) => Navigator.of(context).pushNamed(viewName);


  Color getAppColor() {
    if (isWhatsAppUrl){
      return whatsAppBackgroundColor;
    } else {
      return telegramBackgroundColor;
    }
  }
}