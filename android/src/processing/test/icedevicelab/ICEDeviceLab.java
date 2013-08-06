package processing.test.icedevicelab;

import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import android.content.Intent; 
import android.os.Bundle; 
import android.text.InputType; 
import android.view.inputmethod.EditorInfo; 
import ketai.data.*; 
import ketai.net.nfc.*; 
import ketai.ui.*; 
import apwidgets.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class ICEDeviceLab extends PApplet {

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
APButton writeButton, readButton, userListButton, eqListButton, cancelButton, saveButton;
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
String checkoutStatus = "";
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

public void setup()
{
  // Database setup
  db = new KetaiSQLite(this);  // open database file

  if ( db.connect() )
  {
//    Delete all data (Uncomment for debugging only)
//    println("Dropped users table: " + db.execute( "DROP TABLE users;" ));
//    println("Dropped equipment table: " + db.execute( "DROP TABLE equipment;" ));
//    println("Dropped activity table: " + db.execute( "DROP TABLE activity;" ));
//    println("Dropped badges table: " + db.execute( "DROP TABLE badges;" ));
//    println("Deleting ALL database data!");
//    db.deleteAllData();
    
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
    
//    // Create an entry for testing
//    if (db.execute("INSERT INTO users ('name', 'email', 'phone', 'UID') VALUES ('Andre Le', 'andre.le@hp.com', '(619) 788-2610', 'pXqsnJE1Ja5Ysatm');"))
//      println("Added Andre Le to users");
//    if (db.execute("INSERT INTO equipment ('name', 'description', 'UID', 'checkout') VALUES ('Samsung S4', 'Best phone ever!', 'lGVQgmAsqOalY6bV', " + CHECKED_OUT + ");"))
//      println("Added Samsung S4 to equipment");
//    if (db.execute("INSERT INTO activity ('id_equipment', 'id_users', 'checkout') VALUES (1, 1, 1);"))
//      println("Added S4 checkout to Andre");

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
  
  cancelButton = new APButton(fontSize, fontSize, 200, 100, "Cancel");
//  saveButton = new APButton(width*2/3 - 125, height*1/2 + 50, 250, 100, "Save");
  writeContainer.addWidget(cancelButton);
//  writeContainer.addWidget(saveButton);
  
  if (currentUser != null) {
    nameText = currentUser.name;
    emailText = currentUser.email;
    phoneText = currentUser.phone;
  }
  
  nameField = new APEditText(x_offset, y_offset, width/2, 100);
  emailField = new APEditText(x_offset, PApplet.parseInt(fontSize * 2.5f) + y_offset, width/2, 100);
  phoneField = new APEditText(x_offset, PApplet.parseInt(fontSize * 5) + y_offset, width/2, 100);
  eqNameField = new APEditText(x_offset, y_offset, width/2, 100);
  eqDescriptionField = new APEditText(x_offset, PApplet.parseInt(fontSize * 2.5f) + y_offset, width/2, 100);
  
  
  editUserContainer = new APWidgetContainer(this);
  editEquipmentContainer = new APWidgetContainer(this);
  
    // Setup User Name Field
    editUserContainer.addWidget( nameField );
    nameField.setInputType(InputType.TYPE_CLASS_TEXT);
    nameField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    nameField.setCloseImeOnDone(true);   
    nameField.setText(nameText);
  
    // Setup User Email Field
    editUserContainer.addWidget( emailField );
    emailField.setInputType(InputType.TYPE_CLASS_TEXT);
    emailField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    emailField.setCloseImeOnDone(true);   
    emailField.setText(emailText);
  
    // Setup User Phone Field
    editUserContainer.addWidget( phoneField );
    phoneField.setInputType(InputType.TYPE_CLASS_PHONE);
    phoneField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    phoneField.setCloseImeOnDone(true);
    phoneField.setText(phoneText);
    
        // Setup Equipment Name Text Field
    editEquipmentContainer.addWidget( eqNameField );
    eqNameField.setInputType(InputType.TYPE_CLASS_TEXT);
    eqNameField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    eqNameField.setCloseImeOnDone(true);
    eqNameField.setText(nameText);
  
    // Setup Equipment Description Field
    editEquipmentContainer.addWidget( eqDescriptionField );
    eqDescriptionField.setInputType(InputType.TYPE_CLASS_TEXT);
    eqDescriptionField.setImeOptions(EditorInfo.IME_ACTION_DONE);
    eqDescriptionField.setCloseImeOnDone(true);
    eqDescriptionField.setText(descriptionText);
    
    writeContainer.hide(); // Hide the write container for now 
    editUserContainer.hide(); 
    editEquipmentContainer.hide();
}

public void draw() {

  background(0xff6db7ff);
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
    text("Tap screen to reset", width/2, fontSize * 1.5f);
    popStyle();
  }

}


/*
 * Event callbacks
 */
 
public void onNFCEvent(String txt)
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
    badgeType = PApplet.parseInt(badge[0]);
    badgeContents = badge[1];
    

    
    // Check to see if it's a recognized badge type
    if (badgeType == USER_TAG) {
      clearScreen();
      currentUser = findUser(badgeContents);
      if (currentUser == null) 
        currentScreen = UNRECOGNIZED_MODE;
      else 
        currentScreen = USER_PROFILE_MODE;
      

      
      if (lastTagType == EQUIPMENT_TAG && currentEquipment != null) {
        updateCheckout( currentUser, currentEquipment );
        return;
      }

    } else if (badgeType == EQUIPMENT_TAG) {
      clearScreen();
      currentEquipment = findEquipment(badgeContents);
      if ( currentEquipment == null ) {
        currentScreen = UNRECOGNIZED_MODE;
      } else {
        currentScreen = EQUIPMENT_PROFILE_MODE;
        setupEquipmentScreen();
      }
      
      if (lastTagType == USER_TAG && currentUser != null) {
        updateCheckout( currentUser, currentEquipment );
        return;
      }

    }  else {
      //  Unrecognized badge type. Enter creation mode
      clearScreen();
      println("Not a recognized badge type. Reprogram?");
      currentScreen = UNRECOGNIZED_MODE;
      newUID = generateUID();
      return;
    }
    
    lastScan = txt;
    println("Remembering last scan");
    lastTagType = badgeType;
    lastTagUID = badgeContents;
  } else {
    
      // Incompatible format
      clearScreen();
      currentScreen = UNRECOGNIZED_MODE;
      println("Unrecognized format. Reprogram?");
      newUID = generateUID();

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

public void onClickWidget(APWidget widget) {  
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
    updateWriteBuffer(USER_TAG);
  } else if (widget == eqNameField || widget == eqDescriptionField) {
    updateWriteBuffer(EQUIPMENT_TAG);
  } else if (widget == eqBadgeButton) {  // Check for badge type toggling
    setupWriteScreen( EQUIPMENT_TAG );
  } else if (widget == userBadgeButton) {
    setupWriteScreen( USER_TAG );
  } else if (widget == cancelButton) {
    currentScreen = SCAN_MODE;
    resetScanner();
    clearScreen();
  }
}

