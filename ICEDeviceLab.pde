/*
 * <p>Ketai Sensor Library for Android: http://KetaiProject.org</p>
 *
 * <p>Ketai NFC Features:
 * <ul>
 * <li>handles incoming Near Field Communication Events</li>
 * </ul>
 * <p>Note:
 * Add the following within the sketch activity to the AndroidManifest.xml:
 * 
 * <uses-permission android:name="android.permission.NFC" /> 
 *
 * <intent-filter>
 *   <action android:name="android.nfc.action.TECH_DISCOVERED"/>
 * </intent-filter>
 *
 * <intent-filter>
 *  <action android:name="android.nfc.action.NDEF_DISCOVERED"/>
 * </intent-filter>
 *
 * <intent-filter>
 *  <action android:name="android.nfc.action.TAG_DISCOVERED"/>
 *  <category android:name="android.intent.category.DEFAULT"/>
 * </intent-filter>
 *
 * </p> 
 * <p>Updated: 2012-10-20 Daniel Sauter/j.duran</p>
 */

/*
 * NFC Inventory System
 * Written by: Andre Le
 * Date: 7-26-13
 *
 */


// Import Libraries
import android.content.Intent;
import android.os.Bundle;
import android.text.InputType;
import android.view.inputmethod.EditorInfo;

import ketai.data.*;
import ketai.net.nfc.*;
import ketai.ui.*;

import apwidgets.*;


// Initialize global variables
KetaiSQLite db;
KetaiNFC ketaiNFC;
KetaiVibrate vibe;
KetaiList userKList;
KetaiList eqKList;

ArrayList<String> usersList = new ArrayList<String>();
ArrayList<String> equipmentList = new ArrayList<String>();

// Setup Buttons and Text Fields
APWidgetContainer mainContainer, editUserContainer, editEquipmentContainer;
APWidgetContainer writeContainer;
APButton writeButton, readButton, userListButton, eqListButton;
APEditText nameField, emailField, phoneField;
APEditText eqNameField, eqDescriptionField;
APToggleButton eqBadgeButton, userBadgeButton;

public static final String CREATE_USERS_SQL = "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL, email TEXT NOT NULL, phone TEXT DEFAULT NULL,avatar_image TEXT DEFAULT NULL, UID TEXT UNIQUE);";
public static final String CREATE_EQUIPMENT_SQL = "CREATE TABLE equipment (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT DEFAULT NULL, description TEXT DEFAULT NULL, available INTEGER DEFAULT 1, UID TEXT UNIQUE, checkout INTEGER DEFAULT 1);";
public static final String CREATE_ACTIVITY_SQL = "CREATE TABLE activity (id INTEGER PRIMARY KEY AUTOINCREMENT,id_equipment INTEGER NOT NULL REFERENCES equipment (id),id_users INTEGER NOT NULL REFERENCES users (id), timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, checkout INTEGER DEFAULT 0);";

public static final int UNRECOGNIZED_TAG = 0;
public static final int USER_TAG = 1;
public static final int EQUIPMENT_TAG = 2;

public static final int CHECKED_IN = 0;
public static final int CHECKED_OUT = 1;


int lastTagID = 0;
int lastTagType = 0;
String lastTagUID = "";
String lastScan = "";
String newUID = "";
String[] tagWriteBuffer = {"", "", "", "", ""};

public static final int SCAN_MODE = 1;
public static final int CREATE_MODE = 2;
public static final int USER_PROFILE_MODE = 3;
public static final int EQUIPMENT_PROFILE_MODE = 4;
public static final int UNRECOGNIZED_MODE = 5;
public static final int CONFIRMATION_MODE = 6;
int currentScreen = 0;
User currentUser;
Equipment currentEquipment;
String scanText = "Scan NFC Tag";
String screenTitle = "";
String confirmationText = "";
float rotation = 0;
int fontSize = 48;
Boolean changesMade = false;

String nameText = "Test";
String descriptionText = "Description";
String emailText = "example@email.com";
String phoneText = "(123) 123-1234)";

int x_offset = 300;
int y_offset = 200;

PFont font;

