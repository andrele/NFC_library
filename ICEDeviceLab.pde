/**
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
APWidgetContainer mainContainer;
APWidgetContainer writeContainer;
APButton writeButton, readButton, userListButton, eqListButton;
APEditText nameField, emailField, phoneField;

public static final String CREATE_USERS_SQL = "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL, email TEXT NOT NULL, phone TEXT DEFAULT NULL,avatar_image TEXT DEFAULT NULL, UID TEXT UNIQUE);";
public static final String CREATE_EQUIPMENT_SQL = "CREATE TABLE equipment (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT DEFAULT NULL, description TEXT DEFAULT NULL, available INTEGER DEFAULT 1, UID TEXT UNIQUE, checkout INTEGER DEFAULT 1);";
public static final String CREATE_ACTIVITY_SQL = "CREATE TABLE activity (id INTEGER PRIMARY KEY AUTOINCREMENT,id_equipment INTEGER NOT NULL REFERENCES equipment (id),id_users INTEGER NOT NULL REFERENCES users (id), timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, checkout INTEGER DEFAULT 0);";

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
String emailText = "example@email.com";
String phoneText = "(123) 123-1234)";

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
  currentScreen = SCAN_MODE;
  
  // Main Android Widgets
  vibe = new KetaiVibrate(this);
  
  mainContainer = new APWidgetContainer(this); // create new main container
  writeButton = new APButton(width/3, height - fontSize*3, "Write NFC Tag");
  readButton = new APButton(width/3*2, height - fontSize*3, "Read NFC Tag");
  userListButton = new APButton(0, height - fontSize*3, "User List");
  eqListButton = new APButton(0, int(height - fontSize * 4.5), "Device List");
  mainContainer.addWidget(writeButton);
  mainContainer.addWidget(readButton);
  mainContainer.addWidget(userListButton);
  mainContainer.addWidget(eqListButton);


 // Write Android Widgets

  int x_offset = 300;
  int y_offset = 100;
  newUID = generateUID();
  
  writeContainer = new APWidgetContainer(this); // Create container for write fields
  
  if (currentUser != null) {
    nameText = currentUser.name;
    emailText = currentUser.email;
    phoneText = currentUser.phone;
  }
  
  nameField = new APEditText(x_offset, y_offset, width/2, 100);
  emailField = new APEditText(x_offset, int(fontSize * 2.5) + y_offset, width/2, 100);
  phoneField = new APEditText(x_offset, int(fontSize * 5) + y_offset, width/2, 100);
  
    writeContainer.addWidget( nameField );
    nameField.setInputType(InputType.TYPE_CLASS_TEXT);
    nameField.setImeOptions(EditorInfo.IME_ACTION_NEXT);
    nameField.setText(nameText);
  
    writeContainer.addWidget( emailField );
    emailField.setNextEditText( emailField );
    emailField.setInputType(InputType.TYPE_CLASS_TEXT);
    emailField.setImeOptions(EditorInfo.IME_ACTION_NEXT);
    emailField.setText(emailText);
  
    writeContainer.addWidget( phoneField );
    phoneField.setNextEditText( phoneField );
    phoneField.setInputType(InputType.TYPE_CLASS_PHONE);
    phoneField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    phoneField.setCloseImeOnDone(true);
    phoneField.setText(phoneText);
    
    writeContainer.hide(); // Hide the write container for now 
}

void draw() {

  background(#6db7ff);
  switch(currentScreen) {
  case SCAN_MODE: 
    drawScanScreen(); 
    break;
  case CREATE_MODE:
    drawWriteScreen();
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
  //text(screenTitle, width/2, fontSize * 1.5);
  

}

/*
 * Drawing subroutines
 */
 
void drawConfirmationScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  text(confirmationText, width/2, height/2);
  popStyle();
}

void drawUnrecognizedScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  text("Sorry! Your badge is unrecognized.\nWould you like to rewrite it?\nScan the tag again to enter edit mode.", width/2, height/2);
  popStyle();
}