public void onKetaiListSelection(KetaiList klist) {
  String selection = klist.getSelection();
  println( "Selected " + selection);
}

public void onNFCWrite(boolean result, String message)
{
  if (result) {
    println("Success writing tag! Updating database...");
    updateRecord(tagWriteBuffer);
    changesMade = false;
    confirmationText = "Your changes were saved!";
    println(confirmationText);
    setupConfirmationScreen();
    vibe.vibrate(400);
    
  } else {
    confirmationText = "I have failed you! :(";
    println(confirmationText);
    setupConfirmationScreen();
    println("Failed to write tag: " + message);
  }
}

public void mousePressed() {
  
  if (currentScreen == EQUIPMENT_PROFILE_MODE || currentScreen == USER_PROFILE_MODE || currentScreen == UNRECOGNIZED_MODE || currentScreen == CONFIRMATION_MODE) {
    screenTitle = "Scanning Mode";
    currentScreen = SCAN_MODE;
    resetScanner();
    clearScreen();
  }
  
  if (mouseY < height*2/3 && currentScreen == CREATE_MODE) {
    KetaiKeyboard.hide(this);
    if (eqBadgeButton.isChecked())
      updateWriteBuffer(EQUIPMENT_TAG);
    else
      updateWriteBuffer(USER_TAG);
  }
}



