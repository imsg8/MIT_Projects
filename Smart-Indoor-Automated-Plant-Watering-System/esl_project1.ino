#include <math.h>
#include <Adafruit_LiquidCrystal.h>

Adafruit_LiquidCrystal lcd(0);  // Inititalizing LCD

// defining constant
int temp = 0;
int humidity = 0;
int celcius = 0;
int farenheit = 0;
int voltage = 0;
int mtrSpeed = 0;
// defining weights for logistic regression
double w1 = -0.02999513;
double w2 = 0.05541188;
double w3 = 0.00439418;
double b = 0.09956028;

void setup()
{	
  pinMode(11, OUTPUT);	// motor output
  pinMode(7, OUTPUT);	// led output
  pinMode(A0, INPUT);	// temperature input
  Serial.begin(9600);	
  pinMode(A1, INPUT);	// humidity input
  lcd.begin(16, 2);		// setting LCD cursor
  lcd.print("Watering motor:");	//printing first line of text
}

// logistic regression
double predict(int c, int h, int m){
  double z = (w1*m)+(w2*c)+(w3*h)+b;
  double p = 1/(1+exp(-1*z));
  return p;	
}

void loop()
{
  celcius = (-40 + 0.488155 * (analogRead(A0) - 20));	// converting input to celcius
  humidity = map(analogRead(A1), 0, 1023, 10, 70);		// reading humidity and setting it in permissible range
  Serial.print("Temperatue(celcius): ");
  Serial.println(celcius);
  Serial.print("Humidity: ");
  Serial.println(humidity);
  int k = analogRead(A2); 
  float moistureValue = ((float)(1023-0)/(float)(142-0))*float(k-0);	// moisture sensor input
  int min_range=1;
  int max_range=90;
  int min_val=0;
  int max_val=6310.90;
  float mv=((moistureValue - min_val) / (max_val - min_val)) * (max_range - min_range)+(min_range); // processing moisture input into range
  mv = (int)mv;
  Serial.print("Moisture Value: ");
  Serial.println(mv);
  double prediction = predict(celcius, humidity, mv); // output of logistic regression
  lcd.setCursor(0,1);
  Serial.println(prediction);
  // lcd.println(prediction);
  if (prediction > 0.75) {
    digitalWrite(7, HIGH); // Turn on LED
    mtrSpeed = 10;		   // motor on
    lcd.println("ON");
  } else {
    digitalWrite(7, LOW); // Turn off LED
    mtrSpeed = 0;         // motor off
    lcd.println("OFF");
  }
  mtrSpeed = map(mtrSpeed, 1, 1024, 0, 255);
  analogWrite(11, mtrSpeed); // motor control
  delay(10); 
}