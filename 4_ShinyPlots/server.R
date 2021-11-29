#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(dplyr)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  
  #Dots Color Tracking
  plot.Colors <- reactiveValues(colVect = rep(1, nrow(mtcars)), preHoverColors = rep(1, nrow(mtcars)))
  
  #Plot update
  observe({
    output$plot_click_option <- renderPlot({
      plot(mtcars$wt, mtcars$mpg, xlab = 'wt', ylab = 'Millas por galon', pch = 16, cex = 2.5, col = plot.Colors$colVect)
      })
  })
  
  # 1 - HANDLE HOVER - On hover cambie el color a gris
  observeEvent(input$mouse_hover,{
    #cleaning previous hover
    plot.Colors$colVect <- plot.Colors$preHoverColors
    
    #Getting hover dot(s)
    eventDots <- nearPoints(mtcars, input$mouse_hover, xvar = 'wt', yvar = 'mpg')
    
    #Filter rows
    filteredRowsIndex <- mtcars$wt == eventDots$wt & mtcars$mpg == eventDots$mpg
    
    #Update Dot color tracking
    plot.Colors$colVect[filteredRowsIndex] <- 8
  })
  
  
  # 2 - HANDLE CLICK - On click cambie el color a verde
  # 5 - HANDLE CLICK - On click mostramos la informacion del punto en una tabla
  observeEvent(input$click,{
    #Getting click dot
    eventDots <- nearPoints(mtcars, input$click, xvar = 'wt', yvar = 'mpg')
    
    #Filter rows
    filteredRowsIndex <- mtcars$wt == eventDots$wt & mtcars$mpg == eventDots$mpg
    
    #Update Dot color tracking
    plot.Colors$colVect[filteredRowsIndex] <- 3
    plot.Colors$preHoverColors[filteredRowsIndex] <- 3
    
    #click info
    output$mtcars_tbl_click <- renderTable({eventDots})
  })
  
  # 3 - HANDLE DOUBLE CLICK - On doble click quite el color
  observeEvent(input$dclk,{
    #Getting double click dot
    eventDots <- nearPoints(mtcars, input$dclk, xvar = 'wt', yvar = 'mpg')
    
    #Filter rows
    filteredRowsIndex <- mtcars$wt == eventDots$wt & mtcars$mpg == eventDots$mpg
    
    #Update Dot color tracking
    plot.Colors$colVect[filteredRowsIndex] <- 1
    plot.Colors$preHoverColors[filteredRowsIndex] <- 1
    
  })
  
  # 4 - HANDLE BRUSH - On brush cambie el color (verde) a los puntos que estan dentro del rectangulo.
  observeEvent(input$mouse_brush,{
    #Getting brushed dots
    eventDots <-  brushedPoints(mtcars, input$mouse_brush, xvar='wt', yvar = 'mpg')
    
    #Filter rows
    filteredRowsIndex <- mtcars$wt >= min(eventDots$wt) & mtcars$wt <= max(eventDots$wt) & mtcars$mpg >= min(eventDots$mpg) & mtcars$mpg <= max(mtcars$mpg)
    
    #Update Dot color tracking
    plot.Colors$colVect[filteredRowsIndex] <- 3
    plot.Colors$preHoverColors[filteredRowsIndex] <- 3
    
  })

  # 6 - On brush mostramos todos los puntos en el rectangulo
  output$mtcars_tbl <- renderTable({
    df <- brushedPoints(mtcars, input$mouse_brush, xvar='wt', yvar = 'mpg')
    df
  })


})
