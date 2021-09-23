function GetFroniusValues {
    #base url = /solar_api/v1
    $url = "http://xxxxxxx/solar_api/v1/GetPowerFlowRealtimeData.fcgi"

    $a = Invoke-WebRequest -Uri $url -Headers $Headers  -ContentType  'application/json; charset=utf-8'

    #convert data to JSON format
    $releases = ConvertFrom-Json $a.content
    $inverters = $releases[0].Body.Data.Inverters #object of inverters
    $site = $releases[0].Body.Data.Site #object of site

    #Check only data inverter 1
    $datos = $inverters.1

    write-host "Inverter" -ForegroundColor Yellow
    write-host "DT: " $datos.DT
    write-host "E_Day: " $datos.E_Day
    write-host "E_Total: " $datos.E_Total
    write-host "E_Year: " $datos.E_Year
    write-host "P: " $datos.P
    
    write-host "Site"  -ForegroundColor Yellow 
    write-host "E_Day: " $site.E_Day
    write-host "E_Total: " $site.E_Total
    write-host "E_Year: " $site.E_Year
    write-host "P: " $site.P_PV
    
    #if you want to return some data put it here
    #return $datos
}

#execute
GetFroniusValues

#output example
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
