#include <Wire.h> // For I2C communication
#include <SPI.h>  // For controlling external chips
#include <Arduino.h>
#include <stateMachine.hpp>

//This is the I2C Address of the MCP4725, by default (A0 pulled to GND).
//Please note that this breakout is for the MCP4725A0.
//Please note that this breakout is for the MCP4725A0.
#define MCP4725_ADDR 0x60   // DAC
#define MAXDACUNIT 4095       // 2^12-1 (ie 12 bits)
#define MINDACUNIT 0

void reset_I2C_port();

void DACWrite( int );

int powerToDACUnits( int );

void checkVars( void );

void configureTrial( void );

void startTrial( void );

void endOfTrial( void );

void abortTrial( void );

void digitalOn(int);

void digitalOff(int);

void toneOn(int);

void toneOff(int);

void toneRampUp(void);

void toneRampDown(void);

void laserOn(int);

void laserOff(int);

void laserrampoff(int);

void motorTrialStart(int);

void motorTrialEnd(int);

int32_t mm_per_s_to_pulses_per_s(int);

int32_t mm_per_s_s_to_pulses_per_s_s(int);

void rampoffdur(int);

void resetMotorTimeout(void);

void takeEncoderReading(timems_t &, int32_t &);

void sendEncoderData( void );

void writeLong(uint32_t);

void writeLong(int32_t);

void writeInt(int16_t);

void writeInt8(int8_t);

void flushReceiveBuffer();

int32_t getEncoderVelocityInMotorPulses();
