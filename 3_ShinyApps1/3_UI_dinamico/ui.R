#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)


shinyUI(fluidPage(

    # Application title
    titlePanel("UI Dinamico"),
    
    tabsetPanel(
      tabPanel('Ejemplo 1',
              
               numericInput('min1', 'Limite inferior', value = 5),
               numericInput('max1', 'Limite superior', value = 10),
               sliderInput('slider1', 'Seleccione valor', min = 0, max = 15, value = 5)
               
               
               
               ),
      tabPanel('Ejemplo 2',
               
               sliderInput('s1', 'Seleccione Valor', min = -5, max = 5, value = 0),
               sliderInput('s2', 'Seleccione Valor', min = -5, max = 5, value = 0),
               sliderInput('s3', 'Seleccione Valor', min = -5, max = 5, value = 0),
               sliderInput('s4', 'Seleccione Valor', min = -5, max = 5, value = 0),
               
               actionButton('reset', 'Reiniciar sliders')
               
               ),
      tabPanel('Ejemplo 3', 
               
               numericInput('n', 'corridas', value = 10),
               actionButton('correr', 'correr')
               
               ),
      tabPanel('Ejemplo 4', 
               
               numericInput('nvalue', 'valor', value = 0)
               
               ),
      tabPanel('Ejemplo 5', 
               
               numericInput('celsius', 'temperatura en celsius', value=NA),
               numericInput('farenheit', 'temperatura en farenheit', value=NA)
               
               )
    )
    
    
    
    
    ))
