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
    titlePanel("Tarea - Interacciones con graficas en Shiny"),
    
    
    plotOutput('plot_click_option',
               click = 'click',
               dblclick = 'dclk',
               hover = 'mouse_hover',
               brush = 'mouse_brush'
    ),
    
    tableOutput('mtcars_tbl_click'),
    
    tableOutput('mtcars_tbl'),
    
    

    ))
