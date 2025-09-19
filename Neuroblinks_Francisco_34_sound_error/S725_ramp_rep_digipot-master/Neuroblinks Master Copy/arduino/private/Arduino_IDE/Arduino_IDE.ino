// TODO: Put Arduino to sleep when not running neuroblinks (e.g. pmc_enable_sleepmode())
// TODO: Deal with overflow of millisecond/microsecond timers
// TODO: Non-blocking Serial IO and better serial communication generally (consider Serial.SerialEvent())
#include "main.hpp"
#include "Encoder.h"
#include "MCP4131.h" //Module for tone volume modulation
#include "AD9833.h" //Module for tone generator
#include "DueTimer.h" //Module to generate interumptions and modulte the tone volume

#include "SPI.h"
#include "Tic.h" //module for motor control


// Stimulus channels (as defined in Matlab code)
const int ch_led = 1;
const int ch_puffer_other = 2;
const int ch_puffer_eye = 3;
const int ch_tone = 5;
const int ch_brightled = 7;

// Outputs
const int pin_ss_MCP4131 = 4;  // Potentiometer: slave select Pin for SPI module (active in low). Need one for each external chip you are going to control.
const int pin_ss_AD9833 = 5; // wave generator: slave selected Pin for SPI module (active in low). Need one for each external chip you are going to control.
const int pin_brightled = 7;
const int pin_camera = 8;
const int pin_led = 9;
const int pin_whisker = 10;
const int pin_tone = 11;
const int pin_laser = 12;
const int pin_eye_puff = 13;

// Index into array indicates stimulus number as specified in Matlab, value at that index is corresponding pin number on Arduino
// Index zero should always have zero value because there is no stimulus 0
// Other zeros can be filled in with other values as needed
const int stim2pinMapping[10] {
    0,
    pin_led,
    pin_whisker,
    pin_eye_puff,
    0,
    pin_tone,
    pin_tone,
    pin_brightled,
    0,
    0
};

// Task variables (time in ms, freq in hz) - can be updated from Matlab
// All param_* variables must be 16-bit ints or else they will screw up Serial communication
//    and get mangled
int param_campretime = 200;
int param_camposttime = 800;
int param_csdelay = 0;
int param_csdur = 500;
int param_csch = ch_led;   // default to LED
int param_cs2delay = 0;
int param_cs2dur = 0;
int param_cs2ch = ch_tone;   // default to tone


int param_ISI = 200;
int param_usdur = 20;
/////////////FRANCISCO////////////////
int param_ISI_eye_2 = 0;
int param_usdur_eye_2 = 0;
int param_usch_eye_2 = ch_puffer_other;   // default to second ipsi corneal puff
//////////////////////////////////////

int param_usch = ch_puffer_eye;   // default to ipsi corneal puff
int param_tonefreq = 10000;
int param_csintensity = 64; // default to max intensity
int param_tonecsintensity = 128; // default to max intensity, Olivia splitting tone intensity variable out for ease of use 6/4/2020
int param_csrepeats = 1; //number of repetitions of tone for sequence training
int param_csperiod = 0; //period only necessary for repeating CSs

// For laser stim during trials, time values in ms
int param_laserdelay = 0; // delay from CS onset until laser onset
int param_laserdur = 0; // duration of laser pulse
int param_laserperiod = 0; // period of laser pulse
int param_lasernumpulses = 1; // number of laser pulses in train
int param_rampoffdur = 0; //ALvaro 10/19/18
int param_laserpower = 0; // In DAC units (i.e., 0 --> GND, 4095 --> Vs)
int param_lasergain = 1;
int param_laseroffset = 0;

//MOTOR PARAMETERS
int param_motorcurrent = 0;
int param_motordelaypositive = 0; //this delay is respect to the start of the camerar.
int param_motordelaynegative = 0; //this delay is respect to the start of the camerar.
int param_motordur = param_campretime + param_camposttime;
int param_motorenergizedtrial = 0;
int32_t param_motorspeedtrial = 20000000;
int32_t param_motoraccelerationtrial = 40000000;
int param_motorenergizedintertrials = 0;
int param_PREVIOUSmotorenergizedintertrials=0;
int32_t param_motorspeedintertrials = 20000000;
int32_t param_motoraccelerationintertrials = 40000000;

int param_microstep=16;
float wheel_diameter_in_mm = 203; //203; //152.4;//SET THIS PARAMETER WITH THE DIAMETER OF THE WHEEL.
float perimeter = wheel_diameter_in_mm*3.141592;
float N_pulses_per_revolution = 2000000*param_microstep;
uint32_t time_since_last_motor_reset = 0;


int param_encoderperiod = 5; // in ms
int param_encodernumreadings = (param_campretime + param_camposttime) / param_encoderperiod; // number of readings to take during trial

