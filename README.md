Purchasing Power of Salaries by State and City
================
William Holmes
January 17, 2019

Hosting
=======

Because this app is hosted on GitHub, it can also be viewed remotely on any machine that has R installed by entering the following command into the R console (note that this app requires the `data.table`, `dplyr`, `shiny`, and `shinyjs` packages):

``` eval
shiny::runGitHub("Purchasing-Power-of-Salaries-by-State-and-City", "wholmes105")
```

**Note:** If the data for the application is not available in the working directory, the app cannot be sourced. Run the `CleaningAndJoining.R` script after downloading the data [here](https://drive.google.com/open?id=1jAE4DGtAjmyOVbrEjJ5_s4OOEZ990w9G) to prepare the requisite data for use in the Shiny app.

About the Application
=====================

This application allow the user to select multiple cities to compare the purchasing power of their potential salaries across different locations within the United States.

About the Data that Drives it
=============================

Every year, the American Statistical Association (ASA) hosts a competition called Datafest. As part of the competition, the ASA selects a new "data sponsor" each year from one of many competing companies; the selected company then provides real data from their business and challenges participants to generate useful insights using the data provided. In the 2018 Miami University event, the data sponsor was [Indeed.com](https://Indeed.com), the job-hunting website. While certain aspects of the data were masked (i.e. tokenized and jittered) from the participants for legal reasons and to preserve trade secrets (for example, employers' names and the job titles advertised), the data itself was still real.

However, participants are also encouraged to seek and incorporate outside data sources as they are available; to identify the real purchasing power of a job's salary, data from the [US Bureau of Labor Statistics](https://bls.gov) was used to supplement the data provided by Indeed.

The data used in the application combines the BLS data mentioned above and a subset of that original Datafest data. In the Job Details by City and State table, each row represents a job advertised by a specific company on Indeed.com, and is uniquely represented by the combination of the CompanyID and the JobID. This app creates an interactive interface to simulate a job-seeker using Indeed's platform, augmented by data the company already has and/or can freely acquire, to find jobs that are of greater value, thus generating value for both themselves and for Indeed and its customers.

**Note:** because some jobs are advertised with multiple locations, certain openings may correspond to multiple rows to display the disparate purchasing power that would result from choosing one location over the other.

Why it Matters
==============

As with [Monster.com](https://www.monster.com/), Indeed likely makes several hundred dollars for every employer that posts an opening on their site. This application would allow Indeed to draw more job-seekers to their site by highlighting the jobs that are most valuable and desirable; in turn, Indeed could selectively use this feature on employers' behalf as part of a two-tiered advertising system, an expansion on their current model that would generate larger amounts of revenue and would require minimal maintenance and upkeep, thus adding tens or hundreds of thousands of dollars directly to their bottom line every year.

About the Code
==============

Included with this file is a [Shiny](http://shiny.rstudio.com/) app. Shiny is a package in R that translates R code into HTML, JavaScript, and CSS, which allows it to be viewed locally or placed on servers and viewed remotely; it also allows for an interactive analysis by exploiting the point-and-click nature of these web-based languages; finally, those with knowledge of web development can insert HTML, JavaScript, etc. directly into the Shiny app, allowing for greater flexibility during the creation process.

How to Open the Application
===========================

If you have access to this file and the associated files locally on your machine, you can click on any of the R files presented to automatically open them in R, assuming it is installed. If R is not already open, the working directory will be set to the opened file's location; if R is already running, then the working directory will need to be set to the file's current location so it can execute properly. The included files are:

-   app.R: the Shiny app itself, named as such by default
    -   Requires the data.table, dplyr, shiny, and shinyjs packages.
-   AppData.RData: the final dataset used, after all cleaning, joining, and subsetting has been performed; includes data from both Indeed.com and the BLS.
-   CensusCity2010.xlsx: data from the BLS recording the local cost of living for various cities in each of state in the US; collected once every 10 years as part of the census.
-   CleaningAndJoining.R: a script that converts the Datafest data into the data used for the app by excluding irrelevant columns, cleaning the data, joining the BLS data to the Datafest data, and performing necessary calculations.
    -   Requires the data.table, dplyr and readxl packages
-   factoredData.RData: the original dataset; modified by CleaningAndJoining (see above) to create the final dataset AppData (see above) used in the Shiny app.

<br> <br>
