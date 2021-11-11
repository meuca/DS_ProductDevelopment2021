#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

  
  
  observeEvent(input$min1, {
    updateSliderInput(session, 'slider1', min = input$min1)
  })
  
  observeEvent(input$max1, {
    updateSliderInput(session, 'slider1', max = input$max1)
  })
  
  observeEvent(input$reset, {
    updateSliderInput(session, 's1', value = 0)
    updateSliderInput(session, 's2', value = 0)
    updateSliderInput(session, 's3', value = 0)
    updateSliderInput(session, 's4', value = 0)
  })
  
  observeEvent(input$n, {
    
    if(is.null(input$n) | is.na(input$n) ){
      nombre = 'correr'
    }else if(input$n == 1){
      nombre <- paste('Correr', input$n, 'vez', sep = ' ')
    } else{
      nombre <- paste('Correr', input$n, 'veces', sep = ' ')
    }
    
    updateActionButton(session, 'correr', label = nombre)
    
    
  })
  
  observeEvent(input$nvalue, {
    #updateNumericInput(session, 'nvalue', value = input$nvalue+1)
  })
  
  observeEvent(input$celsius, {
    f <- round(input$celsius*(9/5)+32)
    updateNumericInput(session, 'farenheit', value = f)
  })
  
  observeEvent(input$farenheit, {
    c <- round((input$farenheit-32)*(5/9))
    updateNumericInput(session, 'celsius', value = c)
  })
  

})