// Codes for sending arrays to Matlab - consider enum type cast to byte
const byte ENCODER_L = 100;
const byte TIME_L = 101;
// For converting longs to bytes
const uint32_t bit_patterns_long[4] = { 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000 };
const uint16_t bit_patterns_int[2] = { 0x00ff, 0xff00 };

bool RUNNING = false;

/////////////TONE///////////
//The total duration of the ramp up or ramp down in the tone modulation will be tone_update_sampe_size_us * N_sin_table_elements = 5000 us = 5 ms
const unsigned long tone_update_sampe_size_us = 100; // time between updates of the tone volume during ramp up and ramp down in microseconds
const int N_sin_table_elements = 50; //Total number of updates during ramp up and ramp down tone updates
float sin_table[N_sin_table_elements]; //Precomputed shape of tone modulation for ramp up and ramp down.
int tone_counter_ramp_up = 0;
int tone_counter_ramp_down = N_sin_table_elements-1;

////////////////////////////

// Default constructors for StateMachine objects
// It's probably more flexible if we create an array of StateMachine objects that we can iterate through in main loop but for now this will work
//    and seems easier to comprehend
Stimulus camera(0, param_campretime + param_camposttime, digitalOn, digitalOff, pin_camera);
Stimulus US(param_campretime + param_ISI, param_usdur, digitalOn, digitalOff, stim2pinMapping[param_usch]);
Stimulus US_eye_2(param_campretime + param_ISI_eye_2, param_usdur_eye_2, digitalOn, digitalOff, stim2pinMapping[param_usch_eye_2]);
StimulusRepeating laser(param_campretime + param_laserdelay, param_laserdur, laserOn, laserOff, 0, param_laserperiod, param_lasernumpulses); //ALvaro 10/19/18
StimulusRepeating CS(param_campretime + param_csdelay, param_csdur, digitalOn, digitalOff, stim2pinMapping[param_csch], param_csperiod, param_csrepeats);
Stimulus CS2(param_campretime + param_cs2delay, param_cs2dur, digitalOn, digitalOff, stim2pinMapping[param_cs2ch]);


Stimulus motor(param_motordelaypositive, param_motordur, motorTrialStart, motorTrialEnd, -1);

SensorRepeating diff_enc(0, takeEncoderReading, param_encoderperiod, param_encodernumreadings);

Encoder cylEnc(2, 3); // pins used should have interrupts, e.g. 2 and 3



TicI2C tic; //object to control motor movement.

void reset_I2C_port(){
  //reset pin 21 (I2C port)
  pinMode(21, OUTPUT);
   for (int i = 0; i < 8; i++) {
     digitalWrite(21, HIGH);
     delayMicroseconds(3);
     digitalWrite(21, LOW);
     delayMicroseconds(3);
   }
  pinMode(21, INPUT);
  Wire.setClock(20000);
  Wire.begin();
}

// The setup routine runs once when you press reset or get reset from Serial port
void setup() {
  // Initialize the digital pin as an output.
  pinMode(pin_camera, OUTPUT);
  pinMode(pin_led, OUTPUT);
  pinMode(pin_eye_puff, OUTPUT);
  pinMode(pin_whisker, OUTPUT);
  pinMode(pin_brightled, OUTPUT);
  pinMode(pin_laser, OUTPUT);


  // Default all output pins to LOW - for some reason they were floating high on the Due before I (Shane) added this
  digitalWrite(pin_camera, LOW);
  digitalWrite(pin_led, LOW);
  digitalWrite(pin_eye_puff, LOW);
  digitalWrite(pin_whisker, LOW);
  digitalWrite(pin_brightled, LOW);
  digitalWrite(pin_laser, LOW);


  //Since we are going to control two differnt SPI chips, we must select each one using these ssPin (pin_ss_XXXXXX LOW means the chip will respond to SPI commands).
  tone_generator.Begin(); //initialize the tone generator chip
  //These timers will be used to generate interuptions and modulate the tone amplitude.
  Timer7.attachInterrupt(toneRampUp);
  Timer7.setPeriod(tone_update_sampe_size_us);
  Timer8.attachInterrupt(toneRampDown);
  Timer8.setPeriod(tone_update_sampe_size_us);

  //Precompute the table to do the ramp up and ramp down in the tone
  for (int i = 0; i < N_sin_table_elements; i++){
    sin_table[i]=sin(1.570796*i/(N_sin_table_elements-1));
  }



  Serial.begin(115200);

  //reset pin 21 (I2C port)
  reset_I2C_port();

  //DACWrite(0);


  //Disable the tone generation
  delay(10);
  tone_generator.ApplySignal(SINE_WAVE, REG0, 0);
  delay(2);
  tone_generator.EnableOutput(false);
  delay(2);
  tone_amplitude.writeWiper(0);





  //Motor configuration
  tic.setDecayMode(TicDecayMode::Fast);
  tic.setStepMode(TicStepMode::Microstep16);
  param_microstep = 16;
  tic.setCurrentLimit(param_motorcurrent);
  tic.setMaxSpeed(mm_per_s_to_pulses_per_s(1000)); //MAXIMUM SPEED = 1000 mm/s = 1 m/s
  tic.setMaxAccel(0);
  tic.setMaxDecel(0);
  tic.setTargetVelocity(0);
  tic.deenergize();
  tic.exitSafeStart();

  //This timer will automatically execute the function resetMotorTimeout each 500 ms to reset the motor timeout
  //(THIS TIMEOUT MUST BE RESET AT LEAST EACH 1000 ms)
  //Timer7.attachInterrupt(resetMotorTimeout).start(500000); // Every 500ms
  time_since_last_motor_reset = millis();
}

