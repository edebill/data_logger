#include <util/crc16.h>
#include <avr/sleep.h>
#include <avr/wdt.h>

// http://code.google.com/p/max6675-arduino-library/
#include <MAX6675.h>

int CS = 10;              // CS pin on MAX6675
int SO = 12;              // SO pin of MAX6675
int SCK = 13;             // SCK pin of MAX6675
int units = 0;            // Units to readout temp (0 = ˚F, 1 = ˚C)
float max6675_error = 0.0;        // Temperature compensation error
float temperature = 0.0;  // Temperature output variable


// Initialize the MAX6675 Library

MAX6675 temp0(CS, SO, SCK, units, max6675_error);


//  how do we identify ourselves to the logging application?
#define source "smoker"

//  connected to pin 9 on XBee, with a pullup resistor (100K seems good)
//  This is used to take the Xbee in and out of sleep mode
#define XBEE_PIN 8



#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

#ifndef HAVE_XBEE
#define HAVE_XBEE
#endif


#ifndef HAVE_XBEE_SLEEP
//#define HAVE_XBEE_SLEEP
#endif

//  for our sleep
int nint;   // number of interrupts received
volatile boolean f_wdt=1;



// for timout, waiting for response
uint16_t wait_start;
uint16_t wait_end;

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

  error("booting");

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
  float reading;
  
  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
    f_wdt=0;       // reset flag

    nint++;
    if (nint >= 6) {  // 6 for ~ 1 minute
      nint = 0;
      xbee_wake();
      Serial.begin(9600);
      reading = read_data();

      // if reading is outside range (probably DEVICE_DISCONNECTED) don't log it
      if(reading > -67) {
	transmit_data(reading);
      }

      delay(5);               // wait until the last serial character is sent
      xbee_sleep();
    }

    system_sleep();
  }
}

void xbee_wake(){
#ifdef HAVE_XBEE
  pinMode(XBEE_PIN, OUTPUT);
  digitalWrite(XBEE_PIN, HIGH);
  delay(5);
  digitalWrite(XBEE_PIN, LOW);
  delay(15);
#endif
}

void xbee_sleep(){
#ifdef HAVE_XBEE
  digitalWrite(XBEE_PIN, HIGH);
  pinMode(XBEE_PIN, INPUT);
#endif
}


// individual readings are bad 20% or more of the time
// give ourself NUM_TRIES to get NUM_READINGS good ones, then
// return the median of the good ones.  If we can't get
// 3 good ones in NUM_TRIES, return DEVICE_DISCONNECTED (the
// error return code that comes back from DallasTemperature)
// DEVICE_DISCONNECTED == -1766.19 F, well outside the
// valid reading range for this device.
float read_data(){
#define NUM_TRIES 20
#define NUM_READINGS 3

  return temp0.read_temp(NUM_READINGS);
}


void transmit_data(float temperature) {
  char buff[10];

  format_float(temperature, buff);

  send_temperature("T", source, buff);
}

void format_float(float temperature, char *buff) {
  // sprintf on arduino doesn't support floats
  char sign[2];
  
  if(temperature < 0) {
    strcpy(sign,"-");
  } else {
    sign[0] = '\0';
  }

  int decimal = (temperature - (int)temperature) * 100;

  sprintf(buff, "%s%d.%02d", sign, (int)abs(temperature), abs(decimal));
}


// send temperature to server, looking for a receipt message.
//  try 3 times, then give up
void send_temperature(char *type, char *source_name, char *data) {
  int crc = calculate_crc(type, source_name, data);
  sprintf(crchex, "%04X", crc);

  empty_input_buffer();
  int try_count = 1;
  send_msg(type, source_name, data, crchex);

  while( (3 > try_count) &&  (! check_for_receipt(crchex))) {

    delay(1000);
    delay(random(1000));

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

  begin_timeout(2000);
  while( !timeout() && Serial.available() == 0){

  }

  begin_timeout(500);  // if they've already started, .5 sec should be generous
  receipt[charno] = '\0';

  while(Serial.available() > 0 && charno < 49
	&& receipt[charno] != '\r'
	&& receipt[charno] != '\n'
	&& !timeout()){

    charno++;
    receipt[charno - 1] = Serial.read();

    if(receipt[charno - 1] == '\n'){  // end of line
      receipt[charno - 1] = '\0';  // eat that EOL
      break;
    }

    delay(10);  // give time for more characters to come in
  }
  receipt[charno] = '\0';  // make sure we've got a string terminator

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

void  empty_input_buffer() {
  byte garbage;
  while(Serial.available() > 0){
    garbage = Serial.read();
  }
  
  return;
}

void begin_timeout(uint16_t timeout_period) {
  wait_start = millis();
  wait_end = wait_start + timeout_period;
  
  return;
}

int timeout() {
  uint16_t now;
  now = millis();
  if(wait_start < wait_end){  // normal case
    if( now > wait_end ){
      return 1;
    }
  } else {   // millis() will wrap
    if( now < wait_start && now > wait_end ){
      return 1;
    }
  }

  return 0;
}

void error(char *msg) {
  Serial.print(source);
  Serial.print(" - ");
  Serial.println(msg);
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
