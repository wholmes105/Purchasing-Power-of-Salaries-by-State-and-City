# Datafest 2018 Data Cleaning Script

# Note: Because Github sets a size limit of 25MB on file uploads, the original data cannot be included
  # with this file. However, by loading the shiny package and running the line below, the app can 
  # be viewed remotely from anywhere with an internet connection (please allow a few moments for 
  # teh app to load after the function is run)
# runGitHub("Purchasing-Power-of-Salaries-by-State-and-City", "wholmes105")

# Load the necessary packages and import the data ####
  library(dplyr)
  library(readxl)
# Import the necessary data
load("factoredData.Rdata")

# Select the necessary data and remove the rest of the data to improve performance ####
dataDemo = select(datafest2018NewApril6, companyId, jobId, country, stateProvince,
                  city, estimatedSalary)
remove(datafest2018NewApril6) # remove the unneeded data to improve performance

# Reclassify relevant factors as strings ####
dataDemo$stateProvince = as.character(dataDemo$stateProvince)
dataDemo$city = as.character(dataDemo$city)

# Clean the data and remove unwanted values (NAs, non-locations, etc.) ####
  # Remove duplicate offerings from the dataset
dataDemo = distinct(dataDemo) 
  # Filter out all jobs posted outside the US and remove the column (it is no longer informative)
dataDemo = filter(dataDemo, country == 'US') # Remove jobs outside the US
dataDemo = dataDemo[, -which(colnames(dataDemo) == 'country')] # Remove the Country column
  # Remove offerings where location is NA
dataDemo = dataDemo[-which(is.na(dataDemo$city)), ]

# Find the rows in which one offer is placed for multiple cities ####
  # If there is a '-' in the city column for an offering, the offering exists in multiple cities
cities = regexpr(text = dataDemo$city, pattern = '-') # determines if there is a '-' in the offer's city
multi = cbind(dataDemo, cities) %>% as.data.frame() # creates a df with the city names and '-' indicator
multi = filter(multi, cities != -1) %>% select(-cities) # removes offerings for single cities only

# Remove the unnecessary data
remove(cities)

# Create the necessary data frames to hold the data ####
dashNum = as.data.frame(matrix(ncol = 2, nrow = nrow(multi))) # create a df with the right dimensions
colnames(dashNum) = c('City', 'Dashes') # name the columns appropriately
dashNum$City = multi$city # fill the first column with the city names
# Collect the number of dashes in the new data frame
for(i in 1:nrow(multi)) { # for each row in the multi-city dataset, indicate the number of '-'
  dashNum$Dashes[i] = length(gregexpr(text = dashNum$City, pattern = '-')[[i]])
}
# Join the other columns to the new data frame
dashNum = cbind(dashNum, multi) # Join the data
dashNum = dashNum[, -6] # Remove the redundant city column

# Remove the unnecessary data to improve performance
remove(multi)
remove(i)

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
remove(fixCities)
remove(fixCities2)

# Recalculate the number of dashes in each row
for(i in 1:nrow(dashNum)) { # for each row in the multi-city dataset, indicate the number of '-'
  dashNum$Dashes[i] = length(gregexpr(text = dashNum$City, pattern = '-')[[i]])
}

# Account for the single offering that has 3 cities
dashNum$City[which(dashNum$Dashes > 1)] = gsub(pattern = '-', replacement = ' ', 
                                               dashNum$City[which(dashNum$Dashes > 1)])

# Create the new dataframe to be appended to ####
# Seperate the cities into multiple offerings - first use two-city jobs, then the three-city job
for(i in 1:nrow(dashNum)) { # For every job offering...
  if(dashNum$Dashes[i] == 1) { # Run the two-city algorythm to seperate the jobs into distinct rows
    myDash = regexpr(text = dashNum$City[i], '-')[[1]] - 1 # Identify the location of the dash
    cityName = substr(dashNum$City[i], 1, myDash) # Determine the name of the first city
    
    # Create a 1-row data frame and fill it with the new data
    myCity = as.data.frame(matrix(nrow = 1, ncol = ncol(dashNum))) # Create the new row to be added
    myCity[1, 2:ncol(dashNum)] = dashNum[i, 2:ncol(dashNum)] # Duplicate the job data
    myCity[1, 1] = cityName # Place the city name into the new row
    
    # Add the second city to the dataset and isolate the first city
    colnames(myCity) = colnames(dashNum) # Duplicate the column names
    dashNum = rbind(dashNum, myCity) # Add the new row to the dataset
    dashNum$City[i] = substr(dashNum$City[i], myDash + 2, nchar(dashNum$City[i])) # Remove the duplicate city name
  }
}