// The loop routine runs over and over again forever
// In this loop we have our StateMachines check their states and update as necessary
// The StateMachines handle their own timing
// It's critical that this loop runs fast (< 1 ms period) so don't put anything in here that takes time to execute
// if a trial is running (e.g. "blocking" serial port access should only happen when trial isn't RUNNING)
void loop() {

  //This function resets the motor timeout in the chip that control the motor. This timeout must be reset
  //at least one time each 1000 ms.
  resetMotorTimeout();

  if (RUNNING) {
      // We explicitly check for zero durations to prevent stimuli from flashing on briefly when update() called and duration is zero
      if (param_csdur > 0) { CS.update();}
      if (param_cs2dur > 0) { CS2.update(); }
      if (param_usdur > 0) { US.conditionedUpdate(51); }
      if (param_usdur_eye_2 > 0) { US_eye_2.conditionedUpdate(52); }
      //if (param_usdur > 0) { US.update(); }
      if (param_laserdur > 0) { laser.update(); }

      if (param_motordur > 0) { motor.update(); }

      camera.update();

      diff_enc.update();

      if (camera.checkState()==camera.OFF && CS.checkState()==CS.OFF && CS2.checkState()==CS2.OFF && US.checkState()==US.OFF && US_eye_2.checkState()==US_eye_2.OFF && laser.checkState()==laser.OFF && motor.checkState()==motor.OFF) {
        endOfTrial();
      }

      //Trial aborted by Matlab
      if (Serial.available() > 2 && Serial.peek() == 50) {
          Serial.read(); Serial.read(); Serial.read(); //remove the byte corresponding to the header and the data
          //stop all the stimulus but the camera
          abortTrial();
      }

  }

  else {
      //Disable the tone generation
      tone_generator.EnableOutput(false);
      
      checkVars();
      if (Serial.available() > 0) {
          if (Serial.peek() == 110) { // This is the header for handsack protocol; difference from variable communication is that only one byte is sent in each direction
              byte confirmation = Serial.read();  // Clear the value from the buffer
              flushReceiveBuffer();
              Serial.write(confirmation);
          }
          else if (Serial.peek() == 1) { // This is the header for triggering; difference from variable communication is that only one byte is sent telling to trigger
              Serial.read();  // Clear the value from the buffer
              startTrial();
          }
          else if (Serial.peek() ==2) { //This is the header for send the encoder data form arduino to matlab.
              Serial.read();  // Clear the value from the buffer
              // We should eventually generalize this part for sending and receiving settings/data with Matlab
              sendEncoderData();
              //reset the encoder
              diff_enc.reset();
          }
      }
  }

}

