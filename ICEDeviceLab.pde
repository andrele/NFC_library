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

import ketai.data.*;
import ketai.net.nfc.*;
import ketai.ui.*;

import apwidgets.*;


// Initialize global variables
KetaiSQLite db;
KetaiNFC ketaiNFC;

APWidgetContainer widgetContainer;
APButton writeButton;
APButton readButton;

public static final String CREATE_USERS_SQL = "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL, email TEXT NOT NULL, phone TEXT DEFAULT NULL,avatar_image TEXT DEFAULT NULL, UID TEXT UNIQUE);";
public static final String CREATE_EQUIPMENT_SQL = "CREATE TABLE equipment (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT DEFAULT NULL, description TEXT DEFAULT NULL, available INTEGER DEFAULT 1, UID TEXT UNIQUE, status INTEGER DEFAULT 1);";
public static final String CREATE_ACTIVITY_SQL = "CREATE TABLE activity (id INTEGER PRIMARY KEY AUTOINCREMENT,id_equipment INTEGER NOT NULL REFERENCES equipment (id),id_users INTEGER NOT NULL REFERENCES users (id), timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, status INTEGER DEFAULT 0);";

public static final int USER_TAG = 1;
public static final int EQUIPMENT_TAG = 2;
int lastTagType = 0;
String lastTagUID = "";

public static final int SCAN_MODE = 1;
public static final int CREATE_MODE = 2;
public static final int USER_PROFILE_MODE = 3;
public static final int EQUIPMENT_PROFILE_MODE = 4;
int currentScreen = 0;
String scanText = "Scan NFC Tag";
String screenTitle = "";
float rotation = 0;
int fontSize = 36;

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
    String newUID = generateUID();
    if (db.execute("INSERT INTO users ('name', 'email', 'phone', 'UID') VALUES ('Andre Le', 'andre.le@hp.com', '(619) 788-2610', '"+ newUID +"');"))
          println("Added Andre Le to users");

    // Print record counts
    println("data count for users table: "+db.getRecordCount("users"));
    println("data count for equipment table: "+db.getRecordCount("equipment"));
    println("data count for activity table: "+db.getRecordCount("activity"));

    // Existing code
    //    println("data count for data table: "+db.getRecordCount("data"));
    //
    //    //lets insert a random number or records
    //    int count = (int)random(1, 5);
    //
    //    for (int i=0; i < count; i++)
    //      if (!db.execute("INSERT into data (`name`,`age`) VALUES ('person"+(int)random(0, 100)+"', '"+(int)random(1, 100)+"' )"))
    //        println("error w/sql insert");
    //
    //    println("data count for data table after insert: "+db.getRecordCount("data"));
    //
    //    // read all in table "table_one"
    //    db.query( "SELECT * FROM data" );
    //
    //    while (db.next ())
    //    {
    //      println("----------------");
    //      print( db.getString("name") );
    //      print( "\t"+db.getInt("age") );
    //      println("\t"+db.getInt("foobar"));   //doesn't exist we get '0' returned
    //      println("----------------");
    //    }
  }

  // Setup Draw settings
  orientation(PORTRAIT);
  textAlign(CENTER, CENTER);
  textSize(fontSize);
  ellipseMode(CENTER);
  noFill();
  stroke(255, 255, 255);
  strokeWeight(5);
  currentScreen = SCAN_MODE;
  
  widgetContainer = new APWidgetContainer(this); // create new container for widgets
  writeButton = new APButton(width/3, height - fontSize*3, "Write NFC Tag");
  readButton = new APButton(width/3*2, height - fontSize*3, "Read NFC Tag");
  widgetContainer.addWidget(writeButton);
  widgetContainer.addWidget(readButton);

}

void draw() {

  background(78, 93, 75);
  switch(currentScreen) {
  case SCAN_MODE: 
    drawScanScreen(); 
    break;
  case CREATE_MODE:
    break;
  case USER_PROFILE_MODE: 
    break;
  case EQUIPMENT_PROFILE_MODE:
    break;
  default: 
    drawScanScreen(); 
    break;
  }
  
  // Persistent UI
  text(screenTitle, width/2, fontSize * 2);
  

}

void onNFCEvent(String txt)
{
  if (currentScreen == SCAN_MODE) {
    
    // Check to see if the : delimiter is in the right place
    if (txt.indexOf(":") == 2) {
      
      
      int badgeType = 0;
      String badgeContents = "";
      String[] badge = split(txt, ':');
      badgeType = int(badge[0]);
      badgeContents = badge[1];
      
      if (badgeType == USER_TAG) {
        findUser(badgeContents);
        scanText = "User Badge/n Badge Contents: " + badgeContents;
        lastTagType = USER_TAG;
        lastTagUID = badgeContents;
      } else if (badgeType == EQUIPMENT_TAG) {
        findEquipment(badgeContents);
        lastTagType = EQUIPMENT_TAG;
        lastTagUID = badgeContents;
      }  else {
        //  Unrecognized tag. Ask to create
        scanText = "Unrecognized tag.";
      }  
    } else {
      // Unrecognized tag. Ask to create
      scanText = "Unrecognized tag.";
    }
    
    println(scanText);
  }
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
  text(scanText, 0, 0);
  rotate(radians(rotation));
  arc(0, 0, width/2, width/2, PI, PI*2);
  popMatrix();
}

void drawProfileScreen() {
  screenTitle = "Profile";
  pushStyle();
  int x_offset = 50;
  int y_offset = 150;
  textAlign(LEFT, CENTER);
  text("Name", x_offset, y_offset);
  text("Email", x_offset, y_offset + (fontSize * 2.5));
  text("Phone", x_offset, y_offset + (fontSize * 5));

  popStyle();
}

//void drawProfileCreationScreen() {  
//   pushMatrix();
//   rotate(PI);
//   
//   if () {
//   }
//}


void drawDeviceScreen() {
}


void onClickWidget(APWidget widget) {
  if (widget == writeButton) {
    screenTitle = "Write Mode";
    currentScreen = CREATE_MODE;
  } else if (widget == readButton) {
    screenTitle = "Scanning Mode";
    currentScreen = SCAN_MODE;
  }
}


/* 
 * Utility Functions
 */
 
// Look up badge ID and associated equipment/user
int findUser(String txt) {
  println("Finding user with badge " + txt);
  db.query("SELECT * FROM users WHERE UID LIKE '"+ txt + "';");
  while (db.next ())
  {
    currentScreen = USER_PROFILE_MODE;
    println("User found:");
    println(db.getString("name") + "\t" + db.getString("email") + "\t" + db.getString("phone") + "\tID Badge: " + db.getString("badge"));
    return db.getInt("id");
  }
  
  scanText = "User not found.";
  println(scanText);
  return 0;
}

int findEquipment(String txt) {
  println("Finding equipment with badge " + txt);
  db.query("SELECT * FROM equipment WHERE UID LIKE '"+ txt + "';");
  while (db.next ())
  {
    currentScreen = EQUIPMENT_PROFILE_MODE;
    println("Equipment found:");
    println(db.getString("name") + "\t" + db.getString("description") + "\tID Badge: " + db.getString("UID"));
    return db.getInt("id");
  }
  
  scanText = "Equipment not found.";
  println(scanText);
  return 0;
}

// Function to generate a random 32 character alphanumeric string
String generateUID() {
  String UID = "";
  
  for (int i = 0; i < 32; i++) {
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