void setup()
{
  // Database setup
  db = new KetaiSQLite(this);  // open database file

  if ( db.connect() )
  {
    println("Dropped users table: " + db.execute( "DROP TABLE users;" ));
    println("Dropped equipment table: " + db.execute( "DROP TABLE equipment;" ));
    println("Dropped activity table: " + db.execute( "DROP TABLE activity;" ));
    println("Dropped badges table: " + db.execute( "DROP TABLE badges;" ));
    // Delete all data (Uncomment for debugging only)
    println("Deleting ALL database data!");
    db.deleteAllData();
    
    // Creating tables if they don't exist
    if (!db.tableExists("users")) {
      db.execute(CREATE_USERS_SQL);
      println("Executing " + CREATE_USERS_SQL);
    }

    if (!db.tableExists("equipment")) {
      db.execute(CREATE_EQUIPMENT_SQL);
      println("Executing " + CREATE_EQUIPMENT_SQL);
    }

    if (!db.tableExists("activity")) {
      db.execute(CREATE_ACTIVITY_SQL);
      println("Executing " + CREATE_ACTIVITY_SQL);
    }
    
    // Create an entry for testing
    if (db.execute("INSERT INTO users ('name', 'email', 'phone', 'UID') VALUES ('Andre Le', 'andre.le@hp.com', '(619) 788-2610', 'pXqsnJE1Ja5Ysatm');"))
      println("Added Andre Le to users");
    if (db.execute("INSERT INTO equipment ('name', 'description', 'UID', 'checkout') VALUES ('Samsung S4', 'Best phone ever!', 'lGVQgmAsqOalY6bV', 1);"))
      println("Added Samsung S4 to equipment");
    if (db.execute("INSERT INTO activity ('id_equipment', 'id_users', 'checkout') VALUES (1, 1, 1);"))
      println("Added S4 checkout to Andre");

    // Print record counts
    println("data count for users table: "+db.getRecordCount("users"));
    println("data count for equipment table: "+db.getRecordCount("equipment"));
    println("data count for activity table: "+db.getRecordCount("activity"));
  }
  
  // Set font settings
  font = loadFont("HelveticaNeue-Light-48.vlw");
  textFont(font, 42);

  // Setup Draw settings
  orientation(PORTRAIT);
  textAlign(CENTER, CENTER);
  textSize(fontSize);
  ellipseMode(CENTER);
  noFill();
  stroke(255, 255, 255);
  strokeWeight(5);
  rectMode(CENTER);
  currentScreen = SCAN_MODE;
  
  // Main Android Widgets
  vibe = new KetaiVibrate(this);
  
  mainContainer = new APWidgetContainer(this); // create new main container
  writeButton = new APButton(width/3, height - fontSize*3, "Write NFC Tag");
  readButton = new APButton(width/3*2, height - fontSize*3, "Read NFC Tag");
  userListButton = new APButton(width*2/3 - 125, height - fontSize*3, 250, 100, "User List");
  eqListButton = new APButton(width*1/3 - 125, height - fontSize * 3, 250, 100, "Device List");
  //mainContainer.addWidget(writeButton);
  //mainContainer.addWidget(readButton);
  mainContainer.addWidget(userListButton);
  mainContainer.addWidget(eqListButton);


 // Setup Android Widgets


  newUID = generateUID();
  
  writeContainer = new APWidgetContainer(this); // Create container for write fields
  
  userBadgeButton = new APToggleButton(x_offset, fontSize, 200, 100, "User");
  eqBadgeButton = new APToggleButton(x_offset + 200, fontSize, 200, 100, "Device");
  writeContainer.addWidget(userBadgeButton);
  writeContainer.addWidget(eqBadgeButton); 
  
  if (currentUser != null) {
    nameText = currentUser.name;
    emailText = currentUser.email;
    phoneText = currentUser.phone;
  }
  
  nameField = new APEditText(x_offset, y_offset, width/2, 100);
  emailField = new APEditText(x_offset, int(fontSize * 2.5) + y_offset, width/2, 100);
  phoneField = new APEditText(x_offset, int(fontSize * 5) + y_offset, width/2, 100);
  eqNameField = new APEditText(x_offset, y_offset, width/2, 100);
  eqDescriptionField = new APEditText(x_offset, int(fontSize * 2.5) + y_offset, width/2, 100);
  
  
  editUserContainer = new APWidgetContainer(this);
  editEquipmentContainer = new APWidgetContainer(this);
  
    // Setup User Name Field
    editUserContainer.addWidget( nameField );
    nameField.setInputType(InputType.TYPE_CLASS_TEXT);
    nameField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    nameField.setText(nameText);
  
    // Setup User Email Field
    editUserContainer.addWidget( emailField );
    emailField.setInputType(InputType.TYPE_CLASS_TEXT);
    emailField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    emailField.setText(emailText);
  
    // Setup User Phone Field
    editUserContainer.addWidget( phoneField );
    phoneField.setInputType(InputType.TYPE_CLASS_PHONE);
    phoneField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    phoneField.setCloseImeOnDone(true);
    phoneField.setText(phoneText);
    
        // Setup Equipment Name Text Field
    editEquipmentContainer.addWidget( eqNameField );
    emailField.setInputType(InputType.TYPE_CLASS_TEXT);
    emailField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    emailField.setText(nameText);
  
    // Setup Equipment Description Field
    editEquipmentContainer.addWidget( eqDescriptionField );
    phoneField.setInputType(InputType.TYPE_CLASS_PHONE);
    phoneField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    phoneField.setCloseImeOnDone(true);
    phoneField.setText(descriptionText);
    
    writeContainer.hide(); // Hide the write container for now 
    editUserContainer.hide(); 
    editEquipmentContainer.hide();
}

