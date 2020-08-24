![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-1.png)
# Sensor_ECG_PPG_MAX86150 | ECG / PPG Sensor

Arduino based sensor learning project. The feature combines ECG/PPG data with heart rate calculation, plotting the ECG/PPG curve which used Processing on your computer.

 - Bias Cancellation | Store raw data in time, when new data coming that bias level will calculate as hysteresis filter.

 - Heart Rate Detect | Setting upper/lower threshold once your ECG/PPG value cross u/l threshold, check windows will output the BPM results (Both PPG/ECG).


This board also support WiFi transmission via ESPNOW (ESP8266 Broadcast), and need power by battery. And you need 2x esp8266 board.

1) Read receiver esp8266's mac address.
2) Fill it into transmitter sketch. "ECG_PPG_MAX86150_V5_WiFi_TX"


** **A Known Issue** **

Sampling rate from MAX86150 set as 200sps, but ESP8266's mutiplex with ESPNOW and sensor hub reading task, it will low down the output sample rate to ~150sps. So, when you measuring your ECG/PPG in realtime plot, it may show the missing R-R interval. (R-peak missing!) Don't worry it just the lower sample time caused.


```
Arduino tool kit, and require the following material:
- MCU: ESP8266 
- Display: SD1306_128x64_OLED
- Sensor: MAX86150
```
##

For coding example, you need the following library:

* [Adafruit_SSD1306](https://github.com/adafruit/Adafruit_SSD1306)
* [protocentral_max86150_ecg_ppg](https://github.com/Protocentral/protocentral_max86150_ecg_ppg)

## 

Any question or need technical support:

* Contact me via mail (xbcke12345@gmail.com)

## 
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-2.png)
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-3.png)
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-4.png)
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-5.png)
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-6.png)
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-7.png)
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-8.png)
![*Sensor_MAX86150*](https://github.com/Mic-Tsai/Health_Sensor_ecg_ppg_max86150/blob/master/res/Health_Sensor_ECG_PPG_MAX86150-9.png)
## 


>### License Information
>>This product is open source! Both, our hardware and software are open source and licensed under the following:
>>#### Hardware
>>>All hardware is released under [Creative Commons Share-alike 4.0 International](http://creativecommons.org/licenses/by-sa/4.0/)
>>#### Software 
>>>All software is released under the MIT License [http://opensource.org/licenses/MIT](http://opensource.org/licenses/MIT)
>>#### Documentation
>>>The documentation on this page is released under [Creative Commons Share-alike 4.0 International](http://creativecommons.org/licenses/by-sa/4.0/)
