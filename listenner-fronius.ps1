function GetFroniusValue {
  $url = "http://xxxxxxx/solar_api/v1/GetPowerFlowRealtimeData.fcgi"
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

  return $releases  
}

function precioLuz {  
  #obtiene el precio de la luz zona baleares y canarias
  $url = 'https://api.preciodelaluz.org/v1/prices/now?zone=PCB'
  $response = Invoke-WebRequest -Uri $url -ContentType  "'Accept':'application/json; "
  $releases = ConvertFrom-Json $response.content
  $price = $releases.price / 1000
  return $price
}

function printWebpage {
  #obtiene los datos de las funciones
  $fronius = GetFroniusValue
  $precioLuz = precioLuz

  $inverters = $fronius[0].Body.Data.Inverters    #guardamos la info de los inversores
  $site = $fronius[0].Body.Data.Site              #guardamos la info de los sites 
  
  $rendimiento = $site.E_Total/1000 * $precioLuz  #calculamos el precio con nuestra potencia
  $rendimiento = [math]::Round($rendimiento,2)    #redondeamos

  #guardamos cada inversor por separado
  $inverter1 = $inverters.1
  $inverter2 = $inverters.2

  #print por consola IP > url solicitada
  write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

  #max nominalpower 27000 kwh sacado de su api
  $procesadoInverter1 = $inverter1.P / 1000
  $procesadoInverter2 = $inverter2.P / 1000

  $procesadoInverter1 = ($procesadoInverter1 * 100) / 27
  $procesadoInverter2 = ($procesadoInverter2 * 100) / 27

  $procesadoInverter1 = [math]::Round($procesadoInverter1,2)
  $procesadoInverter2 = [math]::Round($procesadoInverter2,2)

  $energyGeneratedDaily = ($site.E_Day/1000) / 2.2
  $energyGeneratedDaily = [math]::Round($energyGeneratedDaily,2)

  #logica de colores en las barras
  if ($procesadoInverter1 -le 20) {
    $bar = "bg-danger"
  }elseif( ($procesadoInverter1 -le 30) -and ($procesadoInverter1 -gt 20) ){
    $bar = "bg-warning"
  }elseif ($procesadoInverter1 -gt 30) {
    $bar = "bg-success"
  }

  if ($procesadoInverter2 -le 20) {
    $bar2 = "bg-danger"
  }elseif( ($procesadoInverter2 -le 30 -and $procesadoInverter2 -gt 20) ){
    $bar2 = "bg-warning"
  }elseif ($procesadoInverter2 -gt 30) {
    $bar2 = "bg-success"
  }

  #logica sol
  if ($procesadoInverter1 -le 30) {
    $sun = '<i class="bi bi-cloud-sun"></i>'
  } elseif ($procesadoInverter1 -gt 60) {
    $sun = '<i class="bi bi-brightness-high-fill"></i>'
  }else {
    $sun = '<i class="bi bi-brightness-high"></i>'
  }
  
  #logica enchufes
  if ($inverter1.E_Day -lt 1) {
    $plug1 = '<i class="bi bi-plug"></i>'
  }else {
    $plug1 = '<i class="bi bi-plug-fill"></i>'
  }

  if ($inverter2.E_Day -lt 1) {
    $plug2 = '<i class="bi bi-plug"></i>'
  }else {
    $plug2 = '<i class="bi bi-plug-fill"></i>'
  }

  #formateamos el resto de valores 
  $siteE_Day = $site.E_Day/1000
  $siteE_Day = [math]::Round($siteE_Day,2)

  $siteE_Year = $site.E_Year/1000000
  $siteE_Year = [math]::Round($siteE_Year,2)

  $siteE_Total = $site.E_Total/1000000
  $siteE_Total = [math]::Round($siteE_Total,2)

  $siteP_PV = $site.P_PV/1000
  $siteP_PV = [math]::Round($siteP_PV,2)

  #datos inverter 1
  $inverter1E_Day = $inverter1.E_Day/1000
  $inverter1E_Day = [math]::Round($inverter1E_Day,2)
  
  $inverter1E_Year = $inverter1.E_Year/1000000
  $inverter1E_Year = [math]::Round($inverter1E_Year,2)

  $inverter1E_Total = $inverter1.E_Total/1000000
  $inverter1E_Total = [math]::Round($inverter1E_Total,2)

  $inverter1E_P = $inverter1.P/1000000
  $inverter1E_P = [math]::Round($inverter1E_P,2)

  #datos inverter 2
  $inverter2E_Day = $inverter2.E_Day/1000
  $inverter2E_Day = [math]::Round($inverter2E_Day,2)
  
  $inverter2E_Year = $inverter2.E_Year/1000000
  $inverter2E_Year = [math]::Round($inverter2E_Year,2)

  $inverter2E_Total = $inverter2.E_Total/1000000
  $inverter2E_Total = [math]::Round($inverter2E_Total,2)

  $inverter2E_P = $inverter2.P/1000000
  $inverter2E_P = [math]::Round($inverter2E_P,2)


  #CO2 = kg/kWh
  #CO2 = 800-900 gramos de CO2/kWh en Baleares.
  #ejemplo 34.960 kWh/año x 181 g de CO2/kWh  /1^6
  $co2 = 900
  $toneladasCO2diario = ($siteE_Day * $co2)/1000000
  $toneladasCO2Anual = ($siteE_Year * $co2)/1000000
  $toneladasCO2Totales = (($siteE_Total*1000) * $co2)/1000000

  #componemos el html con los datos variables
  [string]$html = '
  <!doctype html>
  <html lang="es">
    <head>
      <!-- Required meta tags -->
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  
      <!-- Bootstrap CSS -->
      <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.7.2/font/bootstrap-icons.css">
      <title>Panel Placas Solares</title>
      <style>
        body {
          background-color: #0f4135;
        }
        .col-md-6 {
          background-color: #1C7A64;
        }
        .col-md-2 {
          background-color: #1C7A64;
        }
        .col-md-4 {
          background-color: #1C7A64;
        }
        .card {
          margin: 1rem auto;
          position: relative; 
          background-color: #1C7A64;
          border: 0;
          #fill: white;
        }
        .card-body-pc{
          z-index: 4;
          position: absolute;
          top: 10%;
          #right: 30%;
          left: 55%;
          bottom: 0;          
          text-align: center;
        }
        .card-body {
          z-index: 2;
          position: absolute;
          top: 7%;
          right: 33%;
          bottom: 0;
          left: 33%;
          text-align: center;
        }
      </style>
    </head>
    <body>
    <main>
    <div class="container py-4">
      <header class="pb-3 mb-4 border-bottom">
        <a href="/" class="d-flex align-items-center text-light text-decoration-none">
          
          <span class="fs-4"><h1>'+ $sun +'</i> Energia</h1></span>
        </a>
      </header>
      
      <div class="row align-items-md-stretch">
        <div class="col-md-4">
          <div class="h-100 p-5 rounded-3 text-light">
            <h2><i class="bi bi-lightning-charge-fill"></i>Global</h2>
            <p>Diario: '+$siteE_Day+' kWh</p>
            <p>Anual: '+$siteE_Year+' MWh</p>
            <p>Total: '+$siteE_Total+' MWh</p>
            <p>Potencia: '+$siteP_PV+' kWh</p>
            <p>Rendimiento: '+$rendimiento+' €</p>
            <p>CO2: '+$toneladasCO2Totales+' t/CO2</p>

          </div>
        </div>
        <div class="col-md-2">
          <div class="h-100 p-5 rounded-3 text-light">
            <!-- Card -->
            <div class="card" style="max-width: 20rem;">

              <!-- Card image -->
              <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" fill="currentColor" class="bi bi-pc-display-horizontal" viewBox="0 0 16 16">
              <path d="M1.5 0A1.5 1.5 0 0 0 0 1.5v7A1.5 1.5 0 0 0 1.5 10H6v1H1a1 1 0 0 0-1 1v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3a1 1 0 0 0-1-1h-5v-1h4.5A1.5 1.5 0 0 0 16 8.5v-7A1.5 1.5 0 0 0 14.5 0h-13Zm0 1h13a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-7a.5.5 0 0 1 .5-.5ZM12 12.5a.5.5 0 1 1 1 0 .5.5 0 0 1-1 0Zm2 0a.5.5 0 1 1 1 0 .5.5 0 0 1-1 0ZM1.5 12h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1 0-1ZM1 14.25a.25.25 0 0 1 .25-.25h5.5a.25.25 0 1 1 0 .5h-5.5a.25.25 0 0 1-.25-.25Z"/>
              </svg>

              <!-- Card content -->
              <div class="card-body-pc text-light rgba-black-light p-6">
                <p>'+$energyGeneratedDaily+' Equipos</p>
              </div>

            </div>
            <!-- Card -->

          </div>
        </div>
        <div class="col-md-6">
          <div class="h-100 p-5 rounded-3 text-light">
            <h2><i class="bi bi-graph-up"></i> Gráfico - Potencia</h2>
              <p>Inversor 1</p>
              <div class="progress">
                  <div class="progress-bar progress-bar-striped progress-bar-animated '+$bar+'" role="progressbar" style="width: '+$procesadoInverter1+'%;" aria-valuenow="'+$procesadoInverter1+'" aria-valuemin="0" aria-valuemax="100">'+$procesadoInverter1+'</div>
              </div>
              <p>Inversor 2</p>
              <div class="progress">
                  <div class="progress-bar progress-bar-striped progress-bar-animated '+$bar2+'" role="progressbar" style="width: '+$procesadoInverter2+'%" aria-valuenow="'+$procesadoInverter2+'" aria-valuemin="0" aria-valuemax="100">'+$procesadoInverter2+'</div>
              </div>                 
          </div>
        </div>
      </div> 
  
      <div class="row align-items-md-stretch">
        <div class="col-md-6">
          <div class="h-100 p-5 text-light">
            <h2>'+ $plug1 +' Inversor 1</h2>
            <p>Diario: '+$inverter1E_Day+' kWh</p>
            <p>Anual: '+$inverter1E_Year+' MWh</p>
            <p>Total: '+$inverter1E_Total+' MWh</p>
            <p>Potencia: '+$inverter1P+' kWh</p>
            <!-- Card -->
            <div class="card" style="max-width: 20rem;">
    
              <!-- Card image -->
              <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" fill="currentColor" class="card-img-top bi bi-lightbulb" viewBox="0 0 16 16">
              <path d="M2 6a6 6 0 1 1 10.174 4.31c-.203.196-.359.4-.453.619l-.762 1.769A.5.5 0 0 1 10.5 13a.5.5 0 0 1 0 1 .5.5 0 0 1 0 1l-.224.447a1 1 0 0 1-.894.553H6.618a1 1 0 0 1-.894-.553L5.5 15a.5.5 0 0 1 0-1 .5.5 0 0 1 0-1 .5.5 0 0 1-.46-.302l-.761-1.77a1.964 1.964 0 0 0-.453-.618A5.984 5.984 0 0 1 2 6zm6-5a5 5 0 0 0-3.479 8.592c.263.254.514.564.676.941L5.83 12h4.342l.632-1.467c.162-.377.413-.687.676-.941A5 5 0 0 0 8 1z"/>
              </svg>
    
              <!-- Card content -->
              <div class="card-body text-light rgba-black-light p-6">
                <p>'+$inverter1E_Day+' kWh</p>
              </div>
    
            </div>
            <!-- Card -->
          </div>
        </div>
        <div class="col-md-6">
          <div class="h-100 p-5 text-light">
            <h2>'+ $plug2 +' Inversor 2</h2>
            <p>Diario: '+$inverter2E_Day+' kWh</p>
            <p>Anual: '+$inverter2E_Year+' MWh</p>
            <p>Total: '+$inverter2E_Total+' MWh</p>
            <p>Potencia: '+$inverter2P+' kWh</p>

            <!-- Card -->
            <div class="card" style="max-width: 20rem;">
    
              <!-- Card image -->
              <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" fill="currentColor" class="card-img-top bi bi-lightbulb" viewBox="0 0 16 16">
              <path d="M2 6a6 6 0 1 1 10.174 4.31c-.203.196-.359.4-.453.619l-.762 1.769A.5.5 0 0 1 10.5 13a.5.5 0 0 1 0 1 .5.5 0 0 1 0 1l-.224.447a1 1 0 0 1-.894.553H6.618a1 1 0 0 1-.894-.553L5.5 15a.5.5 0 0 1 0-1 .5.5 0 0 1 0-1 .5.5 0 0 1-.46-.302l-.761-1.77a1.964 1.964 0 0 0-.453-.618A5.984 5.984 0 0 1 2 6zm6-5a5 5 0 0 0-3.479 8.592c.263.254.514.564.676.941L5.83 12h4.342l.632-1.467c.162-.377.413-.687.676-.941A5 5 0 0 0 8 1z"/>
              </svg>
    
              <!-- Card content -->
              <div class="card-body text-light rgba-black-light p-6">
                <p>'+$inverter2E_Day+' kWh</p>
              </div>
    
            </div>
            <!-- Card -->
          </div>
        </div>
      </div>       
      <!-- Optional JavaScript -->
      <!-- jQuery first, then Popper.js, then Bootstrap JS -->

      <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
      <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
    </body>
  </html>
  '  
  return $html
}

