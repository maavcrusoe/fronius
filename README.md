# Fronius

Obtain data from local fronius solar API

## Some URL API
```
/solar_api/v1/GetInverterInfo.cgi
/solar_api/v1/GetPowerFlowRealtimeData.fcgi
/solar_api/v1/GetInverterRealtimeData.cgi?Scope=System
/solar_api/v1/GetInverterRealtimeData.cgi?Scope=Device&DeviceId=1&DataCollection=CommonInverterData
```
## Output example
```
Inverter
DT:  72
E_Day:  524,9000244140625
E_Total:  100708200
E_Year:  32907918
P:  2548
Site
E_Day:  524,9000244140625
E_Total:  100708200
E_Year:  32907918
P:  2548
```
## PowerShell WebServer
You can use this PS script in your kiosk or local network to print some data about your fronius solar panels, if you need to print something else only need to change all the content in printWebpage function. [Webserver](https://github.com/maavcrusoe/fronius/blob/main/listenner-fronius.ps1)

```
GET /fronius
GET /quit 
POST if you want
```
