#include <util/crc16.h>
#include <OneWire.h>
#include <avr/sleep.h>
#include <avr/wdt.h>



// DS18S20 Temperature chip i/o
// can be either parasite powered or conventionally powered
OneWire ds(10);  // on pin 10

//  how do we identify ourselves to the logging application?
#define source "back porch"

//  connected to pin 9 on XBee, with a pullup resistor (100K seems good)
//  This is used to take the Xbee in and out of sleep mode
#define XBEE_PIN 11



#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

#ifndef HAVE_XBEE_SLEEP
//#define HAVE_XBEE_SLEEP
#endif

//  for our sleep
int nint;   // number of interrupts received
volatile boolean f_wdt=1;

// storage for the temperature we get from the sensor
int sign_bit;     // what's your sign?
int reading[2];  // [0] is whole, [1] is fraction


// crc for our logging message
char crchex[5];


// helpers for finding the temperature sensor and reading it
int ds_found = 0;
byte addr[8];


void setup(void) {
  // initialize inputs/outputs
  // start serial port
  xbee_wake();
  Serial.begin(9600);

#ifdef HAVE_XBEE_SLEEP  

  Serial.print("+++");

  char thisByte = 0;
  while (thisByte != '\r') {
    if (Serial.available() > 0) {
      thisByte = Serial.read();
    }
  }
  Serial.print("ATSM1\r");
  Serial.print("ATCN\r");

  delay(10);
#endif

  Serial.print(source);
  Serial.println(" booting");
  delay(100);

  // CPU Sleep Modes 
  // SM2 SM1 SM0 Sleep Mode
  // 0    0  0 Idle
  // 0    0  1 ADC Noise Reduction
  // 0    1  0 Power-down
  // 0    1  1 Power-save
  // 1    0  0 Reserved
  // 1    0  1 Reserved
  // 1    1  0 Standby(1)

  cbi( SMCR,SE );      // sleep enable, power down mode
  cbi( SMCR,SM0 );     // power down mode
  sbi( SMCR,SM1 );     // power down mode
  cbi( SMCR,SM2 );     // power down mode

  setup_watchdog(9);
  xbee_sleep();
}

void loop(void) {
  int *reading;

  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
    f_wdt=0;       // reset flag

    nint++;
    if (nint >= 6) {  // 6 for ~ 1 minute
      nint = 0;

      xbee_wake();
      Serial.begin(9600);
      if(read_data()){
	transmit_data();
      } else {
	Serial.print(source);
	Serial.print(" - error reading sensor");

	if(read_data()){  // retry.  If we're lucky it was a transient error
	  transmit_data();
	}
      }

      delay(5);               // wait until the last serial character is sent
      xbee_sleep();
    }

    system_sleep();
  }
}

void xbee_wake(){
  pinMode(XBEE_PIN, OUTPUT);
  digitalWrite(XBEE_PIN, HIGH);
  delay(5);
  digitalWrite(XBEE_PIN, LOW);
  delay(15);
}

void xbee_sleep(){
  digitalWrite(XBEE_PIN, HIGH);
  pinMode(XBEE_PIN, INPUT);
}


int read_data(){

  int HighByte, LowByte, TReading, Tc_100, Tf_100;

  if ( ds.search(addr) ){
    ds_found = 1;
  }

  byte i;
  byte present = 0;
  byte data[12];
//  if ( !ds.search(addr)) {
//      Serial.print("No more addresses.\n");
//      ds.reset_search();
//      return;
//  }
  if ( ds_found != 1 ){
    Serial.print("no oneWire devices found");
    delay(1000);
    return 0;
  }

  if ( addr[0] != 0x10 && addr[0] != 0x28) {
     Serial.print("Device is not a DS18S20 family device.\n");
     return 0;
  }

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion

  delay(1000);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.

  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
  }

  if( ! OneWire::crc8( data, 8) == data[9]){
    return 0;
  }
  
  LowByte = data[0];
  HighByte = data[1];
  TReading = (HighByte << 8) + LowByte;
  sign_bit = TReading & 0x8000;  // test most sig bit
  if (sign_bit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }
  Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25
  Tf_100 = (Tc_100 * 9 / 5)   + 3200;

  reading[0] = Tf_100 / 100;  // separate off the whole and fractional portions
  reading[1] = Tf_100 % 100;

  return 1;
}