remove(i)

# Remove the unnecessary Dashes column and unneeded objects used in the loop
dashNum = dashNum[, -which(colnames(dashNum) == 'Dashes')] # Remove Dashes column
remove(myDash)
remove(myCity)
remove(cityName)


# Collect all the job postings for single cities ####
colnames(dataDemo)[which(colnames(dataDemo) == 'city')] = 'City' # Capitalize the column name for consistency
cities = regexpr(text = dataDemo$City, pattern = '-') # determines if there is a '-' in the offer's city
dataDemo = cbind(dataDemo, cities) %>% filter(cities == -1) # Isolate single-city offers
dataDemo = dataDemo[, -ncol(dataDemo)] %>% as.data.frame # Remove the dash-checking column, make a df

remove(cities) # Remove the cities object since it is no longer needed

# Append the single-city offers with the multi-city offers to get clean data and remove unneeded data
cleanData = rbind(dataDemo, dashNum) # Append the data
remove(dataDemo)
remove(dashNum)

# Import the Census Data (cleaned outside of R) ####
bls <- read_excel("CensusCity2010.xlsx", sheet = "Clean", 
                             col_types = c("text", "numeric", "skip", "skip", "skip", 
                                                            "skip", "skip", "skip"))

# Use regular expressions to place the states in a seperate column from the cities
bls$stateProvince = vector(length = nrow(bls)) %>% as.character() # create the state column
for(i in 1:nrow(bls)) { # for every city in the census dataset, move the State to the stateProvince column
  bls$stateProvince[i] = substr(bls$City[i], nchar(bls$City[i])-1, nchar(bls$City[i])) # Move the State
  bls$City[i] = substr(bls$`City`[i], 1, nchar(bls$City[i]) - 4) # Isolate the City
}

remove(i)

# Join the Census data with the Job data ####
finalData = inner_join(cleanData, bls) # join the datasets according to SQL Inner Join rules

# Remove the unneeded data
remove(bls)
remove(cleanData)

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
finalData$adjustedSalary = finalData$estimatedSalary / finalData$CoL * 100 # Adjust Salary
finalData$CoLDollars = finalData$CoL * 60060 / 100 # Adjust CoL to 2017 estimate
finalData$CoLRatio = finalData$estimatedSalary / finalData$CoLDollars * 100 # Calculate CoLRatio

# Format the data ####
# Add thousands-seperators and round to 2 decimal places for neatness
finalData$Salary = finalData$estimatedSalary %>% round(2) %>% format(big.mark = ',')
finalData$`Adjusted Salary` = finalData$adjustedSalary %>% round(2) %>% format(big.mark = ',')
finalData$`Cost of Living` = finalData$CoLDollars %>% round(2) %>% format(big.mark = ',')
finalData$`Salary / Cost of Living` = finalData$CoLRatio %>% round(2)

# Add unit symbols: $ and %, repsectively
finalData$Salary = paste('$', finalData$Salary, sep = '')
finalData$`Adjusted Salary` = paste('$', finalData$`Adjusted Salary`, sep = '')
finalData$`Cost of Living` = paste('$', finalData$`Cost of Living`, sep = '')
finalData$`Salary / Cost of Living` = paste(finalData$`Salary / Cost of Living`, '%', sep = ' ')

# Rename the stateProvince, companyId, jobId columns to be appropriate for front-end use
colnames(finalData)[which(colnames(finalData) == 'stateProvince')] = 'State'
colnames(finalData)[which(colnames(finalData) == 'companyId')] = 'CompanyID'
colnames(finalData)[which(colnames(finalData) == 'jobId')] = 'JobID'

# Remove duplicate entries and rename the data
AppData = distinct(finalData)
remove(finalData)

# Save the data ####
save(AppData, file = 'AppData.RData')