/*
  The following code allows the sketch to handle all NFC events
 when it is running.  Eventually we would like to handle this
 in a more elegant manner for now cut'n'paste will suffice.  
 */
//====================================================================
public void onCreate(Bundle savedInstanceState) { 
  super.onCreate(savedInstanceState);
  ketaiNFC = new KetaiNFC(this);
}

public void onNewIntent(Intent intent) { 
  if (ketaiNFC != null)
    ketaiNFC.handleIntent(intent);
}

//====================================================================

/* 
 * Database Functions
 */
 
public boolean updateRecord(String[] buffer) {
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
    if (db.execute("INSERT INTO equipment ('name', 'description', 'UID') VALUES ('" + buffer[0] +"', '" + buffer[1] +"', '" + buffer[3] +"');")) {
      println("Added " + buffer[0] + " to equipment");
      return true;
    } else if (db.execute("UPDATE equipment SET name='" + buffer[0] + "',description='"+ buffer[1] + "' WHERE uid='" + buffer[3]+"';")) {
      println("Updated " + buffer[0] + ".");
      return true;
    }
  }
  return false;
}

public User findUserByEquipment (Equipment eq) {
  int userID = 0;
  User foundUser = new User();
  println("Finding user with badge using equipment ID: " + eq.id);
  db.query("SELECT * FROM activity WHERE id_equipment="+ eq.id + " ORDER BY id DESC LIMIT 1;");
  while (db.next ())
  {
    println("Found last checkout");
    db.query("SELECT * FROM users WHERE id=" + db.getInt("id_users") + ";");
    while (db.next())
    {
      foundUser.name = db.getString("name");
      foundUser.email = db.getString("email");
      foundUser.phone = db.getString("phone");
      foundUser.id = db.getInt("id");
      foundUser.UID = db.getString("UID");
      println("User found:");
      println(foundUser.name + "\t" + foundUser.email + "\t" + foundUser.phone + "\tID Badge: " + foundUser.id);
      return foundUser;
    }
  }

  println("User not found.");
  return null;  
}
 