void transmit_data() {
  char buff[10];

  if (sign_bit) // If its negative
  {
     sprintf(buff, "-%d.%02d", reading[0], reading[1]);
  } else {
     sprintf(buff, "%d.%02d", reading[0], reading[1]);
  }

  send_temperature("T", source, buff);
}



// send temperature to server, looking for a receipt message.
//  try 3 times, then give up
void send_temperature(char *type, char *source_name, char *data) {
  int crc = calculate_crc(type, source_name, data);
  sprintf(crchex, "%04X", crc);

  int try_count = 1;
  send_msg(type, source_name, data, crchex);

  while( (3 > try_count) &&  (! check_for_receipt(crchex))) {

    send_msg(type, source_name, data, crchex);
    try_count++;
  }
}

void send_msg(char *type, char *source_name, char *data, char *crchex) {
  Serial.print(type);
  Serial.print(":");
  Serial.print(source_name);
  Serial.print(":");
  Serial.print(data);
  Serial.print(":");

  Serial.println(crchex);
}

int check_for_receipt(char * crcstring) {
  char receipt[50];
  int charno = 0;
  delay(100);  // give ourselves a little delay
  while(Serial.available() > 0 && charno < 49){
    charno++;
    receipt[charno - 1] = Serial.read();

    if(receipt[charno - 1] == '\n'){  // end of line
      receipt[charno - 1] = '\0';  // eat that EOL
      break;
    }

    delay(1);  // give time for more characters to come in
  }

  receipt[charno] = '\0';  // make sure we've got a string terminator
  //  if(charno > 0){
  //  Serial.println(receipt);
  //}

  if(charno >= 6) {
    if(receipt[0] == 'R') {  // it's a receipt message
      receipt[6] = '\0';

      if(0 == strcmp(&receipt[2], crcstring)) {
	return 1;
      }
    }
  }

  return 0;
}


int calculate_crc(char * type, char * source_name, char * message) {
  uint16_t crc = 0;

  crc = crc_string(crc, type);
  crc = crc_string(crc, ":");
  crc = crc_string(crc, source_name);
  crc = crc_string(crc, ":");
  crc = crc_string(crc, message);
  crc = crc_string(crc, ":");

  return crc;
}

uint16_t  crc_string(uint16_t crc, char * crc_message) {
  int i;  
  for (i = 0; i < strlen(crc_message) / sizeof crc_message[0]; i++) {
    crc = _crc16_update(crc, crc_message[i]);
  }
  return crc; // must be 0
}



//****************************************************************  
// set system into the sleep state 
// system wakes up when wtchdog is timed out
void system_sleep() {

  cbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter OFF

  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
  sleep_enable();

  sleep_mode();                        // System sleeps here

  sleep_disable();                     // System continues execution here when watchdog timed out 
  sbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter ON

}

//****************************************************************
// 0=16ms, 1=32ms,2=64ms,3=128ms,4=250ms,5=500ms
// 6=1 sec,7=2 sec, 8=4 sec, 9= 8sec
void setup_watchdog(int ii) {

  byte bb;
  int ww;
  if (ii > 9 ) ii=9;
  bb=ii & 7;
  if (ii > 7) bb|= (1<<5);
  bb|= (1<<WDCE);
  ww=bb;
  //  Serial.println(ww);


  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCSR = bb;
  WDTCSR |= _BV(WDIE);


}
//****************************************************************  
// Watchdog Interrupt Service / is executed when  watchdog timed out
ISR(WDT_vect) {
  f_wdt=1;  // set global flag
}
