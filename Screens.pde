/*
 * Set up screens
 */
 
// badgeType can be 0 for Unrecognized, 1 for User Badge, and 2 for Equipment Badge
void setupWriteScreen(int badgeType) {
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
    checkoutStatus = "Currently checked out by "+ findUserByEquipment( currentEquipment ).name +"\n\nScan a user badge to\ncheck it in";
  } else if (currentEquipment.status == CHECKED_IN) {
    checkoutStatus = "Currently checked in\n\nScan a user badge to check out";
  } else {
    checkoutStatus = "Current Status: Unknown";
  }
  
  pushStyle();
  text(currentEquipment.name + "\n" + currentEquipment.description + "\n\n" + checkoutStatus, width/2, height/2, width*5/6, height*2/3);
  popStyle();
}

void drawWriteScreen(int badgeType) {
  screenTitle = "Edit mode";
  
  int y_text_offset = y_offset + 35;
  
  pushStyle();
  
  if (userBadgeButton.isChecked()) {
    textAlign(RIGHT, CENTER);
    text("Name", x_offset, y_text_offset);
    text("Email", x_offset, y_text_offset + (fontSize * 2.5));
    text("Phone", x_offset, y_text_offset + (fontSize * 5));
  } else if (eqBadgeButton.isChecked()) {
    textAlign(RIGHT, CENTER);
    text("Name", x_offset, y_text_offset);
    text("Description", x_offset, y_text_offset + (fontSize * 2.5));
  }
  
  textAlign(CENTER, CENTER);
  if ( eqBadgeButton.isChecked() || userBadgeButton.isChecked() ) {
    if (lastTagUID.equals("") || currentUser.UID.equals("") || currentEquipment.UID.equals("")) {
      text("New generated UID", width/2, y_text_offset + (fontSize * 7.5));
      text( newUID, width/2, y_offset + (fontSize * 9));
    } else {
      text("Existing UID", width/2, y_text_offset + (fontSize * 7.5));
      text( currentUser.UID, width/2, y_text_offset + (fontSize * 9));
    }
  }
  if (changesMade) {
    text("Changes detected. Scan tag again to save.", width/2, y_text_offset + (fontSize * 10.5), width*5/6, height*2/3);
  }
  
  popStyle();

}
