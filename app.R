# Purchasing Power of Salaries by State and City
# Compare Local Cost of Living to individual jobs' salaries to identify the most valuable positions

# Load the necessary packages
library(shiny)
library(shinyjs)
library(dplyr)

# Load the data
load('AppData.RData')

# Note the columns that will not be shown to the user
filterOps = c("estimatedSalary", "adjustedSalary", "CoLDollars", "CoLRatio", "Cost of Living", "CoL")

# Define UI for app that searches jobs by Cost of Living and Salary 
ui = fluidPage( # ui #### 
                # Enable use of the shinyjs package
                useShinyjs(),
                
                # Adjust the font size for the table headers with CSS
                tags$head(tags$style("#tabletitle1{font-size: 25px}")),
                tags$head(tags$style("#tabletitle2{font-size: 25px}")),
                
                # Application title
                titlePanel("Purchasing Power of Salaries by State and City"),
                
                # Sidebar to define search parameters
                sidebarLayout(
                  # Create the sidebar to hold inputs for the user to adjust their search
                  sidebarPanel(
                    # Create inputs to filter search results in the large (i.e. second) table
                      # Create City and State inputs to filter search by location
                      # Selection of multiple locations is allowed
                      # Options are presented in alphabetical order (the topmost option is the default)
                    # Present States to be selected
                    selectizeInput('State', 'State', choices = sort(unique(AppData$State)), 
                                   multiple = TRUE, selected = 'AK', 
                                   options = list(placeholder = 'Choose a State')),
                    # Present Cities to be selected
                    selectizeInput('City', 'City', sort(unique(AppData$City)), 
                                   multiple = TRUE, selected = 'Anchorage', 
                                   options = list(placeholder = 'Choose a City')),
                    # Create numeric inputs to filter search by 
                      # Salary, Cost of Living, and the CoL:Salary ratio
                    numericInput('Salary', 'Salary', # Salary
                                 value = 0, min = 0, step = 10000), 
                    numericInput('adjustedSalary', 'Adjusted Salary', # CoL
                                 value = 0, min = 0, step = 10000), 
                    numericInput('CoLRatio', 'Cost of Living Ratio', # CoLRatio
                                 value = 0, min = 0, step = 10) 
                  ),
                  
                  # Create the main panel to display the search results
                    # Each table has a Title, Subtitle with hyperlink to source, and the table itself
                  mainPanel(
                    # Table 1: Local Cost of Living (Annually)
                    textOutput('tabletitle1'), # Title
                    tags$a(href = "https://www.indeed.com/", "source: Indeed.com"), # Subtitle
                    tableOutput('CoL'), # Display the Cost of Living table
                    # Add a dividing line with a line break above and below to separate the two tables
                    br(), # Line break
                    hr(), # Dividing line
                    br(), # Line break
                    # Table 2: Search results - Company, Job Title, Salary, etc.
                    textOutput('tabletitle2'), # Title
                    tags$a(href = "https://www.bls.gov/", "source: US Bureau of Labor Statistics"), # Subtitle
                    dataTableOutput('Table') # Display the Search Results table
                  )
                )
)

# Server ####
server = function(input, output, session) {
  # Create an object to update the options for input$City
  myData = reactive(sort((AppData %>% filter(State == input$State) %>% select(City) %>% unique())$City))
  
  # Note the length of State and City to ensure the user has both inputs filled
  sl = reactive(length(input$State)) # How many States are selected?
  cl = reactive(length(input$City)) # How many Cities are selected?
  
  # Create a title for each table
  output$tabletitle1 = renderText("Adjusted Yearly Cost of Living by City")
  output$tabletitle2 = renderText("Job Details by City and State")
  
  # Update CoLData when City or State are changed
  observeEvent(input$City, { # When a value is added to City
    # Display the City, State, and Cost of Living
    CoLData = unique(
      filter(AppData, State == input$State, City == input$City)[, c('State', 'City', 'Cost of Living')]
    )
    # Rename the Cost of Living column for the CoLData table and format it appropriately
    colnames(CoLData)[3] = 'Annual Avg. Cost of Living'
    CoLData$`Annual Avg. Cost of Living` = format(CoLData$`Annual Avg. Cost of Living`)
    
    output$CoL = renderTable(
      if(is.null(input$State) | is.null(input$City)) { # If location is not entered appropriately
        return(NULL) # Hide the table
      } else{ # If location is entered appropriately
        return(CoLData) # Display the table
      }
    )
  })
  observeEvent(input$State, {
    # Display the City, State, and Cost of Living
    CoLData = unique( # Update the Cost of Living table
      filter(AppData, State == input$State, City == input$City)[, c('State', 'City', 'Cost of Living')]
    )
    # Rename the Cost of Living column for the CoLData table and format it appropriately
    colnames(CoLData)[3] = 'Annual Avg. Cost of Living'
    CoLData$`Annual Avg. Cost of Living` = format(CoLData$`Annual Avg. Cost of Living`)
    
    output$CoL = renderTable(
      if(is.null(input$State) | is.null(input$City)) { # If location is not entered appropriately
        return(NULL) # Hide the table
      } else{ # If location is entered appropriately
        return(CoLData) # Display the table
      }
    )
    
    # Update the selectable values for City
    updateSelectizeInput(session, inputId = 'City', choices = myData(),
                         # Determine which Cities to display to the user
                         selected = ifelse(length(input$City %in% myData()) > 0, 
                                           # If at least one chosen City is in the chosen State(s)
                                           input$City, # Display all chosen Cities in that State(s)
                                           # If no chosen City is in the chosen State
                                           myData()[1] # Display the first City in the State(s)
                                           )
    )
  })
  
  # Disable the City and numeric inputs if State is left blank
  observeEvent(sl(), {
    toggleState(id = 'City', !is.null(input$State))
    toggleState(id = 'Salary', !is.null(input$State))
    toggleState(id = 'adjustedSalary', !is.null(input$State))
    toggleState(id = 'CoLRatio', !is.null(input$State))
  })
  
  # Disable the State and numeric inputs if City is left blank
  observeEvent(cl(), {
    toggleState(id = 'State', !is.null(input$City))
    toggleState(id = 'Salary', !is.null(input$City))
    toggleState(id = 'adjustedSalary', !is.null(input$City))
    toggleState(id = 'CoLRatio', !is.null(input$City))
  })
  
  # Display the relevant Cost of Living Data to the user
  output$CoL = renderTable(
    if(is.null(input$State) | is.null(input$City)) { # If location is not entered appropriately
      return(NULL) # Hide the table
    } else{ # If location is entered appropriately
      return(CoLData) # Display the table
    }
  )
  
  output$Table = renderDataTable({ # Display the front-end data ####
    if(is.null(input$State) | is.null(input$City)) { # If location is not entered appropriately
      return(NULL) # Hide the table
    } else{ # If location is entered appropriately
      filter(AppData, State == input$State, City == input$City, # Display the table
             estimatedSalary >= input$Salary,
             adjustedSalary >= input$adjustedSalary,
             CoLRatio >= input$`CoLRatio`
      ) [, -which(colnames(AppData) %in% filterOps)] # Display only formatted data in the table
    }
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

