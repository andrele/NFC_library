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

import controlP5.*;

// Initialize global variables
KetaiSQLite db;
KetaiNFC ketaiNFC;

ControlP5 cp5;
String CREATE_USERS_SQL = "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL  DEFAULT 'NULL',email TEXT NOT NULL  DEFAULT 'NULL',phone TEXT DEFAULT NULL,avatar_image TEXT DEFAULT NULL,id_badges INTEGER NOT NULL REFERENCES badges (id));";
String CREATE_EQUIPMENT_SQL = "CREATE TABLE equipment (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT DEFAULT NULL,description TEXT DEFAULT NULL);";
String CREATE_ACTIVITY_SQL = "CREATE TABLE activity (id INTEGER PRIMARY KEY AUTOINCREMENT,id_equipment INTEGER NOT NULL REFERENCES equipment (id),id_users INTEGER NOT NULL REFERENCES users (id));";
String CREATE_BADGES_SQL = "CREATE TABLE badges (id INTEGER PRIMARY KEY AUTOINCREMENT, UID TEXT DEFAULT NULL);";

String scanText = "Scan NFC Tag";
float rotation = 0;

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
//  orientation(LANDSCAPE);
  textAlign(CENTER, CENTER);
  textSize(36);
  ellipseMode(CENTER);
  noFill();
  stroke(255, 255, 255);
  strokeWeight(5);
}

void draw() {

  background(78, 93, 75);
  drawUI();
  
}

void onNFCEvent(String txt)
{
  scanText = "NFC Tag: " + txt;
}

void drawUI() {
  // Rotating Circle
  rotation += 1;
  if (rotation > 360) {
    rotation = 0;
  }
  pushMatrix();
  translate(width/2,height/2);
  text(scanText, 0, 0);
  rotate(radians(rotation));
  arc(0, 0, width/2, width/2, PI, PI*2);
  popMatrix();

}
