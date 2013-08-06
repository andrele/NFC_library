/* 
 * Database Functions
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

User findUserByEquipment (Equipment eq) {
  int userID = 0;
  User foundUser = new User();
  println("Finding user with badge using " + eq.name);
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
User findUser(String txt) {
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

Equipment findEquipment(String txt) {
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
      confirmationText = "Thanks for checking the " + equipment.name + "back in to us, " + user.name + "!";
      
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
void updateWriteBuffer(int tagType) {
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

void updateUserList() {
    db.query("SELECT * FROM users");
    println("User records:");
    usersList.clear();
    while (db.next()) {
      usersList.add(db.getString("name") + " / " + db.getString("email"));
      println(db.getString("name") + "\t" + db.getString("email") + "\t" + db.getString("phone") + "\t" + db.getString("UID"));
    }
}

void updateEqList() {
    int[] equipmentIds;
  
    db.query("SELECT * FROM equipment");
    println("Device records:");
    equipmentList.clear();
    while (db.next()) {
      String equipment = db.getString("name");
      String user = null;
      if ( db.getInt("checkout") == CHECKED_OUT ) {
        user = " / " + findUserByEquipment(findEquipment( db.getString("UID"))).name;
      }
      
      if (user == null)
        user = "";
        
      equipmentList.add( equipment + user );
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