// Check to see if Matlab is trying to send updated variables
// (should we send specific code to indicate that we are sending variables?)
void checkVars() {
  int header;
  int value;
  // Matlab sends data in 3 byte packets: first byte is header telling which variable to update,
  // next two bytes are the new variable data as 16 bit int (can only send 16 bit ints for now)
  // Header is coded numerically (0, 1, and 2 are reserved for special functions so don't use them to code variable identities)
  while (Serial.available() > 2) {
    //This function resets the motor timeout in the chip that control the motor. This timeout must be reset
    //at least one time each 1000 ms.
    resetMotorTimeout();


    header = Serial.read();
    value = Serial.read() | Serial.read() << 8;

    // If you add a new case don't forget to put a break statement after it; c-style switches run through
    switch (header) {
      case 3:
        param_campretime = value;
        break;
      case 4:
        param_csch = value;
        break;
      case 5:
        param_csdur = value;
        break;
      case 6:
        param_usdur = value;
        break;
      case 7:
        param_ISI = value;
        break;
      case 8:
        param_tonefreq = value;
        break;
      case 9:
        param_camposttime = value;
        break;
      case 10:
        param_usch = value;
        break;
      case 11:
        param_laserdelay = value;
        break;
      case 12:
        param_laserdur = value;
        break;
      case 13:
        param_laserpower = value;
        break;
      case 49:
        //param_csintensity = value; Alvaro 05/09/19 from sheiney committed on Jan 18, 2017
        // setDiPoValue(param_csintensity);
        // The Matlab code stores intensity values up to 256 because it's nicer to deal with   Alvaro 05/09/19 sheiney committed on Jan 18, 2017
        // multiples of 2 but we can only pass at most 255 so we have to correct that here.  Alvaro 05/09/19 sheiney committed on Jan 18, 2017
        // Zero is a special case because when the user specifies 0 they want it to mean "off"  Alvaro 05/09/19 sheiney committed on Jan 18, 2017
        param_csintensity = value==0 ? value : value-1; //Alvaro
        break;
      case 14:
        param_tonecsintensity = value==0 ? value : value-1;
        break;
      case 15:
        param_laserperiod = value;
        break;
      case 16:
        param_lasernumpulses = value;
        break;
      case 20:
        param_csperiod = value;
        break;
      case 21:
        param_csrepeats = value;
        break;
      case 22:
        param_rampoffdur = value; //ALvaro 10/19/18
        break;
      //////////////////////////FRANCISCO////////////////////
      case 30:
        param_ISI_eye_2= value;
        break;
      case 31:
        param_usdur_eye_2= value;
        break;
      case 32:
        param_usch_eye_2= value;
        break;
      ////////////////////////////////////////////////////////
      case 33:
        param_csdelay = value;
        break;
      case 34:
        param_cs2delay= value;
        break;
      case 35:
        param_cs2dur= value;
        break;
      case 36:
        param_cs2ch= value;
        break;
      case 37:
        param_motordelaypositive= value;
        break;
      case 38:
        param_motordelaynegative= value;
        break;
      case 39:
        param_motordur= value;
        break;
      case 40:
        param_motorenergizedtrial= value;
        break;
      case 41:
        //param_motorspeedtrial= int32_t(value)*2000000*param_microstep/60; //transforming rpm to motor steps
		    param_motorspeedtrial= mm_per_s_to_pulses_per_s(value); //transforming milimiter per second to motor steps
        break;
      case 42:
        //param_motoraccelerationtrial= int32_t(value)*10000;
		    param_motoraccelerationtrial= mm_per_s_s_to_pulses_per_s_s(value);
        break;
      case 43:
        param_PREVIOUSmotorenergizedintertrials = param_motorenergizedintertrials;
        param_motorenergizedintertrials= value;
        break;
      case 44:
        //param_motorspeedintertrials= int32_t(value)*2000000*param_microstep/60;
		    param_motorspeedintertrials= mm_per_s_to_pulses_per_s(value); //transforming milimiter per second to motor steps
        break;
      case 45:
        //param_motoraccelerationintertrials= int32_t(value)*10000;
	    	param_motoraccelerationintertrials= mm_per_s_s_to_pulses_per_s_s(value);
        break;
      case 46:
        param_motorcurrent= value;
        break;


    }
    // We might be able to remove this delay if Matlab sends the parameters fast enough to buffer
    delay(1); // Delay enough to allow next 3 bytes into buffer (24 bits/115200 bps = ~200 us, so delay 1 ms to be safe).
  }



}