void drawScanScreen() {
  // Set title of screen
  screenTitle = "Scanning Mode";
  // Rotating Circle
  rotation += 1;
  if (rotation > 360) {
    rotation = 0;
  }
  pushMatrix();
  translate(width/2, height/2);
  pushStyle();
  textSize(fontSize);
  popStyle();
  text(scanText, 0, 0);
//  rotate(radians(rotation));
//  arc(0, 0, width/2, width/2, PI, PI*2);
  popMatrix();
}

void drawProfileScreen() {
  screenTitle = "User Profile";
  pushStyle();
  int x_offset = width/3;
  int y_offset = 150;
  textAlign(LEFT, CENTER);
  text(currentUser.name, x_offset, y_offset);
  text(currentUser.email, x_offset, y_offset + (fontSize * 2.5));
  text(currentUser.phone, x_offset, y_offset + (fontSize * 5));

  popStyle();
}



void drawEquipmentScreen() {
  int x_offset = width/3;
  int y_offset = 150;
  screenTitle = "Equipment Profile";
  
  pushStyle();
  
  textAlign(LEFT, CENTER);
  text(currentEquipment.name, x_offset, y_offset);
  text(currentEquipment.description, x_offset, y_offset + (fontSize * 2.5));
  text(equipmentStatus( currentEquipment), x_offset, y_offset + (fontSize * 5));
  popStyle();
}

void drawWriteScreen() {
  int x_offset = width/3;
  int y_offset = 150;
  screenTitle = "Edit mode";
  
  pushStyle();
  textAlign(RIGHT, CENTER);
  text("Name", x_offset, y_offset);
  text("Email", x_offset, y_offset + (fontSize * 2.5));
  text("Phone", x_offset, y_offset + (fontSize * 5));
  textAlign(CENTER, CENTER);
  
  if (currentUser == null || currentUser.UID.equals("")) {
    text("New generated UID", width/2, y_offset + (fontSize * 7.5));
    text( newUID, width/2, y_offset + (fontSize * 9));
  } else {
    text("Existing UID", width/2, y_offset + (fontSize * 7.5));
    text( currentUser.UID, width/2, y_offset + (fontSize * 9));
  }
  
  if (changesMade) {
    text("Changes detected. Tap tag to rewrite", width/2, y_offset + (fontSize * 10.5));
  }
  
  popStyle();
}

void drawActivityScreen() {
  
}

void clearScreen() {
  writeContainer.hide();
  changesMade = false;
  ketaiNFC.cancelWrite();
}

void setupWriteScreen(int x, int y) {
  currentScreen = CREATE_MODE;
  newUID = generateUID();
  if (currentUser != null) {
    nameField.setText( currentUser.name );
    emailField.setText( currentUser.email );
    phoneField.setText( currentUser.phone );
  }
  
  writeContainer.show();
  
}

void setupConfirmationScreen() {
  resetScanner();
  clearScreen();
}


/*
 * Interactions
 */
 
void onNFCEvent(String txt)
{
  boolean repeatScan = false;
  
  // Provide haptic feedback
  vibe.vibrate(200);

  // Check to see if the format is compatible (i.e. if the : delimiter is in the right place)
  if (txt.indexOf(":") == 1) {
    int badgeType = 0;
    String badgeContents = "";
    String[] badge = split(txt, ':');
    badgeType = int(badge[0]);
    badgeContents = badge[1];
    
    if (txt.equals(lastScan)) {
      println("Repeat scan detected.");
      repeatScan = true;
    }
    
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
    
    // If this is a valid badge and a repeat scan, take them to Edit Mode
    if (repeatScan) {
      println("Entering edit mode");
      setupWriteScreen(100, 150);
      resetScanner();
      return;
    }
    
    // Remember the last valid badge scan for repeat actions
    lastTagType = badgeType;
    lastTagUID = badgeContents;
    lastScan = txt;
    println("Remembering last scan");
  } else {
    
      // Incompatible format
      currentScreen = UNRECOGNIZED_MODE;
      println("Unrecognized format. Reprogram?");
      resetScanner();
  }
  

}

