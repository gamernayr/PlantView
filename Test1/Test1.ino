// Include Libraries
#include "Arduino.h"
#include "BTHC05.h"
#include <Time.h>
#include <TimeLib.h>

//Pin defines
#define BTHC05_PIN_TXD  11
#define BTHC05_PIN_RXD  10
#define SensorPin A0

// object initialization
BTHC05 bthc05(BTHC05_PIN_RXD,BTHC05_PIN_TXD);

//data storage
int dys[10];
int mths[10];
int mins[10];
int hrs[10];
float reads[10];
int currentIndex = 0;

void setup() {
  //these lines are for serial usb debugging
  Serial.begin(9600);
  while (!Serial) ; // wait for serial port to connect. Needed for native USB
  Serial.println("start");

  //bluetooth channel open
  bthc05.begin(9600);

  //sync time to current
  setupTime();
  
  for(int i=0; i < 10; i++){
    dys[i] = i;
    mths[i] = i;
    mins[i] = i;
    hrs[i] = i;
    reads[i] = (float)i;
  }
}

void loop() {
  delay(2000);//change this for the reading spacing (maybe around every 8 hours)
  
  readStore();

  String received = bthc05.readString();

  if(received != "")
    batchSend();
}

void readStore(){
  time_t t = now();

  //set a delay time here by making a time_t of 0 
  //get a new reading from the sesnor pin
  float reading = in();

  //store it in the reads 
  reads[currentIndex] = reading;

  //use synced time to record time of current reading
  dys[currentIndex] = day(t);
  mths[currentIndex] = month(t);
  mins[currentIndex] = minute(t);
  hrs[currentIndex] = hour(t);

  //change currentIndex ot the next value, or reset if at the end
  currentIndex++;
  if(currentIndex == 10)
    currentIndex = 0;
}

void batchSend(){
  //bthc05.println(".Apr-11 17:20 600.22");
  for(int i=0; i < 10; i++){
    //build the string
    String out = ".";//start it with a dot since it might drop hte first character

    out += mths[i];
    out += "-";
    out += dys[i];

    out += "&";

    out += hrs[i];
    out += ":";
    out += mins[i];

    out += "&";

    out += reads[i];

    //output the string
    bthc05.println(out);
    delay(550);
  }
}

void setupTime(){
  //store initial date/time values
  String ti = __TIME__;//10:10:10
  String da = __DATE__;//Apr 19 2020

  int index = 0;
  
  //time setup
  //  hh:mm:ss - 24h format
  String hrStr = "";
  String minStr = "";
  String secStr = "";
  for(int i=0; i < ti.length(); i++){
    if(ti.charAt(i) == ':'){
      index++;
    } else{
      switch(index){
        case 0:
          hrStr += ti.charAt(i);
          break;
        case 1:
          minStr += ti.charAt(i);
          break;
        case 2:
          secStr += ti.charAt(i);
          break;
      }
    }
  }
  
  int hrInt = hrStr.toInt();
  int minInt = minStr.toInt();
  int secInt = secStr.toInt();
  
  //date setup
  // Mth dy year
  String dayStr = "";
  String mthStr = "";
  String yearStr = "";

  index = 0;

  for(int i=0; i < da.length(); i++){
    if(da.charAt(i) == ' '){
      index++;
    } else{
      switch(index){
        case 0:
          mthStr += da.charAt(i);
          break;
        case 1:
          dayStr += da.charAt(i);
          break;
        case 2:
          yearStr += da.charAt(i);
          break;
      }
    }
  }

  int mthInt = 4;//we should be parsing this
  //int dayInt = 28;
  int dayInt = dayStr.toInt();
  int yearInt = 2020;
  //int yearInt = yearStr.toInt();

  //setTime(hr, min, sec, day, mnth, yr)
  setTime(hrInt, minInt, secInt, dayInt, mthInt, yearInt);
  //Serial.print(dayInt);
  //Serial.print(dayStr);
  Serial.print(mthInt);
  Serial.print(" ");
  Serial.print(dayInt);
  Serial.println();
  Serial.println(hrStr + " " + minStr + " " + secStr + " " + dayStr + " " + mthStr + " " + yearStr);
}

float in() {
  float sensorVal = 0;
  for (int i = 0; i < 100; i++) {
    sensorVal += analogRead(SensorPin);
    delay(15);
  }
  //average them into one reading
  return sensorVal /= 100;
}

/*
  time_t t = now(); // store the current time in time variable t
  hour(t);          // returns the hour for the given time t
  minute(t);        // returns the minute for the given time t
  second(t);        // returns the second for the given time t
  day(t);           // the day for the given time t
  weekday(t);       // day of the week for the given time t
  month(t);         // the month for the given time t
  year(t);          // the year for the given time t
 */