// Look up badge ID and associated equipment/user
public User findUser(String txt) {
  User foundUser = new User();
  println("Finding user with badge " + txt);
  db.query("SELECT * FROM users WHERE UID LIKE'"+ txt + "';");
  while (db.next ())
  {

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

public Equipment findEquipment(String txt) {
  Equipment foundEquipment = new Equipment();
  println("Finding equipment with badge " + txt);
  db.query("SELECT * FROM equipment WHERE UID LIKE '"+ txt + "';");
  while (db.next ())
  {
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
public String generateUID() {
  String UID = "";
  
  for (int i = 0; i < 16; i++) {
    int randomChar = 0;
    Boolean validChar = false;
    while (validChar == false) {
      randomChar = PApplet.parseInt(random(48, 127));
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

public int getEquipmentCheckoutStatus( Equipment equipment ) {  
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
public void resetScanner() {
  println("Clearing scanner cache");
  lastTagID = 0;
  lastTagType = 0;
  lastTagUID = "";
  lastScan = "";
}

// Checks the device in/out
public void updateCheckout(User user, Equipment equipment) {
  int checkoutStatus = equipment.status;
  
  // If no previous activity, or currently CHECKED_IN, then checkout
  if ( checkoutStatus == -1 || checkoutStatus == CHECKED_IN ) {
    // Add record linking this equipment and user
    if (db.execute("INSERT INTO activity ('id_users', 'id_equipment', 'checkout') VALUES ("+ user.id +", "+ equipment.id +", "+ CHECKED_OUT +");") == true) {
      confirmationText = "Sweet! " + user.name + ", you just checked out the " + equipment.name + "!";
      
      if (db.execute("UPDATE equipment SET checkout=" + CHECKED_OUT + " WHERE id=" + equipment.id + ";") == true)
        println("Updated equipment status to CHECKED_OUT");
      
      println(confirmationText);
      setupConfirmationScreen();
    } else {
      println("Checkout failed. :(");
    }
  } else { // Looks like device was previously checked out. Check that baby in!
    if (db.execute("INSERT INTO activity ('id_users', 'id_equipment', 'checkout') VALUES ("+ user.id +", "+ equipment.id +", "+ CHECKED_IN +");") == true) {
      confirmationText = "Thanks for checking the " + equipment.name + " back in to us, " + user.name + "!";
      
      if (db.execute("UPDATE equipment SET checkout=" + CHECKED_IN + " WHERE id=" + equipment.id + ";") == true)
        println("Updated equipment status to CHECKED_IN");
      
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
public void updateWriteBuffer(int tagType) {
  println("Updating write buffer");
  if (tagType == USER_TAG) {
    println("User tag found");
    tagWriteBuffer[0] = nameField.getText();
    tagWriteBuffer[1] = emailField.getText();
    tagWriteBuffer[2] = phoneField.getText();
    if (lastTagUID.equals(""))
      tagWriteBuffer[3] = newUID;
    else
      tagWriteBuffer[3] = lastTagUID;
    tagWriteBuffer[4] = "USER_TAG";
  } else {
      println("Equipment tag found");
    tagWriteBuffer[0] = eqNameField.getText();
    tagWriteBuffer[1] = eqDescriptionField.getText();
    if (lastTagUID.equals(""))
       tagWriteBuffer[3] = newUID;
     else 
       tagWriteBuffer[3] = lastTagUID;
    
    tagWriteBuffer[4] = "EQUIPMENT_TAG";
  }
  
    println("Write buffer updated with: " + tagWriteBuffer[0] + " " + tagWriteBuffer[1] + " " + tagWriteBuffer[2] + " " + tagWriteBuffer[3] + " " + tagWriteBuffer[4]);
    changesMade = true;
    writeTag(tagWriteBuffer);
}

public void updateUserList() {
    db.query("SELECT * FROM users");
    println("User records:");
    usersList.clear();
    while (db.next()) {
      usersList.add(db.getString("name") + " / " + db.getString("email"));
      println(db.getString("name") + "\t" + db.getString("email") + "\t" + db.getString("phone") + "\t" + db.getString("UID"));
    }
}

public void updateEqList() {
  
  ArrayList<Integer> equipmentIds= new ArrayList<Integer>();
  
  db.query("SELECT * FROM equipment ORDER BY name DESC");
  println("Device records:");
  equipmentList.clear();
  while (db.next()) {
    equipmentIds.add( db.getInt("id") );
  }
  
  for (int i = 0; i < equipmentIds.size(); i++) {
    Equipment thisEquipment = getEquipmentById( equipmentIds.get(i) );
    String user = "";
    if (thisEquipment != null) {
      if ( getEquipmentCheckoutStatus( thisEquipment ) == CHECKED_OUT ) {
        user = " / " + findUserByEquipment( thisEquipment ).name;
      }
      equipmentList.add( thisEquipment.name + user );
    }
  }
}

public Equipment getEquipmentById( int id ) {
  Equipment foundEquipment = new Equipment();
  db.query("SELECT * FROM equipment WHERE id=" + id + ";");
  while (db.next()) {
    foundEquipment.id = db.getInt("id");
    foundEquipment.name = db.getString("name");
    foundEquipment.description = db.getString("description");
    foundEquipment.UID = db.getString("UID");
    foundEquipment.status = getEquipmentCheckoutStatus( foundEquipment );
    return foundEquipment;
  }
  
  return null;
}

public String equipmentStatus( Equipment eq ) {
  if (eq.status == CHECKED_OUT)
    return "Checked out";
  else if (eq.status == CHECKED_IN)
    return "Checked in";
  else
    return "Unknown";
}

// Write the tag using the buffer
public void writeTag(String[] tagWriteBuffer) {
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
class Equipment {
  int id;
  String name;
  String description;
  String UID;
  int status;
  Equipment () {
    id = 0;
    name = "";
    description = "";
    UID = "";
    status = -1;
  }
}
/*
 * Set up screens
 */
 
// badgeType can be 0 for Unrecognized, 1 for User Badge, and 2 for Equipment Badge
public void setupWriteScreen(int badgeType) {
  clearScreen();
  currentScreen = CREATE_MODE;
  writeContainer.show();

  if (badgeType == EQUIPMENT_TAG) {
    
    if ( currentEquipment != null ) { 
      eqNameField.setText( currentEquipment.name );
      eqDescriptionField.setText( currentEquipment.description ); 
    }
    
    userBadgeButton.setChecked(false);
    eqBadgeButton.setChecked(true);

    editEquipmentContainer.show();
    editUserContainer.hide();

  } else {
    
    userBadgeButton.setChecked(true);
    eqBadgeButton.setChecked(false);
    
    if (currentUser != null) {
      nameField.setText( currentUser.name );
      emailField.setText( currentUser.email );
      phoneField.setText( currentUser.phone );
    }
    
    editUserContainer.show();
    editEquipmentContainer.hide();
  } 
  
}

public void setupConfirmationScreen() {
  currentScreen = CONFIRMATION_MODE;
  resetScanner();
  clearScreen();
}



/*
 * Drawing subroutines. Gets called every draw loop (60 fps)
 */

public void clearScreen() {
  writeContainer.hide();
  editEquipmentContainer.hide();
  editUserContainer.hide();
  changesMade = false;
  ketaiNFC.cancelWrite();
}
 
public void drawConfirmationScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  text(confirmationText, width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

public void drawUnrecognizedScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  text("What kind of tag is this??\n\nScan again to enter\nedit mode.", width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

public void drawScanScreen() {
  // Set title of screen
  screenTitle = "Scanning Mode";
  // Rotating Circle
  rotation += 1;
  if (rotation > 360) {
    rotation = 0;
  }
  pushMatrix();
  pushStyle();
  textAlign(CENTER, CENTER);
  textSize(fontSize);
  popStyle();
  text("Welcome to the\nICE Device Lab!\n\nScan a tag to get started", width/2, height/2, width*5/6, height*2/3);
//  rotate(radians(rotation));
//  arc(0, 0, width/2, width/2, PI, PI*2);
  popMatrix();
}

public void drawProfileScreen() {
  screenTitle = "User Profile";
  pushStyle();
  text(currentUser.name + "\n" + currentUser.email + "\n" + currentUser.phone + "\n\nScan device tag to\ncheck it in or out", width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

public void setupEquipmentScreen() {
  if (currentEquipment.status == CHECKED_OUT) {
    checkoutStatus = "Currently checked out by "+ findUserByEquipment( currentEquipment ).name +"\n\nScan a user badge to\ncheck it in";
  } else if (currentEquipment.status == CHECKED_IN) {
    checkoutStatus = "Currently checked in\n\nScan a user badge to check out";
  } else {
    checkoutStatus = "Current Status: Unknown";
  }
}

public void drawEquipmentScreen() {
  screenTitle = "Equipment Profile";
  
  pushStyle();
  text(currentEquipment.name + "\n" + currentEquipment.description + "\n\n" + checkoutStatus, width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

public void drawWriteScreen(int badgeType) {
  screenTitle = "Edit mode";
  
  int y_text_offset = y_offset + 35;
  
  pushStyle();
  
  if (userBadgeButton.isChecked()) {
    textAlign(RIGHT, CENTER);
    text("Name", x_offset, y_text_offset);
    text("Email", x_offset, y_text_offset + (fontSize * 2.5f));
    text("Phone", x_offset, y_text_offset + (fontSize * 5));
  } else if (eqBadgeButton.isChecked()) {
    textAlign(RIGHT, CENTER);
    text("Name", x_offset, y_text_offset);
    text("Description", x_offset, y_text_offset + (fontSize * 2.5f));
  }
  
  textAlign(CENTER, CENTER);
  if ( eqBadgeButton.isChecked() || userBadgeButton.isChecked() ) {
    if (lastTagUID.equals("")) {
      text("New generated UID\n" + newUID, width/2, y_text_offset + (fontSize * 7.5f));
    } else {
      text("Existing UID\n" + currentUser.UID, width/2, y_text_offset + (fontSize * 7.5f));
    }
  }
  if (changesMade) {
    text("Changes detected. Scan tag again to save.", width/2, y_text_offset + (fontSize * 10.5f), width*5/6, height*2/3);
  }
  
  popStyle();

}
class User {
  int id;
  String name;
  String email;
  String phone;
  String UID;
  User () {
    id = 0;
    name = "";
    email = "";
    phone = "";
    UID = "";
  }
}

}
