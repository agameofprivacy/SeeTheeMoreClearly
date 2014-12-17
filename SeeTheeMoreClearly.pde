// See Thee More Clearly
// Creative Coding, Fall 2014
// Eddie Chen & Brigid Walsh
// Levels go up, play sound to increase difficulty to concentrate
// Display lyrics alongside audio track

// NeuroSky
import processing.serial.*; // this is a library to use serial
int whichport = 9; // change to your serial port
Serial myPort;      // The serial port
String inPut = "";    // Incoming (string) serial data
int realvals[]; // these are the numbers

float currentAttentionLevel = 0;
float lastAttentionLevel = 0;
int lastAttentionLevelTimeStamp = 0;
float attentionLevelDiff = 0.0;
StringList sourceImageFiles;
ArrayList<StringDict> questionnaires;
int numOfRounds = 10;
int difficultyFactor = 1;
int currentImageCount = 0;

float attentionCeiling = 95.0;
float attentionFloor = 0.0;
float blurrinessCeiling = 260.0;
float blurSizeCeiling = 36.0;
// when neurosky in, increase to 15000
float timePerRound = 20000.0;

boolean showTitleScreen = true;
boolean showSetup = false;
boolean inquireDifficulty = true;
boolean inquireContentPref = true;
String difficulty = null;
String contentPref = null;
int roundStartTime;
PImage currentImage;
boolean initialRoundTimeSet = false;
float blurriness = 200;
int blurSize = 100;
PShader blur;
PGraphics src;
PGraphics pass1, pass2;
boolean backToTitleScreen = false;
boolean gameOver = false;
int score = 0;
JSONArray images;
boolean roundActive = false;
int response = 0;
float blurSizeToChange;
float blurrinessToChange;
int blurStep = 0;
boolean valueChanged = false;
float currentFrameRate = 24.0;
PImage endGameImage;
void setup() {
  // setup screen
  size(displayWidth, displayHeight, P2D);

  // List all the available serial ports:
  println(Serial.list());

  // open the serial port to the arduino
  String portName = Serial.list()[whichport];
  myPort = new Serial(this, portName, 57600);
  //End of NeuroSky Setup  



  // initialize shader
  blur = loadShader("blurrr.glsl");
  src = createGraphics(displayWidth/4, displayWidth/4, P2D); 

  pass1 = createGraphics(src.width, src.height, P2D);
  pass1.noSmooth();  

  pass2 = createGraphics(width, height, P2D);
  pass2.noSmooth();

  blur.set("blurSize", 0);
  blur.set("sigma", 0);  

  // load questionnaires into ArrayList
  questionnaires = new ArrayList<StringDict>();

  // load sourceImageFiles into StringList
  sourceImageFiles = new StringList();
  sourceImageFiles.append("dreamBabe.jpeg");
  sourceImageFiles.append("puppies.jpeg");
  for (int i = 0; i <= 2; i++) {
    sourceImageFiles.append("dreamBabe.jpeg");
  }
}