# Http Server
#$http = [System.Net.HttpListener]::new() 
$http = New-Object System.Net.HttpListener

# Hostname and port to listen on
$http.Prefixes.Add("http://192.168.10.100:8080/")

# Start the Http Server 
$http.Start()

# Log ready message to terminal 
if ($http.IsListening) {
    write-host " HTTP Server Ready!  " -f 'black' -b 'gre'
    write-host "now try going to $($http.Prefixes)" -f 'y'
    write-host "then try going to $($http.Prefixes)fronius" -f 'y'
}

# INFINTE LOOP
# Used to listen for requests
while ($http.IsListening) {

    # Get Request Url
    # When a request is made in a web browser the GetContext() method will return a request object
    # Our route examples below will use the request object properties to decide how to respond
    $context = $http.GetContext()

    # ROUTE EXAMPLE 2
    # http://127.0.0.1/some/form'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/fronius') {

        $html = printWebpage
      
        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
        $context.Response.OutputStream.Close()
    }
    # ROUTE EXAMPLE 2
    # http://127.0.0.1/some/form'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/fronius2') {

      $html = printWebpage

      #resposed to the request
      $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
      $context.Response.ContentLength64 = $buffer.Length
      $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
      $context.Response.OutputStream.Close() 
  }
    
    # ROUTE EXAMPLE 4
    # http://localhost:8080/quit'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/quit')
    {
        $http.Close()
    }

    # powershell will continue looping and listen for new requests...

} 

# Note:
# To end the loop you have to kill the powershell terminal. ctrl-c wont work :/