void draw() {

  background(#6db7ff);
  switch(currentScreen) {
  case SCAN_MODE: 
    drawScanScreen(); 
    break;
  case CREATE_MODE:
    drawWriteScreen(lastTagType);
    break;
  case USER_PROFILE_MODE: 
    drawProfileScreen();
    break;
  case EQUIPMENT_PROFILE_MODE:
    drawEquipmentScreen();
    break;
  case CONFIRMATION_MODE:
    drawConfirmationScreen();
    break;
  case UNRECOGNIZED_MODE:
    drawUnrecognizedScreen();
    break;
  default: 
    drawScanScreen(); 
    break;
  }
  
  // Persistent UI
  
  if ( currentScreen != SCAN_MODE && currentScreen != CREATE_MODE) {
    pushStyle();
    textSize(46);
    text("Tap screen to reset", width/2, fontSize * 1.5);
    popStyle();
  }

}


/*
 * Event callbacks
 */
 
void onNFCEvent(String txt)
{
  boolean repeatScan = false;
  int badgeType = UNRECOGNIZED_TAG;
  
  // Provide haptic feedback
  vibe.vibrate(200);
  
  if ((txt != "" && txt.equals(lastScan)) || (txt == "" && lastScan.equals("empty"))) {
    println("Repeat scan detected.");
    repeatScan = true;
  }

  // Check to see if the format is compatible (i.e. if the : delimiter is in the right place)
  if (txt.indexOf(":") == 1) {
    
    String badgeContents = "";
    String[] badge = split(txt, ':');
    badgeType = int(badge[0]);
    badgeContents = badge[1];
    

    
    // Check to see if it's a recognized badge type
    if (badgeType == USER_TAG) {
      clearScreen();
      currentUser = findUser(badgeContents);
      
      if (lastTagType == EQUIPMENT_TAG && currentEquipment != null) {
        updateCheckout( currentUser, currentEquipment );
        return;
      }

    } else if (badgeType == EQUIPMENT_TAG) {
      clearScreen();
      currentEquipment = findEquipment(badgeContents);
      
      if (lastTagType == USER_TAG && currentUser != null) {
        updateCheckout( currentUser, currentEquipment );
        return;
      }

    }  else {
      //  Unrecognized badge type. Enter creation mode
      clearScreen();
      println("Not a recognized badge type. Reprogram?");
      currentScreen = UNRECOGNIZED_MODE;
      return;
    }
    
    lastScan = txt;
    println("Remembering last scan");
    lastTagType = badgeType;
    lastTagUID = badgeContents;
  } else {
    
      // Incompatible format
      currentScreen = UNRECOGNIZED_MODE;
      println("Unrecognized format. Reprogram?");
//      resetScanner();

      println("Remembering empty badge.");
      lastScan = "empty";
      lastTagType = 0;
      lastTagUID = "";
  }
  
    // If this is a valid badge and a repeat scan, take them to Edit Mode
    if (repeatScan) {
      if (badgeType == USER_TAG) {
        currentEquipment = null;
      } else if (badgeType == EQUIPMENT_TAG) {
        currentUser = null;
      }
      println("Entering edit mode");
      setupWriteScreen(badgeType);
      resetScanner();
      return;
    }

}

void onClickWidget(APWidget widget) {  
  if (widget == writeButton && currentScreen != CREATE_MODE) {
    setupWriteScreen( UNRECOGNIZED_TAG );
  } else if (widget == readButton && currentScreen != SCAN_MODE) {
    screenTitle = "Scanning Mode";
    currentScreen = SCAN_MODE;
    resetScanner();
    clearScreen();
  } else if (widget == userListButton) {
    updateUserList();
    userKList = new KetaiList(this, usersList);
  } else if (widget == eqListButton) {
    updateEqList();
    eqKList = new KetaiList(this, equipmentList);
  } else if (widget == nameField || widget == emailField || widget == phoneField) {
    // Update write buffer with changes made to text fields
    updateWriteBuffer();
  } else if (widget == eqBadgeButton) {  // Check for badge type toggling
    setupWriteScreen( EQUIPMENT_TAG );
  } else if (widget == userBadgeButton) {
    setupWriteScreen( USER_TAG );
  }
}

void onKetaiListSelection(KetaiList klist) {
  String selection = klist.getSelection();
  println( "Selected " + selection);
}

void onNFCWrite(boolean result, String message)
{
  if (result) {
    println("Success writing tag! Updating database...");
    updateRecord(tagWriteBuffer);
    changesMade = false;
  } else {
    println("Failed to write tag: " + message);
  }
}

void mousePressed() {
  
  if (currentScreen == EQUIPMENT_PROFILE_MODE || currentScreen == USER_PROFILE_MODE || currentScreen == UNRECOGNIZED_MODE) {
    screenTitle = "Scanning Mode";
    currentScreen = SCAN_MODE;
    resetScanner();
    clearScreen();
  }
  
  if (mouseY < height*2/3) {
    KetaiKeyboard.hide(this);
//    if (currentScreen == CREATE_MODE) {
//      updateWriteBuffer();
//    }
  }
}