void draw() {
  // NeuroSky Updates
  println("frame rate: " + frameRate);
  if ( myPort.available() > 0) {  // If data is available,
    inPut = myPort.readStringUntil('\n');
    if (inPut!=null) { // only run if not bogus
      inPut = trim(inPut); // gets rid of white space
      String vals[] = split(inPut, ",");

      if (vals.length==11) {
        realvals = new int[vals.length];
        for (int i = 0; i<realvals.length; i++)
        {
          realvals[i] = parseInt(vals[i]);
        }

        println(realvals[1]);
        //what could go up there + " " + realvals[1]

          if (float(realvals[1]) != currentAttentionLevel) {
          attentionLevelDiff = float(realvals[1]) - lastAttentionLevel; 
          lastAttentionLevel = currentAttentionLevel;
          currentAttentionLevel = float(realvals[1]);
          lastAttentionLevelTimeStamp = millis();
          blurSize = int(map(currentAttentionLevel, attentionFloor, attentionCeiling, blurSizeCeiling, 0));
          blurriness = int(map(currentAttentionLevel, attentionFloor, attentionCeiling, blurrinessCeiling, 0));
          currentFrameRate = frameRate;
          valueChanged = true;
          }
          else{
            valueChanged = false;
          }
      }
    }
  }

  if (gameOver) {
    if (keyPressed) {
      if (key == 32) {
        showSetup = false;
        showTitleScreen = true;
        currentImageCount = 0;
        gameOver = false;
        questionnaires.removeAll(questionnaires);
        difficulty = null;
        contentPref = null;
        score = 0;
        response = 0;
        initialRoundTimeSet = false;
        key = 0;
      }
    }
  }
  if (roundActive) {
    if (keyPressed) {
      if (key == 'J' || key == 'j') {
        response = 1;
        key = 0;
      } else if (key == 'K' || key == 'k') {
        response = 2;
        key = 0;
      } else if (key == 'L' || key == 'l') {
        response = 3;
        key = 0;
      }
    }
  }
  // title screen
  if (showTitleScreen) {
    // clear stats — to do
    // detect titleScreen and Setup keystrokes
    if (keyPressed) {
      // if backspace is pressed, go back to title screen
      if (key == BACKSPACE) {
        showSetup = false;
      }
      // if SPACE is pressed, go to setup screen
      else if (key == 32) {
        showSetup = true;
      }
    }
    if (showSetup) {
      if (keyPressed) {
        if (key == 'B' || key == 'b') {
          // set difficulty to Beginner
          difficulty = "Beginner";
          inquireDifficulty = false;
        } else if (key == 'I' || key == 'i') {
          // set difficulty to Intermediate
          difficulty = "Intermediate";
          inquireDifficulty = false;
        } else if (key == 'E' || key == 'e') {
          // set difficulty to Expert
          difficulty = "Expert";
          inquireDifficulty = false;
        }
        if (key == 'G' || key == 'g') {
          // set content preference to G
          contentPref = "G";
          inquireContentPref = false;
        } else if (key == 'P' || key == 'p') {
          // set content preference to PG
          contentPref = "PG";
          inquireContentPref = false;
        } else if (key == 'X' || key == 'x') {
          // set content preference to XXX 
          contentPref = "XXX";  
          inquireContentPref = false;
        }
        if (key == ENTER && difficulty != null && contentPref != null) {
          if (contentPref == "G") {
            images = loadJSONArray("g.json");
          } else if (contentPref == "PG") {
            images = loadJSONArray("pg.json");
          } else if (contentPref == "XXX") {
            images = loadJSONArray("xxx.json");
          }

          for (int i = 0; i < images.size (); i++) {

            JSONObject image = images.getJSONObject(i); 

            StringDict questionnaire = new StringDict();
            questionnaire.set("file", image.getString("file"));
            questionnaire.set("question", image.getString("question"));
            questionnaire.set("answer1", image.getString("answer1"));
            questionnaire.set("answer2", image.getString("answer2"));
            questionnaire.set("skipMessage", image.getString("skipMessage"));
            questionnaire.set("correctAnswer", image.getString("correctAnswer"));
            questionnaires.add(questionnaire);
          }          
          showTitleScreen = false;
        }
      }
    }

    // draw title screen
    if (!showSetup) {
      background(255, 255, 255, 255);
      textAlign(CENTER, CENTER);
      textSize(32);
      fill(0, 0, 0, 255);
      text("See Thee More Clearly", displayWidth/2, displayHeight/2.5);

      textSize(20);
      fill(50, 50, 50, 255);
      text("Press SPACE to start", displayWidth/2, displayHeight/2.0);
    }
    //draw setup screen
    else if (showSetup) {
      background(255, 255, 255, 255);
      fill(50, 50, 50, 255);
      textSize(32);
      text("Difficulty", displayWidth/2, displayHeight/3);
      textSize(20);
      text("Press 'B' for Beginner, 'I' for Intermediate, or 'E' for Expert", displayWidth/2, displayHeight/3 + 40);
      textSize(32);
      text("Content Preference", displayWidth/2, displayHeight/3 * 1.5);
      textSize(20);
      text("Press 'G' for General, 'P' for PG-13, or 'X' for XXX", displayWidth/2, displayHeight/3 * 1.5 + 40);
      if (difficulty != null) {
        fill(58, 168, 248, 255);
        String difficultySelectedString = "Difficulty: " + difficulty;
        textSize(20);
        text(difficultySelectedString, displayWidth/2, displayHeight/3 + 76);
      }
      if (contentPref != null) {
        fill(58, 168, 248, 255);
        String contentPrefSelectedString = "Content Preference: " + contentPref;
        textSize(20);
        text(contentPrefSelectedString, displayWidth/2, displayHeight/3 * 1.5 + 76);
      }
      if (difficulty != null && contentPref != null) {
        fill(248, 138, 58, 255);
        textSize(26);
        text("Press ENTER to Continue", displayWidth/2, displayHeight/3 * 2.2);
      }
    }
  } else if (!showTitleScreen) {
    // gameplay
    roundActive = true;
    if (valueChanged){
      blurSizeToChange = map(attentionLevelDiff, attentionFloor, attentionCeiling, blurSizeCeiling, 0);
      blurrinessToChange = map(attentionLevelDiff, attentionFloor, attentionCeiling, blurrinessCeiling, 0);
    }
    if (blurStep < currentFrameRate * 5 ) {
      blurSize += blurSizeToChange/currentFrameRate;
      blurriness += blurrinessToChange/currentFrameRate;
    println("current attention level: " + currentAttentionLevel);
    println("blurSize: " + blurSize);
    println("blurriness: " + blurriness);
    println("step: " + blurStep);
      
      ++blurStep;
    } else {
      blurStep = 0;
    }

    background(255, 255, 255, 255);
    if (currentImageCount < numOfRounds) {
      if (!initialRoundTimeSet) {
        currentImage = loadImage(questionnaires.get(0).get("file"));
        roundStartTime = millis();
        initialRoundTimeSet = true;
      }
      if (millis() - roundStartTime < timePerRound && response == 0) {
        currentImage = loadImage(questionnaires.get(currentImageCount).get("file"));        

        src.beginDraw();
        src.clear();
        currentImage.resize(src.width, src.height);
        src.image(currentImage, 0, 0);
        src.endDraw();
        blur.set("blurSize", blurSize);
        blur.set("sigma", blurriness);

        // Applying the blur shader along the vertical direction   
        blur.set("horizontalPass", 0);
        pass1.beginDraw();            
        pass1.clear();
        pass1.shader(blur);  
        pass1.background(255);
        pass1.image(src, 0, 0);
        pass1.endDraw();

        // Applying the blur shader along the horizontal direction      
        blur.set("horizontalPass", 1);
        pass2.beginDraw();   
        pass2.clear();        
        pass2.shader(blur);  
        pass2.image(pass1, (displayWidth - src.width)/2, (displayHeight - src.height)/2 - (displayHeight - src.height)/4);
        pass2.endDraw();    

        image(pass2, 0, 0);

        fill(0);
        textAlign(CENTER, CENTER);
        textSize(32);
        StringDict questionnaire = questionnaires.get(currentImageCount);
        text(questionnaire.get("question"), displayWidth/2, (displayHeight - src.height)/2 * 2.3);
        textSize(26);
        text("'J' for " + questionnaire.get("answer1"), displayWidth/4, (displayHeight - src.height)/2 * 2.5);
        text("'K' for " + questionnaire.get("answer2"), displayWidth/4*2, (displayHeight - src.height)/2 * 2.5);
        text("'L' to " + questionnaire.get("skipMessage"), displayWidth/4*3, (displayHeight - src.height)/2 * 2.5);

        textSize(20);
        textAlign(LEFT, BOTTOM);
        text("Time Remaining: " + (timePerRound/1000 - (millis() - roundStartTime)/1000) + "s", 40, height - 40);
        textAlign(CENTER, BOTTOM);
        text("Bonus Multiplier: " + (round((timePerRound/1000 - (millis() - roundStartTime)/1000)/(timePerRound/1000)*3) + 1) + "x", width/2, height - 40);   
        textAlign(RIGHT, BOTTOM);
        text("Score: " + score, width - 40, height - 40);
      } else if (millis() - roundStartTime >= timePerRound || response > 0) {
        if (currentImageCount < questionnaires.size() - 1) {
          // if answer is correct
          StringDict questionnaire = questionnaires.get(currentImageCount);
          if (response == int(questionnaire.get("correctAnswer"))) {
            score += (round((timePerRound/1000 - (millis() - roundStartTime)/1000)/(timePerRound/1000)*3) + 1);
          }
          // if answer is incorrect
          else {
          }

          ++currentImageCount;
          response = 0;
          roundStartTime = millis();
          currentImage = loadImage(questionnaires.get(currentImageCount).get("file"));        

          src.beginDraw();
          src.clear();
          currentImage.resize(src.width, src.height);
          src.image(currentImage, 0, 0);
          src.endDraw();
          blur.set("blurSize", blurSize);
          blur.set("sigma", blurriness);

          // Applying the blur shader along the vertical direction   
          blur.set("horizontalPass", 0);
          pass1.beginDraw();            
          pass1.clear();
          pass1.shader(blur);  
          pass1.background(255);
          pass1.image(src, 0, 0);
          pass1.endDraw();

          // Applying the blur shader along the horizontal direction      
          blur.set("horizontalPass", 1);
          pass2.beginDraw();   
          pass2.clear();        
          pass2.shader(blur);  
          pass2.image(pass1, (displayWidth - src.width)/2, (displayHeight - src.height)/2 - (displayHeight - src.height)/4);
          pass2.endDraw();    

          fill(0);
          textAlign(CENTER, CENTER);
          textSize(32);
          questionnaire = questionnaires.get(currentImageCount);
          text(questionnaire.get("question"), displayWidth/2, (displayHeight - src.height)/2 * 2.3);
          textSize(26);
          text("'J' for " + questionnaire.get("answer1"), displayWidth/4, (displayHeight - src.height)/2 * 2.5);
          text("'K' for " + questionnaire.get("answer2"), displayWidth/4*2, (displayHeight - src.height)/2 * 2.5);
          text("'L' to " + questionnaire.get("skipMessage"), displayWidth/4*3, (displayHeight - src.height)/2 * 2.5);

          textSize(20);
          textAlign(LEFT, BOTTOM);
          text("Time Remaining: " + (timePerRound/1000 - (millis() - roundStartTime)/1000) + "s", 40, height - 40);
          textAlign(CENTER, BOTTOM);
          text("Bonus Multiplier: " + (round((timePerRound/1000 - (millis() - roundStartTime)/1000)/(timePerRound/1000)*3) + 1) + "x", width/2, height - 40);   
          textAlign(RIGHT, BOTTOM);
          text("Score: " + score, width - 40, height - 40);
        }
        // end game screen
        else {
          StringDict questionnaire = questionnaires.get(currentImageCount);
          if (response == int(questionnaire.get("correctAnswer")) && !gameOver) {
            score += (round((timePerRound/1000 - (millis() - roundStartTime)/1000)/(timePerRound/1000)*3) + 1);
            println("score is: " + score);
          }
          gameOver = true;
          roundActive = false;
          if (gameOver) {
            background(30);
            if(score >= 2 * (numOfRounds * timePerRound/1000) / 3){
              endGameImage = loadImage("highScore.gif");
            }
            else if(score >= 1 * (numOfRounds * timePerRound/1000) / 3 && score < 2 * (numOfRounds * timePerRound/1000)){
              endGameImage = loadImage("mediumScore.gif");
            }
            else{
              endGameImage = loadImage("lowScore.gif");
            }
            image(endGameImage, 0, 0);
            fill(255, 255, 255, 255);
            textAlign(CENTER, CENTER);
            textSize(32);
            text("Game Over", displayWidth/2, displayHeight/2.5);
            fill(205, 205, 205, 255);
            textSize(20);
            text("Press SPACE to Restart", displayWidth/2, displayHeight/2.0);

            fill(205, 205, 205, 255);
            textSize(20);
            text("Score: " + score, displayWidth/2, displayHeight/1.6);
            // back to title screen
            
          }
        }
      }
    }
  }
}// End of draw()


boolean sketchFullScreen() {
  return true;
}

//void updateImageBlur(){
//
//}
//
//
//void displayPromptAndSelections(){
//  
//}

