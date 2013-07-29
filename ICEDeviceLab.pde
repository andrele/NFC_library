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
//import ketai.camera.*;

// Initialize global variables
KetaiSQLite db;
KetaiNFC ketaiNFC;
//KetaiCamera cam;
PImage img;

String CREATE_USERS_SQL = "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL  DEFAULT 'NULL',email TEXT NOT NULL  DEFAULT 'NULL',phone TEXT DEFAULT NULL,avatar_image TEXT DEFAULT NULL,id_badges INTEGER NOT NULL REFERENCES badges (id));";
String CREATE_EQUIPMENT_SQL = "CREATE TABLE equipment (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT DEFAULT NULL,description TEXT DEFAULT NULL, id_badges INTEGER NOT NULL REFERENCES badges (id));";
String CREATE_ACTIVITY_SQL = "CREATE TABLE activity (id INTEGER PRIMARY KEY AUTOINCREMENT,id_equipment INTEGER NOT NULL REFERENCES equipment (id),id_users INTEGER NOT NULL REFERENCES users (id), timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);";
String CREATE_BADGES_SQL = "CREATE TABLE badges (id INTEGER PRIMARY KEY AUTOINCREMENT, UID TEXT DEFAULT NULL);";

int currentScreen;
String scanText = "Scan NFC Tag";
float rotation = 0;
int fontSize = 36;

void setup()
{

  // Database setup
  db = new KetaiSQLite(this);  // open database file

  //  println("Dropping table users..." + db.query( "DROP TABLE IF EXISTS users;" ));
  //  println("Dropping table equipment..." + db.query( "DROP TABLE IF EXISTS equipment;" ));
  //  println("Dropping table activity..." + db.query( "DROP TABLE IF EXISTS activity;" ));
  //  println("Dropping table badges..." + db.query( "DROP TABLE IF EXISTS badges;" ));

  if ( db.connect() )
  {
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

    if (!db.tableExists("badges")) {
      db.execute(CREATE_BADGES_SQL);
      println("Executing " + CREATE_BADGES_SQL);
    }

    //    if (db.execute("INSERT INTO badges ('UID') VALUES ('AndreLe');"))
    //      println("Added AndreLe to badges");

    //    if (db.execute("INSERT INTO users ('name', 'email', 'phone', 'id_badges') VALUES ('Andre Le', 'andre.le@hp.com', '(619) 788-2610', 1);"))
    //      println("Added Andre Le to users");

    // Print record counts
    println("data count for users table: "+db.getRecordCount("users"));
    println("data count for equipment table: "+db.getRecordCount("equipment"));
    println("data count for activity table: "+db.getRecordCount("activity"));
    println("data count for badges table: "+db.getRecordCount("badges"));

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

  //  Setup Camera
//  cam = new KetaiCamera(this, 480, 640, 24);
//  cam.setCameraID(1);
}

void draw() {

  background(78, 93, 75);
  switch(currentScreen) {
  case 0: 
    drawScanScreen(); 
    break;
  case 1: 
    drawProfileScreen(); 
    break;
  case 2: 
    drawDeviceScreen(); 
    break;
  default: 
    drawScanScreen(); 
    break;
  }

  drawProfileScreen();
  println(generateUDID());
}

void onNFCEvent(String txt)
{
  switch(currentScreen) {
  case 0: 
    findBadgeOwner(txt);
    break;
  default:
    findBadgeOwner(txt);
    break;
  }
  scanText = "NFC Tag: " + txt;
}

void drawScanScreen() {
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


// Look up badge ID and associated equipment/user
void findBadgeOwner(String txt) {
  println("Finding badge...");
  Boolean success = false;
  db.query("SELECT * FROM badges WHERE UID LIKE '"+ txt + "';");
  while (db.next ())
  {
    println("Badge found. ID = " + db.getInt("id"));
    success = true;
  }

  if (!success)
    println("Badge not found.");

  success = false;
  db.query("SELECT * FROM badges INNER JOIN users ON badges.id = users.id_badges");
  while (db.next ())
  {
    println(db.getString("name") + "\t" + db.getString("email") + "\t" + db.getString("phone") + "\tID Badge: " + db.getInt("id_badges"));
    success = true;
  }

  if (!success)
    println("User not found.");

  success = false;
  db.query("SELECT * FROM badges INNER JOIN equipment ON badges.id = users.id_badges");
  while (db.next ())
  {

    println(db.getString("name") + "\t" + db.getString("description") + "\tID Badge: " + db.getInt("id_badges"));
    success = true;
  }

  if (!success)
    println("Equipment not found.");
}

// Function to generate a random 32 character alphanumeric string
String generateUDID() {
  String UDID = "";
  
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
    UDID = UDID + str((char)randomChar);
  }
  
  return UDID;
}
