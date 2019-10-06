# DOUBLE CHECK THAT THE GITHUB DOESN'T CONTAIN AN ATTEMPT TO EMBED SHINY INTO STATIC HTML

# Datafest 2018 Data Cleaning Script
  # Download the data at https://drive.google.com/open?id=1jAE4DGtAjmyOVbrEjJ5_s4OOEZ990w9G

# Note: Because Github sets a size limit of 25MB on file uploads, the original data cannot be included
  # with this file. However, by installing the shiny package and running the line below, the app can 
  # be viewed remotely from anywhere with an internet connection (please allow a few moments for 
  # the app to load after the function is run)
# shiny::runGitHub("Purchasing-Power-of-Salaries-by-State-and-City", "wholmes105")

# Load the necessary packages and import the data ####
# Load the necessary packages
library(dplyr)
library(data.table)
library(foreach)
library(doParallel)

# Prepare for parallel processing below
  # This script leaves one core available to the OS and makes use of all other cores when parallel processing
    # If two cores or fewer are available, only one core is used
(detectCores() - 1) %>% max(1) %>% registerDoParallel() 

# Import the necessary data
# load("factoredData.Rdata")
fread(
  "datafest2018NewApril6.csv", 
  select = c(
    'companyId', 
    'jobId', 
    'country', 
    'stateProvince',
    'city',
    'estimatedSalary'
  )
)

# 
dataDemo = as.data.table(datafest2018NewApril6)[, .(
  companyId, 
  jobId, 
  country, 
  stateProvince = as.character(stateProvince), 
  city = as.character(city), 
  estimatedSalary
)]

remove(datafest2018NewApril6) # remove the unneeded data to free resources

# Clean the data and remove unwanted values (NAs, non-locations, etc.) ####
  # Remove duplicate offerings from the dataset
dataDemo = distinct(dataDemo)
  # Filter out all that are jobs posted outside the US or do not have a location specified
# and remove the column (it is no longer informative)
dataDemo = dataDemo[country == 'US'][!is.na(city)]

# Remove the Country column (it no longer holds distinguishing information)
dataDemo = dataDemo[, country := NULL] 

# Find the rows in which one offer is placed for multiple cities ####
  # If there is a '-' in the city column for an offering, the offering exists in multiple cities
# Create a subset of the data containing only job offerings with multiple cities
dashNum = copy(dataDemo)[regexpr(text = city, pattern = '-') != -1] %>% setnames('city', 'City')

# Create a column indicating how many dashes are in each City
dashNum[, Dashes := gregexpr(text = City, pattern = '-') %>% lapply(length) %>% unlist()]

# Replace dashes used as spaces with the appropriate characters ####
fixCities = c( # define the city names that use '-' innappropriately (and a street address)
  'Cardiff-by-the-Sea',
  'Tri-Cities',
  'Mentor-on-the-Lake',
  'Carmel-by-the-Sea',
  'Co-Op City',
  'Lauderdale-by-the-Sea',
  'Castleton-on-Hudson',
  'Croton-on-Hudson',
  'Nine-mile',
  'Hastings-on-Hudson',
  'Ho-Ho-Kus',
  'Geneva-on-the-Lake',
  'Saint Mary-of-the-Woods',
  'Cornwall-on-Hudson',
  '11 North-Victoria Road-FM 493 Colonia',
  'Fifty-Six',
  'Ak-Chin Village',
  'Malden-on-Hudson'
)
fixCities2 = c( # define the corrected city names from fixCities
  'Cardiff by the Sea',
  'Tri Cities',
  'Mentor on the Lake',
  'Carmel by the Sea',
  'Co Op City',
  'Lauderdale by the Sea',
  'Castleton on Hudson',
  'Croton on Hudson',
  'Nine mile',
  'Hastings on Hudson',
  'Ho Ho Kus',
  'Geneva on the Lake',
  'Saint Mary of the Woods',
  'Cornwall on Hudson',
  'Colonia',
  'Fifty Six',
  'Ak Chin Village',
  'Malden on Hudson'
)

# Build a loop to search for each of the city names and fix them
for(i in 1:length(fixCities)) {
  dashNum$City = gsub(pattern = fixCities[i], replacement = fixCities2[i], dashNum$City)
}

# Remove the vectors, since they will no longer be used
remove(
  fixCities,
  fixCities2
)

# Recalculate the number of dashes in each row
dashNum[, Dashes := gregexpr(text = City, pattern = '-') %>% lapply(length) %>% unlist()]

# Account for the single offering that has 3 cities
dashNum[Dashes > 1, City := City %>% gsub(pattern = '-', replacement = ' ')]