// Update the instantiated StateMachines here with any new values that have been sent from Matlab
void configureTrial() {
//	  Wire.begin();
//    tic.setDecayMode(TicDecayMode::Fast);
//    tic.setStepMode(TicStepMode::Microstep16);
//    param_microstep = 16;
    tic.setCurrentLimit(param_motorcurrent);

    motor.setDelay(param_motordelaypositive);
    motor.setDuration(param_motordur);

    camera.setDuration(param_campretime + param_camposttime);
    camera.setDelay(param_motordelaynegative);
    //camera.refreshNumRepeats(); // added these lines to fix problem preventing trials > 5s from running. Notes are in kimoli's 2/17/2020 commit to the neuroblinks_S725 repository

    CS.setDelay(param_motordelaynegative + param_campretime + param_csdelay);
    CS.setDuration(param_csdur);
    CS.setFunctionArg(stim2pinMapping[param_csch]);
    CS.setPeriod(param_csperiod);
    CS.setNumRepeats(param_csrepeats);

    CS2.setDelay(param_motordelaynegative + param_campretime + param_cs2delay);
    CS2.setDuration(param_cs2dur);
    CS2.setFunctionArg(stim2pinMapping[param_cs2ch]);

    US.setDelay(param_motordelaynegative + param_campretime + param_ISI);
    US.setDuration(param_usdur);
    US.setFunctionArg(stim2pinMapping[param_usch]);
    //US.refreshNumRepeats(); // added these lines to fix problem preventing trials > 5s from running. Notes are in kimoli's 2/17/2020 commit to the neuroblinks_S725 repository

    /////////////////////FRANCISCO//////////////////
    US_eye_2.setDelay(param_motordelaynegative + param_campretime + param_ISI_eye_2);
    US_eye_2.setDuration(param_usdur_eye_2);
    US_eye_2.setFunctionArg(stim2pinMapping[param_usch_eye_2]);
    ////////////////////////////////////////////////

    laser.setDelay(param_motordelaynegative + param_campretime + param_laserdelay);
    laser.setDuration(param_laserdur);
    laser.setPeriod(param_laserperiod);
    laser.setNumRepeats(param_lasernumpulses);

    if (param_motordelaynegative > 0){
      if (param_motordur > param_motordelaynegative + param_campretime + param_camposttime){
        param_encodernumreadings = (param_motordur) / param_encoderperiod; // number of readings to take during trial
      }else{
        param_encodernumreadings = (param_motordelaynegative + param_campretime + param_camposttime) / param_encoderperiod; // number of readings to take during trial
      }
    }else{
      if (param_campretime + param_camposttime > param_motordelaypositive + param_motordur){
        param_encodernumreadings = (param_campretime + param_camposttime) / param_encoderperiod; // number of readings to take during trial
      }else{
        param_encodernumreadings = (param_motordelaypositive + param_motordur) / param_encoderperiod; // number of readings to take during trial
      }
    }

    if (param_encodernumreadings > MAX_DIFFERENTIAL_SENSOR_READINGS){
      param_encodernumreadings = MAX_DIFFERENTIAL_SENSOR_READINGS;
    }
    diff_enc.setNumRepeats(param_encodernumreadings);

   // Do some error checking for required bounds //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
   // CS intensity can be at most 255 (=2^8-1) because PWM with analogWrite uses 8 bit value //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
   // CS intensity for tone can have at most a value of 127 because the digital potentiometer is 7 bits //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
   // but we don't have to worry about it because most significant bit will be truncated so 255 will look like 127 //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
   if (param_csintensity < 0) { param_csintensity = 0;} //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
   if (param_csintensity > 255) { param_csintensity = 255;} //Alvaro 05/09/19 sheiney committed on Jan 18, 2017

   if (param_tonecsintensity < 0) { param_tonecsintensity = 0;} // Olivia splitting tone intensity variable out for ease of use 6/4/2020
   if (param_tonecsintensity > 128) { param_tonecsintensity = 128;} // Olivia splitting tone intensity variable out for ease of use 6/4/2020

   if (param_csch == ch_tone || param_cs2ch == ch_tone || param_usch == ch_tone || param_usch_eye_2 == ch_tone){
     tone_amplitude.writeWiper(0);
     tone_generator.SetFrequency(REG0, param_tonefreq);
   }

}

// Called by main loop when Arduino receives trigger from Matlab
void startTrial() {
    configureTrial();

    RUNNING = true;

    if (param_motordur > 0) {
      motor.start();
    }
    else{
      motor.stop();
      motor.off();
    }

    // Once StateMachines have been started the delay clock is ticking so don't put anything else below the call to start()
    // We want to return to the main loop ASAP after StateMachines have started
    // Each start() method only contains one function call to get current time and two assignment operations so should return quickly
    // The duration of the trial is determined by the camera parameters (delay, duration) -- all timing is relative to it
    camera.start();

    diff_enc.start();

    // duration of zero means it's not supposed to run on this trial so don't bother to start it
    if (param_csdur > 0) { CS.start(); }
    if (param_cs2dur > 0) { CS2.start(); }
    if (param_usdur > 0) { US.start(); }
    if (param_usdur_eye_2 > 0) { US_eye_2.start(); }
    if (param_laserdur > 0) { laser.start(); }



}

// Called by main loop when camera stops
void endOfTrial() {
    RUNNING = false;

    // These should already be stopped if we timed things well but we'll do it again just to be safe
    CS.stop();
    CS2.stop();
    US.stop();
    US_eye_2.stop();
    laser.stop();
    diff_enc.stop();
    motor.stop();
    camera.stop(); // Should already be stopped if this function was called


    //Disable the tone generation.
    if (param_csch == ch_tone || param_cs2ch == ch_tone || param_usch == ch_tone || param_usch_eye_2 == ch_tone){
      tone_amplitude.writeWiper(0);
      tone_generator.EnableOutput(false);
    }
}

// Called by main loop when matlab abort a trial
void abortTrial() {

    //RUNNING = false;

    // We stop everything but the camera
    CS.stop();
    CS2.stop();
    US.stop();
    US_eye_2.stop();
    laser.stop();
    diff_enc.stop();
    motor.stop();

    //CS.off();
    //CS2.off();
    //US.off();
    //US_eye_2.off();
    //laser.off();
    //diff_enc.off();
    //motor.off();


    //Disable the tone generation.
    if (param_csch == ch_tone || param_cs2ch == ch_tone || param_usch == ch_tone || param_usch_eye_2 == ch_tone){
      tone_amplitude.writeWiper(0);
      tone_generator.EnableOutput(false);
    }
}


