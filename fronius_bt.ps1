#Import the module, create a data source and a table
Import-Module PSSQLite

$Database = "C:\sqlite\placasSolares.db"
$con = New-SQLiteConnection -DataSource $Database
#$con.Open() 
#Write-Output $con

function GetFroniusValue {
    $url = "http://x.x.x.x/solar_api/v1/GetPowerFlowRealtimeData.fcgi"
    $a = Invoke-WebRequest -Uri $url -ContentType  'application/json; charset=utf-8'
  
    #convierte a formato JSON para poder ser procesado
    $releases = ConvertFrom-Json $a.content
    $inverters = $releases[0].Body.Data.Inverters
    $site = $releases[0].Body.Data.Site
  
    #temporalmente filtramos por el inversor con id 1
    #$datos = $inverters.1
  
    write-host "Inverter" -ForegroundColor Yellow
    write-host "DT: " $inverters[0].1
    write-host "Site"  -ForegroundColor Yellow 
    write-host "E_Day: " $site
    write-host "P_PV: " $site.P_PV
  
    return $releases  
  }

function insertSQL {
    param ($values)
    #Write-Output $con
    #Invoke-SqliteQuery -SQLiteConnection $con -Query "PRAGMA STATS"
    #id                : 1
    #time              : 22/09/2022 11:00:00
    #site_E_day        : 123
    #site_E_Total      : 123
    #site_E_Year       : 12315
    #site_P_PV         : 11123
    #inversor1_E_Day   : 123
    #inversor1_E_Total : 123456
    #inversor1_E_Year  : 123456
    #inversor1_P       : 123132
    #inversor2_E_Day   : 4542313
    #inversor2_E_Total : 13213
    #inversor2_E_Year  : 12313
    #inversor2_P       : 13213

    # recuperamos los valores y agrupamos el objeto por inverters y site
    $inverter1 = $froniusData[0].Body.Data.Inverters.1
    $inverter2 = $froniusData[0].Body.Data.Inverters.2
    $site = $froniusData[0].Body.Data.Site

    #inverter 1
    $inverter1_DT = $inverter1.DT
    $inverter1_E_Day = $inverter1.E_Day
    $inverter1_E_Total = $inverter1.E_Total
    $inverter1_P = $inverter1.P
    
    #inverter 2
    $inverter2_DT = $inverter2.DT
    $inverter2_E_Day = $inverter2.E_Day
    $inverter2_E_Total = $inverter2.E_Total
    $inverter2_P = $inverter2.P

    $time = Get-Date
    $time = $time.ToString("yyyy-MM-dd HH\:mm\:ss") #22/09/2022 12:00:00

    try {
        $Query = "INSERT INTO fronius_bt (id,time,site_E_day,site_E_Total,site_P_PV,inversor1_E_Day,inversor1_P,inversor2_E_Day,inversor2_P) 
            VALUES (NULL,'$($time)','1','2','3','$($inverter1_E_Day)','$($inverter1_P)','$($inverter2_E_Day)','$($inverter2_P)')"

        Invoke-SqliteQuery -SQLiteConnection $con -Query $Query
        $con.Close()
        Write-host "Row Inserted!" -ForegroundColor Green
    }
    catch {
        Write-host "Error: $($_.Exception.Message)"
    }
}

$froniusData = GetFroniusValue
#write-host $froniusData[0].Body.Data.Inverters.1 -ForegroundColor Blue
#write-host $froniusData[0].Body.Data.Inverters.2 -ForegroundColor Blue
#write-host $froniusData[0].Body.Data.Site -ForegroundColor Blue
insertSQL -values $froniusData