void onClickWidget(APWidget widget) {  
  if (widget == writeButton && currentScreen != CREATE_MODE) {
    setupWriteScreen( 100, 150 );
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
  
  if (currentScreen == UNRECOGNIZED_MODE) {
    setupWriteScreen( 100, 150);
    return;
  }
  
  if (mouseY < height*2/3) {
    KetaiKeyboard.hide(this);
    if (currentScreen == CREATE_MODE) {
      updateWriteBuffer();
    }
  }
}

/* 
 * Utility Functions
 */
 
boolean updateRecord(String[] buffer) {
  // Determine which table to update
  if (buffer[4].equals("USER_TAG")) {
    if (db.execute("INSERT INTO users ('name', 'email', 'phone', 'UID') VALUES ('" + buffer[0] +"', '" + buffer[1] +"', '" + buffer[2] +"', '" + buffer[3] +"');")) {
      println("Added " + buffer[0] + " to users");
      return true;
    } else if (db.execute("UPDATE users SET name='" + buffer[0] + "',email='"+ buffer[1] + "',phone='" + buffer[2] + "' WHERE uid='" +buffer[3]+"';")) {
      println("Updated " + buffer[0] + ".");
      return true;
    }
  } else {
  }
  return false;
}
 
// Look up badge ID and associated equipment/user
User findUser(String txt) {
  User foundUser = new User();
  println("Finding user with badge " + txt);
  db.query("SELECT * FROM users WHERE UID LIKE'"+ txt + "';");
  while (db.next ())
  {
    currentScreen = USER_PROFILE_MODE;
    foundUser.name = db.getString("name");
    foundUser.email = db.getString("email");
    foundUser.phone = db.getString("phone");
    foundUser.id = db.getInt("id");
    foundUser.UID = db.getString("UID");
    println("User found:");
    println(foundUser.name + "\t" + foundUser.email + "\t" + foundUser.phone + "\tID Badge: " + foundUser.id);
    
    return foundUser;
  }
  
  scanText = "User not found.";
  println(scanText);
  return null;
}

Equipment findEquipment(String txt) {
  Equipment foundEquipment = new Equipment();
  println("Finding equipment with badge " + txt);
  db.query("SELECT * FROM equipment WHERE UID LIKE '"+ txt + "';");
  while (db.next ())
  {
    currentScreen = EQUIPMENT_PROFILE_MODE;
    foundEquipment.id = db.getInt("id");
    foundEquipment.name = db.getString("name");
    foundEquipment.description = db.getString("description");
    foundEquipment.UID = db.getString("UID");
    foundEquipment.status = getEquipmentCheckoutStatus( foundEquipment );
    
    println("Equipment found:");
    println(foundEquipment.name + "\t" + foundEquipment.description + "\tID Badge: " + foundEquipment.UID + "\tStatus: " + equipmentStatus( foundEquipment ) );
    
    return foundEquipment;
  }
  
  scanText = "Equipment not found.";
  println(scanText);
  return null;
}

// Function to generate a random 32 character alphanumeric string
String generateUID() {
  String UID = "";
  
  for (int i = 0; i < 16; i++) {
    int randomChar = 0;
    Boolean validChar = false;
    while (validChar == false) {
      randomChar = int(random(48, 127));
      // If character is a number, use it
      if (randomChar >= 48 && randomChar <= 57)
        break;
      // If character is a capitalized letter, use it
      if (randomChar >= 65 && randomChar <= 90)
        break;
      // If character is a lowercase letter, use it
      if (randomChar >= 97 && randomChar <= 122)
        break;
    }
    
    // Add the random character to the string
    UID = UID + str((char)randomChar);
  }
  
  return UID;
}

int getEquipmentCheckoutStatus( Equipment equipment ) {  
  int status = -1;
  // Check to see if equipment is already checked out
  db.query("SELECT * FROM activity WHERE id_equipment="+ equipment.id +" ORDER BY id DESC LIMIT 1;");
  while (db.next ())
  {
      status = db.getInt("checkout");
      if (status == CHECKED_OUT)
        println("Currently checked OUT.");
      else
        println("Currently checked IN.");
      return status;
  }
  
  println("No previous activity found.");
  return status;
}

// Resets the scanner by clearing the last scanned data.
void resetScanner() {
  println("Clearing scanner cache");
  lastTagID = 0;
  lastTagType = 0;
  lastTagUID = "";
  lastScan = "";
}

// Checks the device in/out
void updateCheckout(User user, Equipment equipment) {
  int checkoutStatus = equipment.status;
  
  // If no previous activity, or currently CHECKED_IN, then checkout
  if ( checkoutStatus == -1 || checkoutStatus == CHECKED_IN ) {
    // Add record linking this equipment and user
    if (db.execute("INSERT INTO activity ('id_users', 'id_equipment', 'checkout') VALUES ("+ user.id +", "+ equipment.id +", "+ CHECKED_OUT +");") == true) {
      confirmationText = "Successfully checked the " + equipment.name + " out to " + user.name + "!";
      println(confirmationText);
      setupConfirmationScreen();
    } else {
      println("Checkout failed. :(");
    }
  } else { // Looks like device was previously checked out. Check that baby in!
    if (db.execute("INSERT INTO activity ('id_users', 'id_equipment', 'checkout') VALUES ("+ user.id +", "+ equipment.id +", "+ CHECKED_IN +");") == true) {
      confirmationText = user.name + " successfully checked the " + equipment.name + " in!";
      println(confirmationText);
      setupConfirmationScreen();
      
    } else {
      println("Checkin failed :(");
    }
  }
  // Clear any previous scans before moving on. Prevents accidental checkouts.
  resetScanner();
}

// Update the write buffer and prepare for writing
void updateWriteBuffer() {
    tagWriteBuffer[0] = nameField.getText();
    tagWriteBuffer[1] = emailField.getText();
    tagWriteBuffer[2] = phoneField.getText();
    if (currentUser.UID.equals(""))
      tagWriteBuffer[3] = newUID;
    else
      tagWriteBuffer[3] = currentUser.UID;
    tagWriteBuffer[4] = "USER_TAG";
    println("Write buffer updated with: " + tagWriteBuffer[0] + " " + tagWriteBuffer[1] + " " + tagWriteBuffer[2] + " " + tagWriteBuffer[3] + " " + tagWriteBuffer[4]);
    changesMade = true;
    writeTag(tagWriteBuffer);
}

void updateUserList() {
    db.query("SELECT * FROM users");
    println("User records:");
    usersList.clear();
    while (db.next()) {
      usersList.add(db.getString("name"));
      println(db.getString("name") + "\t" + db.getString("email") + "\t" + db.getString("phone") + "\t" + db.getString("UID"));
    }
}

void updateEqList() {
    db.query("SELECT * FROM equipment");
    println("Device records:");
    equipmentList.clear();
    while (db.next()) {
      equipmentList.add(db.getString("name"));
      println(db.getString("name") + "\t" + db.getString("description") + "\t" + db.getString("UID"));
    }
}

String equipmentStatus( Equipment eq ) {
  if (eq.status == CHECKED_OUT)
    return "Checked out";
  else if (eq.status == CHECKED_IN)
    return "Checked in";
  else
    return "Unknown";
}

// Write the tag using the buffer
void writeTag(String[] tagWriteBuffer) {
   String tagContents = "";
   // If tag is user type, then prefix with 1:
   if (tagWriteBuffer[4].equals("USER_TAG")) {
     tagContents = str(USER_TAG) + ":" + tagWriteBuffer[3];
     // Update user table with other info
   } else { // If tag is equipment type, then prefix with 2:
     tagContents = str(EQUIPMENT_TAG) + ":" + tagWriteBuffer[3];
     // Update equipment table with other info
   }
   
   ketaiNFC.write(tagContents);
}