// Make sure this code executes fast (< 1 ms) so it doesn't screw up the timing for everything else
void DACWrite(int DACvalue) {

    Wire.beginTransmission(MCP4725_ADDR);
    Wire.write(64);                     // cmd to update the DAC
    Wire.write(DACvalue >> 4);        // the 8 most significant bits...
    Wire.write((DACvalue & 15) << 4); // the 4 least significant bits...
    Wire.endTransmission();

}

int powerToDACUnits(int power) {

    int DACUnits = power * param_lasergain + param_laseroffset;

    if (DACUnits < MAXDACUNIT) {return DACUnits;}
    else {return MAXDACUNIT;}

}


// Tone is a special case of digitalWrite because it uses a timer to cycle at requested frequency
// We also have a special case if CS is LED to use CS intensity to regulate brightness
void digitalOn(int pin) {
    // if (pin == pin_tone) { //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
    switch (pin) { //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
      case pin_tone: //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
        toneOn(pin);
//    }  //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
//    else {  //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
      break; //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
     case pin_led: //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
       analogWrite(pin, param_csintensity); //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
       break; //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
    case pin_brightled: //Alvaro 05/09/19
      analogWrite(pin, param_csintensity); //Alvaro 05/09/19
      break;
     default: //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
        digitalWrite(pin, HIGH);
    }
}

void digitalOff(int pin) {
    if (pin == pin_tone) {
        toneOff(pin);
    }
    else {
       // We can turn it off with digitalWrite even if we turned it on with analogWrite //Alvaro 05/09/19 sheiney committed on Jan 18, 2017
        digitalWrite(pin, LOW);
    }
}

void toneOn(int pin) {
  //This timer will generate the ramp up in the tone volume
  Timer7.start();
};

void toneOff(int pin) {
    //This timer will generate the ramp down in the tone volume
  Timer8.start();
};



void toneRampUp(){
  if (tone_counter_ramp_up < N_sin_table_elements){
    int value = param_tonecsintensity*sin_table[tone_counter_ramp_up];
    tone_amplitude.writeWiper(value);
    if (tone_counter_ramp_up == 0){
      tone_generator.EnableOutput(true);
    }
    tone_counter_ramp_up++;
  }else{
    Timer7.stop();
    tone_counter_ramp_up = 0;
  }
}

void toneRampDown(){
  if (tone_counter_ramp_down >= 0){
    int value = param_tonecsintensity*sin_table[tone_counter_ramp_down];
    tone_amplitude.writeWiper(value);
    tone_counter_ramp_down--;
  }else{
    Timer8.stop();
    tone_generator.EnableOutput(false);
    tone_counter_ramp_down = N_sin_table_elements - 1;
  }
}



