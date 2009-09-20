#include <Wire.h>
#include <PCF8583.h>

#define SWITCH_PIN 6
#define PCF8583_ADDRESS 0xA0
#define EEPROM_ADDRESS 0xA4 >> 1
PCF8583 rtc(PCF8583_ADDRESS);
int last_pin_state = 0;
long int start_time;
long int stop_time;
unsigned int next_address = 0;


void setup() {
  Serial.begin(9600);
  Serial.print("booting...");
  Wire.begin();
  pinMode(SWITCH_PIN, INPUT);
  Serial.println("done.");
  Serial.print("what time is it?");
  int time_set = 0;
  while(time_set == 0){
    if(Serial.available()){
      
      rtc.year= (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48)) + 2000;
      rtc.month = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
      rtc.day = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
      rtc.hour  = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
      rtc.minute = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
      rtc.second = (byte) ((Serial.read() - 48) * 10 + (Serial.read() - 48)); // Use of (byte) type casting and ascii math to achieve result.  

      Serial.println("setting date");
      rtc.set_time();
      time_set = 1;
    }
  }

  Serial.println("checking memory for previous entries:");
  /*
  i2c_eeprom_read_buffer(EEPROM_ADDRESS, next_address,(byte *) &start_time, 4);
  i2c_eeprom_read_buffer(EEPROM_ADDRESS, next_address + 4,(byte *) &stop_time, 4);
  Serial.print("start time = ");
  Serial.println(start_time);

  while(start_time != 0) {
    Serial.print("period of ");
    Serial.print(stop_time - start_time);
    Serial.println(" secs");
    next_address += 8;
    i2c_eeprom_read_buffer(EEPROM_ADDRESS, next_address,(byte *) &start_time, 4);
    i2c_eeprom_read_buffer(EEPROM_ADDRESS, next_address + 4,(byte *) &stop_time, 4);
  }
  */
  byte foo;
  foo = i2c_eeprom_read_byte(EEPROM_ADDRESS, next_address);
  while(foo != 0){
    Serial.print("address ");
    Serial.print(next_address);
    Serial.print(" = ");
    Serial.println((int) foo);
    next_address++;
    foo = i2c_eeprom_read_byte(EEPROM_ADDRESS, next_address);

  }

  Serial.println("done");
  
}

void loop() {
  int val = digitalRead(SWITCH_PIN);
  if(last_pin_state == LOW){  // was unpressed
    if(val == HIGH){   // low to high transition
      rtc.get_time();
      start_time = mktime(rtc.second, rtc.minute, rtc.hour, rtc.day, rtc.month,
			  rtc.year);
      last_pin_state = HIGH;
      Serial.println("button pressed");
    }
  } else {
    if(val == LOW){ // HIGH to LOW transition
      last_pin_state = LOW;
      rtc.get_time();
      stop_time = mktime(rtc.second, rtc.minute, rtc.hour, rtc.day, rtc.month,
			rtc.year);
      Serial.println("button released");
      Serial.print("button held for ");
      Serial.print(stop_time - start_time);
      Serial.println(" seconds");
      i2c_eeprom_write_page(EEPROM_ADDRESS, next_address, (byte *) &start_time, 4);
      i2c_eeprom_write_page(EEPROM_ADDRESS, next_address + 4, (byte *) &stop_time, 4);
      next_address += 8;
    }
  }
}


void i2c_eeprom_write_byte( int deviceaddress, unsigned int eeaddress, byte data ) {
  int rdata = data;
  Wire.beginTransmission(deviceaddress);
  Wire.send((int)(eeaddress >> 8)); // MSB
  Wire.send((int)(eeaddress & 0xFF)); // LSB
  Wire.send(rdata);
  Wire.endTransmission();
}

// WARNING: address is a page address, 6-bit end will wrap around
// also, data can be maximum of about 30 bytes, because the Wire library has a buffer of 32 bytes
void i2c_eeprom_write_page( int deviceaddress, unsigned int eeaddresspage, byte* data, byte length ) {
  Wire.beginTransmission(deviceaddress);
  Wire.send((int)(eeaddresspage >> 8)); // MSB
  Wire.send((int)(eeaddresspage & 0xFF)); // LSB
  byte c;
  for ( c = 0; c < length; c++)
    Wire.send(data[c]);
  Wire.endTransmission();
}

byte i2c_eeprom_read_byte( int deviceaddress, unsigned int eeaddress ) {
  byte rdata = 0xFF;
  Wire.beginTransmission(deviceaddress);
  Wire.send((int)(eeaddress >> 8)); // MSB
  Wire.send((int)(eeaddress & 0xFF)); // LSB
  Wire.endTransmission();
  Wire.requestFrom(deviceaddress,1);
  if (Wire.available()) rdata = Wire.receive();
  return rdata;
}

// maybe let's not read more than 30 or 32 bytes at a time!
void i2c_eeprom_read_buffer( int deviceaddress, unsigned int eeaddress, byte *buffer, int length ) {
  Wire.beginTransmission(deviceaddress);
  Wire.send((int)(eeaddress >> 8)); // MSB
  Wire.send((int)(eeaddress & 0xFF)); // LSB
  Wire.endTransmission();
  Wire.requestFrom(deviceaddress,length);
  int c = 0;
  for ( c = 0; c < length; c++ )
    if (Wire.available()) buffer[c] = Wire.receive();
}


/***********************************************************************/
#define EPOCH_YEAR 1970
#define TM_YEAR_BASE 1900
#define SECONDS_PER_MINUTE 60
#define SECONDS_PER_HOUR 60 * SECONDS_PER_MINUTE
#define SECONDS_PER_DAY 24 * SECONDS_PER_HOUR
#define SECONDS_PER_YEAR 365 * SECONDS_PER_DAY



/* Return 1 if YEAR + TM_YEAR_BASE is a leap year.  */
static inline int
leapyear (long int year)
{
  /* Don't add YEAR to TM_YEAR_BASE, as that might overflow.
     Also, work even if YEAR is negative.  */
  return
    ((year & 3) == 0
     && (year % 100 != 0
	 || ((year / 100) & 3) == (- (TM_YEAR_BASE / 100) & 3)));
}


const unsigned short int __mon_yday[2][13] =
  {
    /* Normal years.  */
    { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365 },
    /* Leap years.  */
    { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366 }
  };


long mktime(int sec, int min, int hour, int day, int mon, int year) {
  int mon_yday = __mon_yday[leapyear (long(year))] [mon - 1];
  int yday = mon_yday + day;

  int leap_days = 0;
  int step_year = 1970;
  while(step_year < year) {
      if(leapyear(step_year)) {
          leap_days++;
      }
      step_year++;
  }
  
  long time = long((long(year) - EPOCH_YEAR) * SECONDS_PER_YEAR) + 
            long(yday - 1 + leap_days) * SECONDS_PER_DAY +  // -1 because today isn't over
            long(hour) * SECONDS_PER_HOUR + min * SECONDS_PER_MINUTE + sec;

  return time;
}

