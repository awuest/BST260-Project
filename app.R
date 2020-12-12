
library(shiny)
library(ggplot2)
library(dplyr)
library(usmap)
library(stringr)
library(stringi)
library(tidyverse)
library(maptools)
library(readxl)
library(shinythemes)
library(sf)
library(tmap)

#Read in data and wrangle a bit
city_total_data <- read_excel("./data/city_total_data.xlsx")
census_tract_total_data <- read_csv("./data/census_tract_total_data.csv")

#Wrangling for Race/Eth portion of Tab 1
# identify all metrics available w/ racial breakdown in data frame
race_vars <- names(city_total_data)[names(city_total_data) %>% str_detect("asian")] %>% str_replace("asian", "")
# identify specific col names that contain race metric
temp <- names(city_total_data)[names(city_total_data) %>% str_detect(str_c(race_vars, collapse="|"))] 
# filter out age/gender cols since some metrics available at race, as well as gender/age breakdown
race_cols <- temp[temp %>% str_detect("age|female|male", negate = TRUE)]  # final list of race related metric col names

#selecting race columns from above and formatting to long format
race_dat <- city_total_data %>% select(append(append(race_cols,  "city_name"), "state_abbr")) %>% 
    pivot_longer(!c(city_name, state_abbr), 
                 names_to = "measure", values_to = "estimate") %>%
    mutate(measure = str_replace(measure, "total_population", "all")) %>%
    mutate(measure = stri_replace_last_fixed(measure, '_', " ")) %>%
    separate(measure, c("measure", "population"), sep = " ") %>% 
    mutate(population = str_to_title(population))

#Wrangling for Tab 2
city_total_data <- city_total_data %>% separate(geolocation, c("Latitude", "Longitude"), ", ") %>% #Separates the geolocation data at the comma between the long/lat and makes two separate columns
    mutate(Longitude = str_remove(Longitude, "[\\)]")) %>% #String processing necessary to remove the parentheses from the original geolocation formatting
    mutate(Latitude = str_remove(Latitude, "[\\()]"))

#New dataframe that will be used for mapping selecting only the variables that will be used in the mapping part of the app; in addition, facilities variable is adjusted for each city's population
usmappingdf <- city_total_data %>% mutate(AdjFacilities = (number_sites/population2010)*100000) %>% select(Longitude, Latitude, city_name, state_abbr, mammouse_adjprev, breast_cancer_deaths_total_population, AdjFacilities)

#The transform function requires numeric values and the previous string processing store the long/lat as strings
usmappingdf$Longitude <- as.numeric(as.character(usmappingdf$Longitude))
usmappingdf$Latitude <- as.numeric(as.character(usmappingdf$Latitude))

mappabletransformeddf <- usmap_transform(usmappingdf)

#Wrangling for Tab 3
census_tract_total_data_nyc <- census_tract_total_data %>%
    filter(state_abbr == "NY", city_name == "New York")

census_tracts <- st_read("./data/cb_2018_36_tract_500k/cb_2018_36_tract_500k.shp", quiet = TRUE)
colnames(census_tracts)[colnames(census_tracts) == "GEOID"] <- "tract_fips"
census_tract_total_data_nyc$tract_fips <- as.character(census_tract_total_data_nyc$tract_fips)
census_tracts_combined_data_nyc <- left_join(census_tracts, census_tract_total_data_nyc, by = "tract_fips")
census_tracts_subset_data_nyc <- census_tracts_combined_data_nyc %>%
    filter(state_abbr == "NY", city_name == "New York") %>% #needs to be filtered again
    rename("racial_ethnic_diversity_total_population" = `racial/ethnic_diversity_total_population`,
           "unemployment_annual_neighborhood_level_total_population" = `unemployment_annual_neighborhood-level_total_population`) #renamed for ease of use