# Create the new table to be appended to #### # nrow before/after start | 3143/6285
# Seperate the cities into multiple offerings - first use two-city jobs, then the three-city job
dashNum = foreach(i = 1:nrow(dashNum), .packages = 'dplyr') %dopar% { # For every job offering...
  if(dashNum$Dashes[i] == 1) { # Run the two-city algorythm to seperate the jobs into distinct rows
    myDash = regexpr(text = dashNum$City[i], '-')[[1]] - 1 # Identify the location of the dash
    cityName = substr(dashNum$City[i], 1, myDash) # Determine the name of the first city
    
    # Create a 1-row data frame and fill it with the new data
    myCity = as_tibble(matrix(nrow = 2, ncol = ncol(dashNum))) # Create the new row to be added
    myCity[, 2:ncol(dashNum)] = dashNum[i, 2:ncol(dashNum)] # Duplicate the job data
    myCity[1, 1] = cityName # Place the city name into the new row
    
    # Add the second city to the dataset and isolate the first city
    colnames(myCity) = colnames(dashNum) # Duplicate the column names
    # dashNum = rbind(dashNum, myCity) # Add the new row to the dataset
    myCity[2, 1] = substr(dashNum$City[i], myDash + 2, nchar(dashNum$City[i])) # Note the second city name
  } else(myCity = dashNum[i, ])
  
  return(myCity)
} %>% rbindlist()


remove(i)

# Remove the unnecessary Dashes column and unneeded objects used in the loop
dashNum = dashNum[, Dashes := NULL] # Remove Dashes column

# Collect all the job postings for single cities ####
colnames(dataDemo)[which(colnames(dataDemo) == 'city')] = 'City' # Capitalize the column name for consistency

# Determine if there is a '-' in the city name and isolate single-city offers
dataDemo = dataDemo[regexpr(text = dataDemo$City, pattern = '-') == -1]

# Append the single-city offers with the multi-city offers to get clean data and remove unneeded data
cleanData = rbind(dataDemo, dashNum) # Append the single-city and multi-city data.tables
remove(
  dataDemo, 
  dashNum
)

# Import the Census Data (cleaned outside of R) ####
bls = readxl::read_excel("CensusCity2010.xlsx", sheet = "Clean", 
                             col_types = c("text", "numeric", "skip", "skip", "skip", 
                                                            "skip", "skip", "skip"))

# Use regular expressions to place the states in a seperate column from the cities
bls$stateProvince = vector(length = nrow(bls)) %>% as.character() # create the state column
for(i in 1:nrow(bls)) { # for every city in the census dataset, move the State to the stateProvince column
  # Move the State (it is always the last two characters in the City column)
  bls$stateProvince[i] = substr(bls$City[i], nchar(bls$City[i])-1, nchar(bls$City[i])) 
  # Remove the state abbreviation and comma from the City column
  bls$City[i] = substr(bls$`City`[i], 1, nchar(bls$City[i]) - 4) 
}

remove(i)

# Join the Census data with the Job data ####
finalData = merge(
  # Perform an inner join on the cleanData and bls tables
  cleanData,
  bls,
  # Use the stateProvince and City fields to join the tables
  by = c('stateProvince', 'City')
)

# Remove the unneeded data
remove(
  bls, 
  cleanData
)

# Estimate the National Cost of Living
  # https://www.statista.com/statistics/247455/annual-us-consumer-expenditures/
  # According to the sidebar on the page above (now changed), the 2017 Cost of Living was $60,060
# Column Definitions
  # CoL: Local Cost of Living expressed as a percentage, i.e. 100 = 100%
  # estimatedSalary: estimated Salary of position (no adjustments made)
  # adjustedSalary: estimated Salary adjusted for local CoL; the value it'd have if CoL were national avg
  # CoLDollars: Local Cost of Living expressed as a dollar amount, i.e. 50000 = $50,000 annually
  # CoLRatio: How much of the local CoL does the job pay, expressed as a percentage, i.e. 67 = 67%

# Create the calculated fields
finalData[
  ,
  adjustedSalary := estimatedSalary / CoL * 100 # Adjust Salary
][
  ,
  CoLDollars := CoL * 60060 / 100 # Adjust CoL to 2017 estimate
][
  ,
  CoLRatio := estimatedSalary / CoLDollars * 100 # Calculate CoLRatio
]

# Format the data ####
# Add thousands-seperators and round to 2 decimal places for neatness
finalData[
  ,
  Salary := estimatedSalary %>% round(2) %>% format(big.mark = ',')
][
  ,
  `Adjusted Salary` := adjustedSalary %>% round(2) %>% format(big.mark = ',')
][
  ,
  `Cost of Living` := CoLDollars %>% round(2) %>% format(big.mark = ',')
][
  ,
  `Salary / Cost of Living` := CoLRatio %>% round(2)
]

# Add unit symbols: $ and %, repsectively
finalData[
  ,
  Salary := paste('$', Salary, sep = '')
][
  ,
  `Adjusted Salary` := paste('$', `Adjusted Salary`, sep = '')
][
  ,
  `Cost of Living`  :=  paste('$', `Cost of Living`, sep = '')
][
  ,
  `Salary / Cost of Living` := paste(`Salary / Cost of Living`, '%', sep = ' ')
]

# Rename the stateProvince, companyId, jobId columns to be appropriate for front-end use
finalData %>% setnames(
  c('stateProvince', 'companyId', 'jobId'), 
  c('State', 'CompanyID', 'JobID')
)

# Remove duplicate entries and rename the data
AppData = distinct(finalData)
remove(finalData)

# Save the data ####
save(AppData, file = 'AppData.RData')

