#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(DT)
library(stringr)
library(dplyr)
library(ggplot2)  #Graphs
library(mapview)  #Map Handling
library(sf)       #Utilities
library(sp)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  filtersVarNames <- c('precio', 'longitud', 'latitud', 'contruccion', 'habitaciones', 'dormitorios', 'poblacion', 'horages', 'ingresos')
  dsColumnNames <-c('precio', 'longitude', 'latitude', 'anios_de_contruccion', 'total_habitaciones', 'total_dormitorios', 'poblacion', 'hogares', 'ingresos_medios')
  
  #--------------------------URL INPUTS------------------------------------------------------------
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query[['user']])) {
      output$userName <- renderText(paste("Bienvenid@ ", query[['user']]))
      #updateTextInput(session, "userName", value = paste("Bienvenid@ ", query[['user']]))
    }
    if(!is.null(query[['tab']])){
      tabSelected <- switch(query[['tab']], '1' = "Datos generales", '2' = "Tabla", '3' = "Graficas")
      updateTabsetPanel(session, "contentPanel", selected = tabSelected)
    }
  })
  
  
  
  #----------------------------LOAD DATA - SHOW METADATA---------------------------------------------
  archivo_cargado<-reactive({
    contenido_archivo<-input$cargar_archivo
    
    if  (is.null(contenido_archivo)){
      return(NULL)
    }else  if (str_detect(contenido_archivo$name,'.csv')){
      out<-readr::read_csv(contenido_archivo$datapath)  
      return (out)  
      
    } else if (str_detect(contenido_archivo$name,'.tsv')){
      out<-readr::read_tsv(contenido_archivo$datapath)
      return(out)
    }else {
      showModal(modalDialog(title = "Error!", "Extension de archivo no soportado", easyClose = TRUE,footer = NULL))
      return(NULL)
    }
  })
  
  output$inf_archivo <-renderDataTable({
    fileMetaData <- c('Archivo no seleccionado', 0)
    
    if(!is.null(archivo_cargado())){
      fileMetaData <- c(input$cargar_archivo$name, nrow(archivo_cargado()))
    }
    data.frame(Descripcion = fileMetaData)
  }, options = list(pageLength = 4, lengthChange = FALSE, searching=FALSE, info=FALSE, targets = 1, aoColumnDefs = list(sWidth = "20px")))
  
  #Update Filters boundaries
  observeEvent(archivo_cargado(),{
    updateSliderInput(session,'precio', min = min(archivo_cargado()[['precio']]), max = max(archivo_cargado()$precio), value = c(min(archivo_cargado()$precio),max(archivo_cargado()$precio)))
    updateSliderInput(session,'longitud', min = min(archivo_cargado()$longitude), max = max(archivo_cargado()$longitude), value = c(min(archivo_cargado()$longitude),max(archivo_cargado()$longitude)))
    updateSliderInput(session,'latitud', min = min(archivo_cargado()$latitude), max = max(archivo_cargado()$latitude), value = c(min(archivo_cargado()$latitude),max(archivo_cargado()$latitude)))
    updateSliderInput(session,'contruccion', min = min(archivo_cargado()$anios_de_contruccion), max = max(archivo_cargado()$anios_de_contruccion), value = c(min(archivo_cargado()$anios_de_contruccion),max(archivo_cargado()$anios_de_contruccion)))
    updateSliderInput(session,'habitaciones', min = min(archivo_cargado()$total_habitaciones), max = max(archivo_cargado()$total_habitaciones), value = c(min(archivo_cargado()$total_habitaciones),max(archivo_cargado()$total_habitaciones)))
    updateSliderInput(session,'dormitorios', min = min(archivo_cargado()$total_dormitorios,na.rm = TRUE), max = max(archivo_cargado()$total_dormitorios,na.rm = TRUE), value = c(min(archivo_cargado()$total_dormitorios,na.rm = TRUE),max(archivo_cargado()$total_dormitorios, na.rm = TRUE)))
    updateSliderInput(session,'poblacion', min = min(archivo_cargado()$poblacion), max = max(archivo_cargado()$poblacion), value = c(min(archivo_cargado()$poblacion),max(archivo_cargado()$poblacion)))
    updateSliderInput(session,'horages', min = min(archivo_cargado()$hogares, na.rm = TRUE), max = max(archivo_cargado()$hogares, na.rm = TRUE), value = c(min(archivo_cargado()$hogares, na.rm = TRUE),max(archivo_cargado()$hogares, na.rm = TRUE)))
    updateSliderInput(session,'ingresos', min = min(archivo_cargado()$ingresos_medios, na.rm = TRUE), max = max(archivo_cargado()$ingresos_medios, na.rm = TRUE), value = c(min(archivo_cargado()$ingresos_medios, na.rm = TRUE),max(archivo_cargado()$ingresos_medios, na.rm = TRUE)))
    
  })
  
  #----------------------------SHOW DATA AND DATA FILTERING------------------------------------------
  output$resumen<-renderPrint({
    if(!is.null(archivo_cargado())){
      summary(archivo_cargado())
    }
  })
  
  output$contenido_archivo <- DT::renderDataTable(out_dataset())
  
  out_dataset <- reactive({
    if (is.null(archivo_cargado()))
    {return(NULL)}
    
    out<-
      archivo_cargado() %>%
      filter (longitude >= input$longitud[1],
              longitude <= input$longitud[2],
              
              latitude >= input$latitud[1],
              latitude <= input$latitud[2],
              
              anios_de_contruccion>= input$contruccion[1],
              anios_de_contruccion<= input$contruccion[2],
              
              total_habitaciones >= input$habitaciones[1],
              total_habitaciones <= input$habitaciones[2],
              
              total_dormitorios >= input$dormitorios[1],
              total_dormitorios <= input$dormitorios[2],
              
              poblacion >= input$poblacion[1],
              poblacion <= input$poblacion[2],
              
              hogares >= input$horages[1],
              hogares <= input$horages[2],
              
              ingresos_medios>= input$ingresos[1],
              ingresos_medios<= input$ingresos[2],
              
              precio >= input$precio[1],
              precio <= input$precio[2]
      )
    return(out)
  })
  
  #--------------------------------------------------------GRAPHS------------------------------------  
  #----------------------------HELP FUNCTIONS--------------------------------------------------------
  mapPlot <-function(data){
    Locations<-subset(data, select = c(longitude, latitude, precio,
                                       anios_de_contruccion,
                                       total_habitaciones,
                                       total_dormitorios,
                                       poblacion,
                                       hogares,
                                       ingresos_medios))
    # Convert points df to sf object
    Locations <- st_as_sf(Locations, coords = c("longitude", "latitude"))
    st_crs(Locations) <- "+init=epsg:4326 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0" # assign CRS to points
    return(mapview(Locations, zcol="precio", at = seq(0,600000,50000),cex=mapVarFilter()))
  }
  
  densityPlots<-function(ds, col, name){
    bins <- (max(ds[[col]])-min(ds[[col]]))/50
    ggplot(ds, aes(x = .data[[col]])) +
      geom_histogram(aes(y=..density..), colour="black", fill="white", binwidth = bins)+
      geom_density(alpha=.2, fill="#FF6666") +
      geom_vline(aes(xintercept=mean(.data[[col]]), color="Promedio"), linetype="dashed", size=1) +
      geom_vline(aes(xintercept=median(.data[[col]]), color="Mediana"), linetype="dashed", size=1) +
      
      theme(plot.title = element_text(hjust = 0.5, size = 22),
            axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            legend.title = element_text(size=15),
            legend.text = element_text(size=12),
            legend.key.height= unit(1, 'cm')
      )+
      scale_color_manual(name = "Estadisticas", values = c(Promedio = "blue", Mediana = "red"))+
      labs(title = paste("Grafica de densidad de ", name))
  }
  
  scatterPlot<-function(ds, xCol, yCol, xlabel, ylabel){
    ggplot(ds)+
      geom_point(aes(x = .data[[xCol]], y = .data[[yCol]] ), col = "blue", size=ranges$size)+
      geom_smooth(aes(x = .data[[xCol]], y = .data[[yCol]], color="Tendencia"), method = "lm", size = 1) +
      theme(plot.title = element_text(hjust = 0.5, size = 22),
            axis.title.x = element_text(size = 15),
            axis.title.y = element_text(size = 15),
            legend.title = element_text(size=15),
            legend.text = element_text(size=12),
            legend.key.height= unit(1, 'cm')) +
      scale_color_manual(name = "Linea de tendencia", values = c(Tendencia = "red"))+
      labs(title = paste("Grafica de dispersion de ", xlabel, " vs ", ylabel),
           x = xlabel,
           y = ylabel)+
      coord_cartesian(xlim = ranges$x, ylim = ranges$y, expand = FALSE)
  }
  
  variableReFormat <- function(unformattedVariable){
    switch (unformattedVariable,
            " " = "",
            "Precio" = "precio",
            'Anios de Construccion' = 'anios_de_contruccion',
            'Total de Habitaciones' = 'total_habitaciones',
            'Total Dormitorios' = 'total_dormitorios',
            'Poblacion' = 'poblacion',
            'Cantidad de Hogares' = 'hogares',
            'Ingresos Promedio' = 'ingresos_medios'
    )
  }
  
  #----------------------------REACTIVE INPUT FOR GRAPHS---------------------------------------------
  mapVarFilter <- reactive({ variableReFormat(input$mapVariables)})
  
  densityVarFilter <- reactive({ variableReFormat(input$densityVariables)})
  
  scatterVarX <- reactive({ variableReFormat(input$scatterVariablesX)})
  
  scatterVarY <- reactive({ variableReFormat(input$scatterVariablesY)})
  
  ranges <- reactiveValues(x = NULL, y = NULL, size = 0.5)
  
  #-----------------------------MAP GRAPH------------------------------------------------------------
  output$mapplot <- renderLeaflet({
    data<-out_dataset()
    
    if(!is.null(data)){
      mapPlot(data)@map
    }
  })
  #----------------------------DENSITY PLOTS---------------------------------------------------------
  output$densityPlot <- renderPlot({
    data<-out_dataset()
    
    if(!is.null(data)){
      densityPlots(data, densityVarFilter(), input$densityVariables)
    }
  })
  #----------------------------DYNAMIC SCATTER PLOTS---------------------------------------------------------
  observe({
    output$scatterPlot <- renderPlot({
      data<-out_dataset()
      
      if(!is.null(data) & !is.na(scatterVarX()) & !is.na(scatterVarY())){
        
        scatterPlot(data, scatterVarX(), scatterVarY(), input$scatterVariablesX, input$scatterVariablesY)
      }
    })
  })
  
  output$brushedDots <- DT::renderDataTable(brushedPoints(out_dataset(), input$scatterbrh, xvar=scatterVarX(), yvar = scatterVarY()))
  
  observeEvent(input$scatterdclk, {
    brush <- input$scatterbrh
    if (!is.null(brush)) {
      ranges$x <- c(brush$xmin, brush$xmax)
      ranges$y <- c(brush$ymin, brush$ymax)
      ranges$size <- 2
      
    } else {
      ranges$x <- NULL
      ranges$y <- NULL
      ranges$size <- 0.5
    }
  })
  
  
  
  #--------------------------------DOWNLOAD SET--------------------------------
  
  output$downloadData <- downloadHandler(
    filename = function() { 
      paste("dataset-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      write.csv(out_dataset(), file)
    })
  
  #---------------------------------RESET INPUT--------------------------------
  
  observeEvent(input$reset,{
    updateSliderInput(session,'precio', value = c(min(archivo_cargado()$precio),max(archivo_cargado()$precio)))
    updateSliderInput(session,'longitud', value = c(min(archivo_cargado()$longitude),max(archivo_cargado()$longitude)))
    updateSliderInput(session,'latitud', value = c(min(archivo_cargado()$latitude),max(archivo_cargado()$latitude)))
    updateSliderInput(session,'contruccion', value = c(min(archivo_cargado()$anios_de_contruccion),max(archivo_cargado()$anios_de_contruccion)))
    updateSliderInput(session,'habitaciones', value = c(min(archivo_cargado()$total_habitaciones),max(archivo_cargado()$total_habitaciones)))
    updateSliderInput(session,'dormitorios', value = c(min(archivo_cargado()$total_dormitorios,na.rm = TRUE),max(archivo_cargado()$total_dormitorios, na.rm = TRUE)))
    updateSliderInput(session,'poblacion', value = c(min(archivo_cargado()$poblacion),max(archivo_cargado()$poblacion)))
    updateSliderInput(session,'horages', value = c(min(archivo_cargado()$hogares, na.rm = TRUE),max(archivo_cargado()$hogares, na.rm = TRUE)))
    updateSliderInput(session,'ingresos', value = c(min(archivo_cargado()$ingresos_medios, na.rm = TRUE),max(archivo_cargado()$ingresos_medios, na.rm = TRUE)))
    
  })
  
  #----------------------------DYNAMIC INPUT-----------------------------
  updateFiltersLimits <- function(triggerFilter){
    if(!is.null(out_dataset())){
      if(nrow(out_dataset()) > 0){
        toProcessFilters <- filtersVarNames[filtersVarNames != triggerFilter] #Process all filters except the one that trigger the update
        toProcessColumns <- dsColumnNames[filtersVarNames != triggerFilter]
        for(i in 1:length(toProcessFilters)){
          updateSliderInput(session,toProcessFilters[i], value = c(min(out_dataset()[[toProcessColumns[i]]], na.rm = TRUE),max(out_dataset()[[toProcessColumns[i]]], na.rm = TRUE))) 
        }
      }
    }
  }
  
  observeEvent(input$precio,{
    updateFiltersLimits('precio')
  })
  
  observeEvent(input$longitud,{
    updateFiltersLimits('longitud')
  })
  
  observeEvent(input$latitud,{
    updateFiltersLimits('latitud')
  }) 
  
  observeEvent(input$construccion,{
    updateFiltersLimits('construccion')
  }) 
  
  observeEvent(input$habitaciones,{
    updateFiltersLimits('habitaciones')
  }) 
  
  observeEvent(input$dormitorios,{
    updateFiltersLimits('dormitorios')
  }) 
  
  observeEvent(input$poblacion,{
    updateFiltersLimits('poblacion')
  }) 
  
  observeEvent(input$horages,{
    updateFiltersLimits('horages')
  })
  
  observeEvent(input$ingresos,{
    updateFiltersLimits('ingresos')
  }) 
  
  
})