ui <- fluidPage(theme = shinytheme("flatly"),
                titlePanel("Demographic and Health-Related Trends in 500 US Cities and Relation to  Mammography and Breast Cancer Mortality "),
                
                #First tab - variable of choice comparison + racial-ethnic
                tabsetPanel(
                    tabPanel("National Trends",
                             p("In the first section, users may select demographic, health-related, and other variables of interest to compare with trends in breast cancer screening and mortality. On the plot, users may click on a point to find the name of that city and the raw data values.
                               In the second section, users may select certain demographic or health-related variables to visualize the breakdown across 500 US cities. Understanding these breakdowns is imperative to fully conceptualizing the trends we see in the first plots related to breast cancer variables."),
                             fluidRow(h2("Breast Cancer Screening and Death Trends Across Demographic and Health-Related Variables"),
                                      column(width = 4,
                                             radioButtons(inputId = "BCVariable",
                                                          label = "Choose a variable:",
                                                          choices = list("Mammography Use" = "mammouse_adjprev",
                                                                         "Breast Cancer Deaths" = "breast_cancer_deaths_total_population")),
                                             selectizeInput(inputId = "VarSelection",
                                                            label = "Choose another variable:",
                                                            choices = c("Air Pollution Levels" = "air_pollution_particulate_matter_total_population",
                                                                        "Diabetes Rate" = "diabetes_total_population",
                                                                        "Teen Births" = "teen_births_total_population",
                                                                        "Binge Drinking" = "binge_drinking_total_population",
                                                                        "Walkability" = "walkability_total_population",
                                                                        "Frequent Mental Distress in Population" = "frequent_mental_distress_total_population",
                                                                        "Frequent Physical Distress in Population" = "frequent_physical_distress_total_population",
                                                                        "High School Completion Rates" = "high_school_completion_total_population",
                                                                        "Housing with Potential Lead Risk" = "housing_with_potential_lead_risk_total_population",
                                                                        "Income Inequality" = "income_inequality_total_population",
                                                                        "Limited Access to Healthy Foods" = "limited_access_to_healthy_foods_total_population",
                                                                        "Obesity Rate" = "obesity_total_population",
                                                                        "Racial/Ethnic Diversity in Population" = "racial_ethnic_diversity_total_population",
                                                                        "Smoking Rate" = "smoking_total_population",
                                                                        "Unemployment Rate" = "unemployment_annual_neighborhood_level_total_population",
                                                                        "Uninsured Rate" = "uninsured_total_population",
                                                                        "Prenatal Care" = "prenatal_care_total_population",
                                                                        "Low Birthweight in Population" = "low_birthweight_total_population"))
                                             
                                      ),
                                      column(width = 8,
                                             tableOutput(outputId = "ScatterClickInfo"), #output for the below click feature
                                             plotOutput(outputId = "BCVariableSelectorPlot",
                                                        click = clickOpts(id = "ScatterClickBCVar") #this allows users to click on a point in the scatterplot and return a tibble with the values corresponding to that point (i.e. find out the city that point corresponds to)
                                             )
                                      )
                             ),
                             fluidRow(h2("Racial-Ethnic Trends Across 500 U.S. Cities"),
                                      column(width = 4,
                                             radioButtons(inputId = "RaceEthVariable",
                                                          label = "Choose a variable:",
                                                          choices = list("Breast Cancer Deaths" = "breast_cancer_deaths",
                                                                         "High School Completion" = "high_school_completion",
                                                                         "Limited Access to Healthy Foods" = "limited_access_to_healthy_foods",
                                                                         "Unemployment Levels" = "unemployment_annual_neighborhood_level",
                                                                         "Uninsured Levels" = "uninsured",
                                                                         "Teen Births" = "teen_births",
                                                                         "Prenatal Care" = "prenatal_care",
                                                                         "Low Birthweight" = "low_birthweight" #these are the variables that have racial-ethnic breakdowns available
                                                          ))
                                      ),
                                      column(width = 8,
                                             plotOutput(outputId = "RaceEthPlot")) #violin plot
                             ),
                             fluidRow(
                                 column(width = 4,
                                        radioButtons(inputId = "RaceEthScatterVar",
                                                     label = "Choose a variable:",
                                                     choices = list("High School Completion" = "high_school_completion",
                                                                    "Limited Access to Healthy Foods" = "limited_access_to_healthy_foods",
                                                                    "Unemployment Levels" = "unemployment_annual_neighborhood_level",
                                                                    "Uninsured Levels" = "uninsured",
                                                                    "Teen Births" = "teen_births",
                                                                    "Prenatal Care" = "prenatal_care",
                                                                    "Low Birthweight" = "low_birthweight"))
                                 ),
                                 column(width = 8,
                                        plotOutput(outputId = "RaceEthScatter")) #scatterplot with breast cancer mortality correlated to the above-selected variable
                             )
                    ),
                    
                    #Second tab - national map
                    tabPanel("Breast Cancer Screening and Mortality Trends from a National Perspective",
                             p("Users may explore breast cancer screening and death trends across 500 cities in the United States against the number of facilities offering mammography services in that city.
                               In the first section, users may select a breast cancer variable of interest and visualize the impact of that variable against the number of facilities offering mammography services in each city. The number of facilities in that city is adjusted based on the population of that city.
                               In the second section, users may select up to 10 cities to plot alone in order to make closer comparisons between areas of interest."),
                             fluidRow(h2("National Look"),
                                      column(width = 3,
                                             radioButtons(inputId = "BCM_or_Mammo_National",
                                                          label = "Select a variable:",
                                                          choices = list("Mammography Use" = "mammouse_adjprev",
                                                                         "Breast Cancer Deaths" = "breast_cancer_deaths_total_population"))),
                                      column(width = 9,
                                             plotOutput(outputId = "NationalMap"))
                                      
                             ),
                             fluidRow(h2("City Selection"),
                                      column(width = 3,
                                             radioButtons(inputId = "BCM_or_Mammo",
                                                          label = "Select a variable:",
                                                          choices = list("Mammography Use" = "mammouse_adjprev",
                                                                         "Breast Cancer Deaths" = "breast_cancer_deaths_total_population"))
                                      ),
                                      column(width = 3,
                                             selectizeInput(
                                                 inputId = "city_selection",
                                                 label = "Select cities to map (max 10):",
                                                 choices = mappabletransformeddf$city_name,
                                                 multiple = TRUE, #allows users to select multiple cities to plot
                                                 options = list(maxItems = 10)
                                             )
                                      ),
                                      column(width = 6,
                                             tableOutput(outputId = "city_info_table") #this table will output the information for the selected cities
                                      )
                             ),
                             fluidRow(
                                 column(width = 12,
                                        plotOutput(outputId = "NationalMapPerCity"))
                             )),
                    
                    #Third tab - NYC specific heatmaps
                    tabPanel("New York City Trends",
                             p("Users may explore explore the trends of a variety of demographic, socioeconomic, and individual health factors specific to New York City individuals. Select a variable to produce a plot of the prevalence of that variable broken into census tracts with New York City.
                               An understanding of the census-tract breakdown of these variables is imperative to fully contextualizing the breast cancer trends we have seen in this application and in the analyses produced throughout this project."),
                             fluidRow(
                                 column(width = 3,
                                        selectizeInput(inputId = "VarSelectionHeatMap",
                                                       label = "Choose a variable:",
                                                       choices = c("Mammography Use" = "mammouse_crudeprev",
                                                                   "Air Pollution Levels" = "air_pollution_particulate_matter_total_population",
                                                                   "Diabetes Rate" = "diabetes_total_population",
                                                                   "Frequent Mental Distress in Population" = "frequent_mental_distress_total_population",
                                                                   "Frequent Physical Distress in Population" = "frequent_physical_distress_total_population",
                                                                   "High School Completion Rates" = "high_school_completion_total_population",
                                                                   "Housing with Potential Lead Risk" = "housing_with_potential_lead_risk_total_population",
                                                                   "Income Inequality" = "income_inequality_total_population",
                                                                   "Limited Access to Healthy Foods" = "limited_access_to_healthy_foods_total_population",
                                                                   "Obesity Rate" = "obesity_total_population",
                                                                   "Racial/Ethnic Diversity in Population" = "racial_ethnic_diversity_total_population",
                                                                   "Smoking Rate" = "smoking_total_population",
                                                                   "Unemployment Rate" = "unemployment_annual_neighborhood_level_total_population",
                                                                   "Uninsured Rate" = "uninsured_total_population",
                                                                   "Binge Drinking" = "binge_drinking_total_population"
                                                       ))
                                 ),
                                 column(width = 9,
                                        tmapOutput(outputId = "HeatMapOfVariableNYC"))
                             )
                             
                             
                    )
                )
                
)



source("map_plot_labels.R") #custom function for labeling plots/tables


server <- function(input, output) {
    
    
    #First tab scatterplot for all 500 ciites, non-stratified by race
    output$BCVariableSelectorPlot <- renderPlot({
        #reactive labels for axes and captions taken from function file
        bc_labs = map_labels(input$BCVariable)
        BCLabel = bc_labs[1] #selects first label from appropriate variable match based on user selection
        BCCaption = bc_labs[2] #selects second label from list for appropriate variable match based on user selection
        
        var_labs = map_labels(input$VarSelection)
        VarLabel = var_labs[1]
        VarCaption = var_labs[2]
        
        city_total_data %>% 
            ggplot(aes_string(x=input$VarSelection, y=input$BCVariable)) + #aes_string since R stores user selections as a string
            geom_point() +
            labs(x = VarLabel, y = BCLabel, caption = sprintf("Units as follows: %s and %s", BCCaption, VarCaption)) + #reactive labels and caption for metric info
            ggtitle(sprintf("%s and %s in 500 US Cities", BCLabel, VarLabel)) + #reactive plot title based on variables selected
            theme_bw()
    })
    
    city_click_info <- reactive({
        
        BCLabel = map_labels(input$BCVariable)[1]
        VarLabel = map_labels(input$VarSelection)[1]

        selected_df <- city_total_data %>% 
                select(city_name, state_abbr, input$BCVariable, input$VarSelection) %>%
                nearPoints(input$ScatterClickBCVar,
                           threshold = 2) #Limits the distance from the click that it will pick up points to display
 
        
        names(selected_df) = c("City", "State", BCLabel, VarLabel)
        #This prints out the information based on what variables were selected by the user
        return(selected_df)
        
    })
    
    #This prints out the information based on what variables were selected by the user
    output$ScatterClickInfo <- renderTable({
            city_click_info()    
        })
    
    #Tab 1 - race/eth section
    race_eth_df <- reactive(race_dat %>% filter(measure == input$RaceEthVariable)) #so that we are only looking at the selected measure in the plot
    
    output$RaceEthPlot <- renderPlot({
        
        
        # #Reactive labels and caption for units
        RaceYLabel = map_labels(input$RaceEthVariable)[1]
        RaceCaption = map_labels(input$RaceEthVariable)[2]
   
        race_eth_df() %>% ggplot() +
            geom_violin(aes(x = population, y = estimate, fill = population), alpha = 0.5) +
            labs(x = "Racial/Ethnic Population", y = RaceYLabel, fill = "Population", caption = sprintf("Measure Info/Units: %s", RaceCaption)) + #reactive label and caption
            ggtitle(sprintf("Racial-Ethnic Breakdown of %s in US Cities", RaceYLabel)) #reactive title
    })
    
    #Reactive df for second race-eth plot
    race_eth_scatter_df <- reactive(race_dat %>% pivot_wider(id_cols = c(state_abbr, city_name, population),
                                                             names_from = measure,
                                                             values_from = estimate) %>%
                                        select(c("population", input$RaceEthScatterVar, "breast_cancer_deaths")) %>% drop_na()) #so that we are only using the race ("population"), selected variable, and BC deaths
    
    output$RaceEthScatter <- renderPlot({
        # #Reactive labels and captions for units
        RaceEthScatterLabel = map_labels(input$RaceEthScatterVar)[1]
        RaceEthCaption  = map_labels(input$RaceEthScatterVar)[2]
        
        race_eth_scatter_df() %>% ggplot() + 
            geom_point(aes_string(x= input$RaceEthScatterVar, #aes_string since Shiny stores the selections as strings
                                  y= "breast_cancer_deaths", 
                                  fill = "population", 
                                  color = "population"), alpha = .5)  +
            scale_y_sqrt() + #scale transformations for better visualization
            scale_x_sqrt() + #scale transformations for better visualization
            ylab("Breast Cancer Deaths per 100K (sqrt scale)") +
            xlab(sprintf("%s (sqrt scale)", RaceEthScatterLabel)) +
            labs(fill = "Population", color = "Population", caption = sprintf("Measure Info/Units: %s", RaceEthCaption)) + #Capitalizing legend title + reactive caption for metric info
            ggtitle(sprintf("%s and Breast Cancer Deaths Across Race and Ethinicity Groups", RaceEthScatterLabel)) #reactive title
        
    })
    
    #Tab 2 - this is a reactive dataframe based on the 1-10 cities selected by the user to display
    city_selected_df <- reactive(mappabletransformeddf %>% 
                                     group_by(city_name) %>% 
                                     filter(city_name %in% input$city_selection))
    
    #Tab 2 plot - this is the second plot on the tab
    output$NationalMapPerCity <- renderPlot({
        #Reactive Labels for the color scale
        if (input$BCM_or_Mammo == "mammouse_adjprev") {
            BCLabel <- "Mammography Use"
        }
        else if (input$BCM_or_Mammo == "breast_cancer_deaths_total_population") {
            BCLabel <- "Breast Cancer Deaths"
        }
        
        #Reactive scale limits based on measure chosen so that it will be consistent across cities chosen
        if (input$BCM_or_Mammo == "mammouse_adjprev") {
            BCLimit <- c(60, 85) #range to encompass largest and smallest values
        }
        else if (input$BCM_or_Mammo == "breast_cancer_deaths_total_population") {
            BCLimit <- c(10, 55) #range to encompass largest and smallest values
        }
        
        #This is the plot that allows users to select ~10 cities to plot to compare measures
        plot_usmap() +
            geom_point(data = city_selected_df(), #reactive df used
                       aes_string(x = "Longitude.1", #these are spatially transformed coordinates
                                  y = "Latitude.1",
                                  size = "AdjFacilities", #dot changes size according to number of mammo facilites per population size
                                  color = input$BCM_or_Mammo), #color changes according to continous scale
                       alpha = 1) +
            scale_color_viridis_c(option = "viridis", direction = -1, limits = BCLimit) + #direction -1 reverses the order of the coloring so it goes lighter to darker
            theme(legend.position = "bottom") +
            labs(color = BCLabel, size = "Number of Facilities per 100,000 people")
    })
    
    #This table displays the statistics for the cities selected
    output$city_info_table <- renderTable(
        city_selected_df() %>% #reactive df used
            select(city_name, state_abbr, AdjFacilities, mammouse_adjprev, breast_cancer_deaths_total_population) %>% #only want to report these
            rename("City" = "city_name",
                   "State" = "state_abbr",
                   "Number of Facilities per 100,000 people" = "AdjFacilities",
                   "Mammography Use (%)" = "mammouse_adjprev",
                   "Breast Cancer Deaths per 100,000 women" = "breast_cancer_deaths_total_population")
    )
    
    #This is the overall national map that only reacts to the user selected BC variable
    output$NationalMap <- renderPlot({
        #reactive labels
        if (input$BCM_or_Mammo_National == "mammouse_adjprev") {
            BCLabelNat <- "Mammography Use"
        }
        else if (input$BCM_or_Mammo_National == "breast_cancer_deaths_total_population") {
            BCLabelNat <- "Breast Cancer Deaths"
        }
        
        plot_usmap() +
            geom_point(data = mappabletransformeddf, #uses the spatially-transformed df
                       aes_string(x = "Longitude.1", #spatially-transformed coordinates from usmaptransform function
                                  y = "Latitude.1",
                                  size = "AdjFacilities", #size of dot reacts based on the number of facilities in that city
                                  color = input$BCM_or_Mammo_National), #reacts based on the input by the user
                       alpha = 0.5) + #used lower alpha level since there's some overlap with cities in certain states
            scale_color_viridis_c(option = "viridis", direction = -1) + #direction = -1 reverses the scale coloring so it goes light to dark
            theme(legend.position = "bottom") +
            labs(color = BCLabelNat, size = "Number of Facilities per 100,000 people")
    })
    
    #Tab 3 Heatmap - color is reactive based on variable selected
    output$HeatMapOfVariableNYC <- renderTmap({ #tmap is the type of plot used for these census tract data
        #reactive labelling
        HeatMapLabel = map_labels(input$VarSelectionHeatMap)[1]
        
        #reactive coloring based on the variable selected
        tm_shape(census_tracts_subset_data_nyc) + 
        tm_fill(col = input$VarSelectionHeatMap, colorNA = "light gray", 
                 palette = "Greens", title = "% of total population") + 
        tm_legend(outside = TRUE, main.title = sprintf("Prevalence of %s in NYC", 
                                                       HeatMapLabel)) 
    })
}



shinyApp(ui = ui, server = server)