void laserOn(int dummy) { // Function signature requires int but we don't need it so call it "dummy"
    double counter;
if (param_laserpower>=30 && param_laserpower<=4095)
  {
    DACWrite(powerToDACUnits(param_laserpower));
  }
///////////////////////FRANCISCO: DELETE THIS SECTION/////////////////////////
//else
//if (param_laserpower==4095)
//  {
//    DACWrite(powerToDACUnits(4095));
//  }
//else
//  if (param_laserpower==2047)
//  {
//    DACWrite(powerToDACUnits(2047));
//  }
//else
//  if (param_laserpower==3000)
//  {
//    DACWrite(powerToDACUnits(3000));
//  }
//  else
//    if (param_laserpower==3250)
//    {
//      DACWrite(powerToDACUnits(3250));
//    }
//    else
//      if (param_laserpower==3500)
//      {
//        DACWrite(powerToDACUnits(3500));
//      }
//      else
//        if (param_laserpower==3750)
//        {
//          DACWrite(powerToDACUnits(3750));
//        }
//        else
//          if (param_laserpower==4000)
//          {
//            DACWrite(powerToDACUnits(4000));
//          }
///////////////////////////////////////////////////////////////
else
    if (param_laserpower==1)
      {
       DACWrite(powerToDACUnits(2047));
      }
else
      if (param_laserpower==2)
      for (counter = 2047; counter < 4095; counter = counter+0.16)
      {
        DACWrite(powerToDACUnits(counter));
       }
else
      if (param_laserpower==3)
      {
         DACWrite(powerToDACUnits(4095));
       }
else
    if (param_laserpower==4)
        for (counter = 4095; counter > 2048; counter = counter-0.16)
        {
          DACWrite(powerToDACUnits(counter));
        }
else
    if (param_laserpower==5)
        for (counter = 2047; counter > 0; counter = counter-0.16)
        {
          DACWrite(powerToDACUnits(counter));
        }
else
    if (param_laserpower==6)
      {
        DACWrite(powerToDACUnits(0));
      }
  else
     if (param_laserpower==7)
        for (counter = 0; counter < 2046; counter = counter+0.16)
        {
          DACWrite(powerToDACUnits(counter));
        }
  else
      if (param_laserpower==8)
        {
         DACWrite(powerToDACUnits(410));
        }
  else
        if (param_laserpower==9)
        for (counter = 410; counter < 819; counter = counter+0.031)
        {
          DACWrite(powerToDACUnits(counter));
         }
  else
        if (param_laserpower==10)
        {
           DACWrite(powerToDACUnits(819));
         }
  else
      if (param_laserpower==11)
          for (counter = 819; counter > 411; counter = counter-0.031)
          {
            DACWrite(powerToDACUnits(counter));
          }
  else
      if (param_laserpower==12)
          for (counter = 410; counter > 0; counter = counter-0.031)
          {
            DACWrite(powerToDACUnits(counter));
          }
  else
      if (param_laserpower==13)
        {
          DACWrite(powerToDACUnits(0));
        }
  else
      if (param_laserpower==14)
          for (counter = 0; counter < 409; counter = counter+0.031)
          {
            DACWrite(powerToDACUnits(counter));
        }
  else
            if (param_laserpower==15)
              {
               DACWrite(powerToDACUnits(1024));
              }
        else
              if (param_laserpower==16)
              for (counter = 1024; counter < 2047; counter = counter+0.08)
              {
                DACWrite(powerToDACUnits(counter));
               }
        else
              if (param_laserpower==17)
              {
                 DACWrite(powerToDACUnits(2047));
               }
        else
            if (param_laserpower==18)
                for (counter = 2047; counter > 1025; counter = counter-0.08)
                {
                  DACWrite(powerToDACUnits(counter));
                }
        else
            if (param_laserpower==19)
                for (counter = 1024; counter > 0; counter = counter-0.08)
                {
                  DACWrite(powerToDACUnits(counter));
                }
        else
            if (param_laserpower==20)
              {
                DACWrite(powerToDACUnits(0));
              }
          else
             if (param_laserpower==21)
                for (counter = 0; counter < 1024; counter = counter+0.08)
                {
                  DACWrite(powerToDACUnits(counter));
                }
        else
              if (param_laserpower==22)
              {
                DACWrite(powerToDACUnits(614));
              }
        else
              if (param_laserpower==23)
              for (counter = 614; counter < 1229; counter = counter+0.048)
              {
                DACWrite(powerToDACUnits(counter));
               }
        else
              if (param_laserpower==24)
              {
                 DACWrite(powerToDACUnits(1229));
               }
        else
            if (param_laserpower==25)
                for (counter = 1229; counter > 615; counter = counter-0.048)
                {
                  DACWrite(powerToDACUnits(counter));
                }
        else
            if (param_laserpower==26)
                for (counter = 614; counter > 0; counter = counter-0.048)
                {
                  DACWrite(powerToDACUnits(counter));
                }
        else
            if (param_laserpower==27)
              {
                DACWrite(powerToDACUnits(0));
              }
          else
             if (param_laserpower==28)
                for (counter = 0; counter < 614; counter = counter+0.048)
                {
                  DACWrite(powerToDACUnits(counter));
                }};


void laserOff(int dummy) { // Function signature requires int but we don't need it so call it "dummy"
  double counter;
double  timeramp = (1/(param_rampoffdur*0.000625));
double  rampoff = param_rampoffdur;
if (rampoff==0)
  DACWrite(0);
  else
    if (rampoff>0)
    for (counter = param_laserpower; counter > 0; counter = counter-timeramp)
      {
        DACWrite(powerToDACUnits(counter));
      }};

void motorTrialStart(int dummy) { // Function signature requires int but we don't need it so call it "dummy"
  //resetMotorTimeout();
  if (param_motorenergizedtrial == 1){
    if (param_PREVIOUSmotorenergizedintertrials == 0){
      int32_t EncoderVelocityInMotorPulses = getEncoderVelocityInMotorPulses();
      tic.setStartingSpeed(uint32_t(abs(EncoderVelocityInMotorPulses)));
      tic.setTargetVelocity(EncoderVelocityInMotorPulses);
      tic.energize();
      tic.exitSafeStart();
      tic.clearDriverError();
      delay(1);
      tic.setStartingSpeed(uint32_t(0));
    }
    //tic.setMaxSpeed(param_motorspeedtrial);
    tic.setMaxAccel(param_motoraccelerationtrial);
    tic.setMaxDecel(param_motoraccelerationtrial);
    tic.setTargetVelocity(param_motorspeedtrial);

    tic.energize();
    tic.exitSafeStart();
    tic.clearDriverError();


  }else{
    tic.deenergize();
  }
}

