import java.util.ArrayList.*;
import java.awt.Color;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.widget.Toast;
import android.view.Gravity;
import android.bluetooth.*;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.TextView;
import android.widget.EditText;  
import android.widget.Button;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Set;
import java.util.UUID;


PVector pos = new PVector(0, 0);
ArrayList<String> items = new ArrayList<String>();
/*
  We want the data to be all the same
  By default it is delimited by newline character
  We want a few things:
    - and integer that says the soil quality
    - 2 bytes that represent date
    - 1 byte for hour
*/

boolean foundDevice = false;
BluetoothAdapter myAdapter;

TextView myLabel;
EditText myTextbox;
BluetoothSocket mmSocket;
BluetoothDevice mmDevice;
OutputStream mmOutputStream;
InputStream mmInputStream;
Thread workerThread;
byte[] readBuffer;
int readBufferPosition;
int counter;
volatile boolean stopWorker;

//40:4e:36:5b:26:c3
void setup() {
  size(1080, 1920);
}

void draw() {
  gui();
  showList();
  //debugLines();
  findBT();
  if(myAdapter!=null){
    try{
      openBT();
    } catch(IOException e){
       println("IOException error");
    }
  }
  
}
//---------------------------showList-----------------------------------------------
void showList() {
  //top bit
  rectMode(CENTER);
  fill(220);
  noStroke();
  rect(width/2, 195, width-200, 75);
  stroke(255, 0, 0);
  int inc = 55;
  line(300, 155, 300, 155 + inc + 25);
  line(width-300, 155, width-300, 155 + inc + 25);
  rectMode(LEFT);

  for (int i=0; i<4; i++) {
    //background rect
    fill(255);
    stroke(0);
    rect(100, 175 + (i * inc) + inc, width-100, 175 + inc + (i * inc) + inc);

    //dividers
    stroke(255, 0, 0);
    line(300, 160 + ((i+1) * inc) + 15, 300, 160 + inc + ((i+1) * inc) + 15);
    line(width-300, 160 + ((i+1) * inc) + 15, width-300, 160 + inc + ((i+1) * inc) + 15);
  }
}
//----------------------------GUI-------------------------------------------------
void gui() {
  //gui setup
  background(0);
  rectMode(CENTER);

  //top box
  fill(22, 193, 19);//green
  stroke(0);
  rect(width/2, 50, width, 100);
  fill(0);
  textAlign(LEFT);
  textSize(70);
  text("Plant Data", 10, 70);

  //connection
  if(myAdapter == null)//err on con
    fill(200, 30, 30);
  else
    fill(52, 235, 134);
  rect(width-100, 50, 200, 100);
  fill(0);
  textAlign(CENTER);
  textSize(50);
  text("CON", width-100, 70);
}
//-------------------------debugLines----------------------------------------------
void debugLines() {
  //red debug lines to show press location
  stroke(255, 0, 0);
  line(pos.x, 0, pos.x, height);
  line(0, pos.y, width, pos.y);
}
//---------------------mousePressed-------------------------------------------------
void mousePressed() {
  //debug line reset
  pos = new PVector(mouseX, mouseY);
}
//----------------------------------------------------------------------------------

void findBT() {
  myAdapter = BluetoothAdapter.getDefaultAdapter();//attempt connection to bluetooth device
  //no device found
  //if (myAdapter == null)
    //myLabel.setText("No bluetooth adapter available");

  //bluetooth is disabled on device
  /*
  if (!myAdapter.isEnabled()) {
    Intent enableBluetooth = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
    startActivityForResult(enableBluetooth, 0);
  }
  */

  Set<BluetoothDevice> pairedDevices = myAdapter.getBondedDevices();
  if (pairedDevices.size() > 0) {//if theres a paired device
    for (BluetoothDevice device : pairedDevices) {//find the one that has a name
      if (device.getName().equals("MattsBlueTooth")) {
        mmDevice = device;
        break;
      }
    }
  }
  //myLabel.setText("Bluetooth Device Found");
}


void openBT() throws IOException {
  UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"); //Standard SerialPortService ID
  mmSocket = mmDevice.createRfcommSocketToServiceRecord(uuid);        
  mmSocket.connect();
  mmOutputStream = mmSocket.getOutputStream();
  mmInputStream = mmSocket.getInputStream();

  beginListenForData();

  //myLabel.setText("Bluetooth Opened");
}



void beginListenForData() {
  final Handler handler = new Handler(); 
  final byte delimiter = 10; //This is the ASCII code for a newline character

  stopWorker = false;
  readBufferPosition = 0;
  readBuffer = new byte[1024];
  workerThread = new Thread(new Runnable() {
    public void run() {                
      while (!Thread.currentThread().isInterrupted() && !stopWorker) {
        try {
          int bytesAvailable = mmInputStream.available();                        
          if (bytesAvailable > 0) {
            byte[] packetBytes = new byte[bytesAvailable];
            mmInputStream.read(packetBytes);
            for (int i=0; i<bytesAvailable; i++) {
              byte b = packetBytes[i];
              if (b == delimiter) {
                byte[] encodedBytes = new byte[readBufferPosition];
                System.arraycopy(readBuffer, 0, encodedBytes, 0, encodedBytes.length);
                final String data = new String(encodedBytes, "US-ASCII");
                readBufferPosition = 0;
                //"data" is a string that is whatever is sent over the BT connection delimited by newline
                //shouldn't need any checks since the arduino waits still there is a valid serial connection to send anything
                handler.post(new Runnable() {
                  public void run() {
                    //myLabel.setText(data);
                    //println(myLabel);
                    items.add(data);
                  }
                }
                );
              } else {
                readBuffer[readBufferPosition++] = b;
              }
            }
          }
        } 
        catch (IOException ex) 
        {
          stopWorker = true;
        }
      }
    }
  }
  );

  workerThread.start();
}

void sendData() throws IOException {
  String msg = myTextbox.getText().toString();
  msg += "\n";
  mmOutputStream.write(msg.getBytes());
  myLabel.setText("Data Sent");
}

void closeBT() throws IOException {
  stopWorker = true;
  mmOutputStream.close();
  mmInputStream.close();
  mmSocket.close();
  myLabel.setText("Bluetooth Closed");
}
