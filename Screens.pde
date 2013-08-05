/*
 * Set up screens
 */
 
// badgeType can be 0 for Unrecognized, 1 for User Badge, and 2 for Equipment Badge
void setupWriteScreen(int badgeType) {
  currentScreen = CREATE_MODE;
  writeContainer.show();

  newUID = generateUID();
  if (currentUser != null && badgeType == USER_TAG) {
    
    userBadgeButton.setChecked(true);
    eqBadgeButton.setChecked(false);
    
    nameField.setText( currentUser.name );
    emailField.setText( currentUser.email );
    phoneField.setText( currentUser.phone );
    editUserContainer.show();
    editEquipmentContainer.hide();

//    lastTagType = USER_TAG;
    editUserContainer.show();
    println("User button pressed");  
  }
  
  if (currentEquipment != null && badgeType == EQUIPMENT_TAG) {
    
    userBadgeButton.setChecked(false);
    eqBadgeButton.setChecked(true);
    
    eqNameField.setText( currentEquipment.name );
    eqDescriptionField.setText( currentEquipment.description );
    
    editEquipmentContainer.show();
    editUserContainer.hide();

  }
  
}

void setupConfirmationScreen() {
  currentScreen = CONFIRMATION_MODE;
  resetScanner();
  clearScreen();
}



/*
 * Drawing subroutines. Gets called every draw loop (60 fps)
 */

void clearScreen() {
  writeContainer.hide();
  editEquipmentContainer.hide();
  editUserContainer.hide();
  changesMade = false;
  ketaiNFC.cancelWrite();
}
 
void drawConfirmationScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  text(confirmationText, width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

void drawUnrecognizedScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  text("What kind of tag is this??\nScan again to enter\nedit mode.", width/2, height/2, width*5/6, height*2/3);
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
  text(currentUser.name + "\n" + currentUser.email + "\n" + currentUser.phone + "\n\nScan device tag to\ncheck it in or out", width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

void drawEquipmentScreen() {
  screenTitle = "Equipment Profile";
  String checkoutStatus = "";
  
  if (currentEquipment.status == CHECKED_OUT) {
    checkoutStatus = "Currently checked out\n\nScan user badge to\ncheck it in";
  } else if (currentEquipment.status == CHECKED_IN) {
    checkoutStatus = "Currently checked in\n\nScan user badge to check out";
  } else {
    checkoutStatus = "Current Status: Unknown";
  }
  
  pushStyle();
  text(currentEquipment.name + "\n" + currentEquipment.description + "\n\n" + checkoutStatus, width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

void drawWriteScreen(int badgeType) {
  screenTitle = "Edit mode";
  
  pushStyle();
  
  if (badgeType == USER_TAG) {
    textAlign(RIGHT, CENTER);
    text("Name", x_offset, y_offset);
    text("Email", x_offset, y_offset + (fontSize * 2.5));
    text("Phone", x_offset, y_offset + (fontSize * 5));
  } else if (badgeType == EQUIPMENT_TAG) {
    textAlign(RIGHT, CENTER);
    text("Name", x_offset, y_offset);
    text("Description", x_offset, y_offset + (fontSize * 2.5));
  }
  
  textAlign(CENTER, CENTER);
  if (currentUser == null || currentUser.UID.equals("")) {
    text("New generated UID", width/2, y_offset + (fontSize * 7.5));
    text( newUID, width/2, y_offset + (fontSize * 9));
  } else {
    text("Existing UID", width/2, y_offset + (fontSize * 7.5));
    text( currentUser.UID, width/2, y_offset + (fontSize * 9));
  }
  
  if (changesMade) {
    text("Changes detected. Scan tag to rewrite", width/2, y_offset + (fontSize * 10.5));
  }
  
  popStyle();

}