void motorTrialEnd(int dummy) { // Function signature requires int but we don't need it so call it "dummy"
  //resetMotorTimeout();
  if (param_motorenergizedintertrials == 1){
    if ((param_motorenergizedtrial == 0 && param_motordur > 0) || (param_PREVIOUSmotorenergizedintertrials == 0 && param_motordur == 0)){
      int32_t EncoderVelocityInMotorPulses = getEncoderVelocityInMotorPulses();
      tic.setStartingSpeed(uint32_t(abs(EncoderVelocityInMotorPulses)));
      tic.setTargetVelocity(EncoderVelocityInMotorPulses);
      tic.energize();
      tic.exitSafeStart();
      tic.clearDriverError();
      delay(1);
      tic.setStartingSpeed(uint32_t(0));
    }
    tic.setMaxAccel(param_motoraccelerationintertrials);
    tic.setMaxDecel(param_motoraccelerationintertrials);
    tic.setTargetVelocity(param_motorspeedintertrials);
    tic.energize();
    tic.exitSafeStart();
    tic.clearDriverError();


  }else{
    tic.deenergize();
  }
}

int32_t mm_per_s_to_pulses_per_s(int mm_per_s){
  N_pulses_per_revolution = 2000000*param_microstep;
  int32_t N_pulses_per_s = mm_per_s*N_pulses_per_revolution/perimeter;
  return N_pulses_per_s;
}

int32_t mm_per_s_s_to_pulses_per_s_s(int mm_per_s_s){
  int32_t N_pulses_per_s_s = 20000*param_microstep*mm_per_s_s/perimeter;
  return N_pulses_per_s_s;
}

// Sends a "Reset command timeout" command to the Tic each 800ms.
// We must call this at least once per second, or else a command timeout
// error will happen. The Tic's default command timeout period
// is 1000 ms, but it can be changed or disabled in the Tic
// Control Center.
void resetMotorTimeout()
{
  if (millis() - time_since_last_motor_reset > 800){
    time_since_last_motor_reset = millis();
    tic.resetCommandTimeout();
    //The execution of this reset command timeout should take less than 1ms. Nevertheless,
    //if the I2C port fail, this command will block the arduino execution for arround 40ms.
    //In that case, we need to reset the I2C port.
    if(millis() - time_since_last_motor_reset > 5){
      reset_I2C_port();
    }
  }
}


// We call by reference so we can update the local variables in "reading_function" of StateMachine object
void takeEncoderReading(timems_t &time, int32_t &reading) {

    time = millis();
    reading = cylEnc.read();
    // reading = 5000-random(10000);  // for testing

}

void sendEncoderData() {

    // Consider using Serial.availableForWrite() if the code below is blocking

    Serial.write(ENCODER_L);
    writeInt(param_encodernumreadings); //Send the number of values that the encoder recorded.
    writeLong(diff_enc.getFirstReading()); //Send first sample
    for (int i=0; i<param_encodernumreadings; i++) {
        writeInt8(diff_enc.getReading(i));
        //This function resets the motor timeout in the chip that control the motor. This timeout must be reset
        //at least one time each 1000 ms.
        resetMotorTimeout();
    }

    Serial.write(TIME_L);
    writeInt(param_encodernumreadings); //Send the number of values that the encoder recorded.
    writeLong(diff_enc.getFirstTime()); //Send first sample
    for (int i=0; i<param_encodernumreadings; i++) {
        writeInt8(diff_enc.getTime(i));
        //This function resets the motor timeout in the chip that control the motor. This timeout must be reset
        //at least one time each 1000 ms.
        resetMotorTimeout();
    }
}

// We have to send bytes over the serial port, so break the 32-bit integer into 4 bytes by ANDing only the byte we want
// and shifting that byte into the first 8 bits
// Unsigned longs
void writeLong(uint32_t long_value) {
    for (int i=0; i<4; i++) {
        // Can we do this instead: (byte)(long_value >> 24) [replacing 24 with appropriate shift]?
        // Cast to byte will truncate to first 8 bits as side effect
        byte val = ( long_value & bit_patterns_long[i] ) >> 8*i;
        Serial.write(val);
    }
}

// Overloaded for signed longs
void writeLong(int32_t long_value) {
    for (int i=0; i<4; i++) {
        byte val = ( long_value & bit_patterns_long[i] ) >> 8*i;
        Serial.write(val);
    }
}

// Overloaded for signed longs
void writeInt(int16_t int_value) {
    for (int i=0; i<2; i++) {
        byte val = ( int_value & bit_patterns_int[i] ) >> 8*i;
        Serial.write(val);
    }
}

// Overloaded for signed longs
void writeInt8(int8_t int8_value) {
    Serial.write(int8_value);
}

void flushReceiveBuffer() {
    while(Serial.available()) {
        Serial.read();
    }
}

int32_t getEncoderVelocityInMotorPulses(){
  float encoderPulses = diff_enc.getPulsesPerSecond();
  int32_t N_encoderPulsesPerRevolution = 4096;

  int32_t LocalEncoderVelocityInMotorPulses = N_pulses_per_revolution * encoderPulses / N_encoderPulsesPerRevolution;
  return LocalEncoderVelocityInMotorPulses;
}
