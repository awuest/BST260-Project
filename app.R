
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
#NOTE - UPDATE SO ITS NOT JUST ON MY COMPUTER FOR FINAL SUBMISSION
city_total_data <- read_excel("./data/city_total_data.xlsx")
census_tract_total_data <- read_csv("./data/census_tract_total_data.csv")

#Wrangling for Race/Eth portion of Tab 1
# identify all metrics available w/ racial breakdown in data frame
race_vars <- names(city_total_data)[names(city_total_data) %>% str_detect("asian")] %>% str_replace("asian", "")
# identify specific col names that contain race metric
temp <- names(city_total_data)[names(city_total_data) %>% str_detect(str_c(race_vars, collapse="|"))] 
# filter out age/gender cols since some metrics available at race, as well as gender/age breakdown
race_cols <- temp[temp %>% str_detect("age|female|male", negate = TRUE)]  # final list of race related metric col names

race_dat <- city_total_data %>% select(append(append(race_cols,  "city_name"), "state_abbr")) %>% 
    pivot_longer(!c(city_name, state_abbr), 
                 names_to = "measure", values_to = "estimate") %>%
    mutate(measure = str_replace(measure, "total_population", "all")) %>%
    mutate(measure = stri_replace_last_fixed(measure, '_', " ")) %>%
    separate(measure, c("measure", "population"), sep = " ")

#Wrangling for Tab 2
city_total_data <- city_total_data %>% separate(geolocation, c("Latitude", "Longitude"), ", ") %>% 
    mutate(Longitude = str_remove(Longitude, "[\\)]")) %>% 
    mutate(Latitude = str_remove(Latitude, "[\\()]"))

usmappingdf <- city_total_data %>% mutate(AdjFacilities = (number_sites/population2010)*100000) %>% select(Longitude, Latitude, city_name, state_abbr, mammouse_adjprev, breast_cancer_deaths_total_population, AdjFacilities)

usmappingdf$Longitude <- as.numeric(as.character(usmappingdf$Longitude))
usmappingdf$Latitude <- as.numeric(as.character(usmappingdf$Latitude))

mappabletransformeddf <- usmap_transform(usmappingdf)

#Wrangling for Tab 3
census_tract_total_data_nyc <- census_tract_total_data %>%
    filter(state_abbr == "NY", city_name == "New York")

#UPDATE FIRST LINE FOR FINAL SUBMISSION
census_tracts <- st_read("./data/cb_2018_36_tract_500k/cb_2018_36_tract_500k.shp", quiet = TRUE)
colnames(census_tracts)[colnames(census_tracts) == "GEOID"] <- "tract_fips"
census_tract_total_data_nyc$tract_fips <- as.character(census_tract_total_data_nyc$tract_fips)
census_tracts_combined_data_nyc <- left_join(census_tracts, census_tract_total_data_nyc, by = "tract_fips")
census_tracts_subset_data_nyc <- census_tracts_combined_data_nyc %>%
    filter(state_abbr == "NY", city_name == "New York") %>% 
    rename("racial_ethnic_diversity_total_population" = `racial/ethnic_diversity_total_population`,
           "unemployment_annual_neighborhood_level_total_population" = `unemployment_annual_neighborhood-level_total_population`)

ui <- fluidPage(theme = shinytheme("lumen"),
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
                                             verbatimTextOutput(outputId = "ScatterClickInfo"),
                                             plotOutput(outputId = "BCVariableSelectorPlot",
                                                        click = clickOpts(id = "ScatterClickBCVar")
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
                                                                         "Low Birthweight" = "low_birthweight"
                                                          ))
                                      ),
                                      column(width = 8,
                                             plotOutput(outputId = "RaceEthPlot"))
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
                                        plotOutput(outputId = "RaceEthScatter"))
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
                                                 multiple = TRUE,
                                                 options = list(maxItems = 10)
                                             )
                                      ),
                                      column(width = 6,
                                             tableOutput(outputId = "city_info_table")
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
                                                                   "Prenatal Care" = "prenatal_care_total_population",
                                                                   "Low Birthweight in Population" = "low_birthweight_total_population",
                                                                   "Binge Drinking" = "binge_drinking_total_population"
                                                       ))
                                 ),
                                 column(width = 9,
                                        tmapOutput(outputId = "HeatMapOfVariableNYC"))
                             )
                             
                             
                    )
                )
                
)



source("map_plot_labels.R") # custom function for labeling plots/tables


server <- function(input, output) {
    
    
    #First tab scatterplot
    output$BCVariableSelectorPlot <- renderPlot({
        bc_labs = map_labels(input$BCVariable)
        BCLabel = bc_labs[1]
        BCCaption = bc_labs[2]
        
        var_labs = map_labels(input$VarSelection)
        VarLabel = var_labs[1]
        VarCaption = var_labs[2]
        
        city_total_data %>% 
            ggplot(aes_string(x=input$VarSelection, y=input$BCVariable)) + #aes_string since R stores user selections as a string
            geom_point() +
            labs(x = VarLabel, y = BCLabel, caption = sprintf("Units as follows: %s and %s", BCCaption, VarCaption)) + #reactive labels
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
        
        return(selected_df)
        
    })
    
    #This prints out the information based on what variables were selected by the user
    output$ScatterClickInfo <- renderPrint({
            city_click_info()    
        })
    
    #Tab 1 - race/eth section
    race_eth_df <- reactive(race_dat %>% filter(measure == input$RaceEthVariable))
    
    output$RaceEthPlot <- renderPlot({
        
        #Reactive labels and caption for units
        if (input$RaceEthVariable == "breast_cancer_deaths") {
            RaceYLabel = "Breast Cancer Deaths"
            RaceCaption = "Breast Cancer Deaths in females (per 100,000)"
        }
        else if (input$RaceEthVariable == "high_school_completion") {
            RaceYLabel = "High School Completion"
            RaceCaption = "Residents aged ≥25 with high school diploma, or equivalent, or higher degree (%)"
        }
        else if (input$RaceEthVariable == "limited_access_to_healthy_foods") {
            RaceYLabel = "Limited Access to Healthy Foods"
            RaceCaption = "Population living more than ½ mile from the nearest supermarket, supercenter, or large grocery store (%)"
        }
        else if (input$RaceEthVariable == "unemployment_annual_neighborhood_level") {
            RaceYLabel = "Unemployment at Neighborhood Level"
            RaceCaption = "Civilian labor force that is unemployed, by month (%)"
        }
        else if (input$RaceEthVariable == "uninsured") {
            RaceYLabel = "Uninsured Levels"
            RaceCaption = "Current lack of health insurance among people aged 0-64 years (%)"
        }
        else if (input$RaceEthVariable == "teen_births") {
            RaceYLabel = "Teen Birth Levels"
            RaceCaption = "Births to mothers aged 15-19 (per 1,000 females in that age group)"
        }
        else if (input$RaceEthVariable == "prenatal_care") {
            RaceYLabel = "Prenatal Care Levels"
            RaceCaption = "Births for which prenatal care began in the first trimester (%)"
        }
        else if (input$RaceEthVariable == "low_birthweight") {
            RaceYLabel = "Low Birthweight Levels"
            RaceCaption = "Live births with low birthweight <2500 grams (%)"
        }
        
        race_eth_df() %>% ggplot() +
            geom_violin(aes(x = population, y = estimate, fill = population), alpha = 0.5) +
            labs(x = "Racial/Ethnic Population", y = RaceYLabel, fill = "Population", caption = sprintf("Measure Info/Units: %s", RaceCaption)) +
            ggtitle(sprintf("Racial-Ethnic Breakdown of %s in US Cities", RaceYLabel))
    })
    
    #Reactive df for second race-eth plot
    race_eth_scatter_df <- reactive(race_dat %>% pivot_wider(id_cols = c(state_abbr, city_name, population),
                                                             names_from = measure,
                                                             values_from = estimate) %>%
                                        select(c("population", input$RaceEthScatterVar, "breast_cancer_deaths")) %>% drop_na())
    
    output$RaceEthScatter <- renderPlot({
        #Reactive labels and captions for units
        if (input$RaceEthScatterVar == "high_school_completion") {
            RaceEthScatterLabel = "High School Completion"
            RaceEthCaption = "Residents aged ≥25 with high school diploma, or equivalent, or higher degree (%)"
        }
        else if (input$RaceEthScatterVar == "limited_access_to_healthy_foods") {
            RaceEthScatterLabel = "Limited Access to Healthy Foods"
            RaceEthCaption = "Population living more than ½ mile from the nearest supermarket, supercenter, or large grocery store (%)"
        }
        else if (input$RaceEthScatterVar == "unemployment_annual_neighborhood_level") {
            RaceEthScatterLabel = "Unemployment at Neighborhood Level"
            RaceEthCaption = "Civilian labor force that is unemployed, by month (%)"
        }
        else if (input$RaceEthScatterVar == "uninsured") {
            RaceEthScatterLabel = "Uninsured Levels"
            RaceEthCaption = "Current lack of health insurance among people aged 0-64 years (%)"
        }
        else if (input$RaceEthScatterVar == "teen_births") {
            RaceEthScatterLabel = "Teen Birth Levels"
            RaceEthCaption = "Births to mothers aged 15-19 (per 1,000 females in that age group)"
        }
        else if (input$RaceEthScatterVar == "prenatal_care") {
            RaceEthScatterLabel = "Prenatal Care Levels"
            RaceEthCaption = "Births for which prenatal care began in the first trimester (%)"
        }
        else if (input$RaceEthScatterVar == "low_birthweight") {
            RaceEthScatterLabel = "Low Birthweight Levels"
            RaceEthCaption = "Live births with low birthweight <2500 grams (%)"
        }
        
        race_eth_scatter_df() %>% ggplot() + 
            geom_point(aes_string(x= input$RaceEthScatterVar, 
                                  y= "breast_cancer_deaths", 
                                  fill = "population", 
                                  color = "population"), alpha = .5)  +
            scale_y_sqrt() +
            scale_x_sqrt() + 
            ylab("Breast Cancer Deaths per 100K (sqrt scale)") +
            xlab(sprintf("%s (sqrt scale)", RaceEthScatterLabel)) +
            labs(fill = "Population", color = "Population", caption = sprintf("Measure Info/Units: %s", RaceEthCaption)) + #Capitalizing legend title
            ggtitle(sprintf("%s and Breast Cancer Deaths Across Race and Ethinicity Groups", RaceEthScatterLabel))
        
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
            BCLimit <- c(60, 85)
        }
        else if (input$BCM_or_Mammo == "breast_cancer_deaths_total_population") {
            BCLimit <- c(10, 55)
        }
        
        #This is the plot that allows users to select up to 10 cities to plot to compare measures
        plot_usmap() +
            geom_point(data = city_selected_df(),
                       aes_string(x = "Longitude.1",
                                  y = "Latitude.1",
                                  size = "AdjFacilities",
                                  color = input$BCM_or_Mammo),
                       alpha = 1) +
            scale_color_viridis_c(option = "viridis", direction = -1, limits = BCLimit) + #direction -1 reverses the order of the coloring so it goes lighter to darker
            theme(legend.position = "bottom") +
            labs(color = BCLabel, size = "Number of Facilities per 100,000 people")
    })
    
    #This table displays the statistics for the cities selected
    output$city_info_table <- renderTable(
        city_selected_df() %>% 
            select(city_name, state_abbr, AdjFacilities, mammouse_adjprev, breast_cancer_deaths_total_population) %>% 
            rename("City" = "city_name",
                   "State" = "state_abbr",
                   "Number of Facilities per 100,000 people" = "AdjFacilities",
                   "Mammography Use (%)" = "mammouse_adjprev",
                   "Breast Cancer Deaths per 100,000 women" = "breast_cancer_deaths_total_population")
    )
    
    #This is the overall national map that only reacts to the user selected BC variable
    output$NationalMap <- renderPlot({
        if (input$BCM_or_Mammo_National == "mammouse_adjprev") {
            BCLabelNat <- "Mammography Use"
        }
        else if (input$BCM_or_Mammo_National == "breast_cancer_deaths_total_population") {
            BCLabelNat <- "Breast Cancer Deaths"
        }
        
        plot_usmap() +
            geom_point(data = mappabletransformeddf, #uses the spatially-transformed df
                       aes_string(x = "Longitude.1", 
                                  y = "Latitude.1",
                                  size = "AdjFacilities", #size of dot reacts based on the number of facilities in that city
                                  color = input$BCM_or_Mammo_National), #reacts based on the input by the user
                       alpha = 0.5) + #used lower alpha level since there's some overlap with cities in certain states
            scale_color_viridis_c(option = "viridis", direction = -1) + #direction = -1 reverses the scale coloring so it goes light to dark
            theme(legend.position = "bottom") +
            labs(color = BCLabelNat, size = "Number of Facilities per 100,000 people")
    })
    
    #Tab 3 Heatmap - color is reactive based on variable selected
    output$HeatMapOfVariableNYC <- renderTmap({
        #reactive labelling
        if (input$VarSelectionHeatMap == "air_pollution_particulate_matter_total_population") {
            HeatMapLabel <- "Air Pollution Level"
        }
        else if (input$VarSelectionHeatMap == "mammouse_crudeprev") {
            HeatMapLabel <- "Mammography Use"
        }
        else if (input$VarSelectionHeatMap == "diabetes_total_population") {
            HeatMapLabel <- "Diabetes Rate"
        }
        else if (input$VarSelectionHeatMap == "binge_drinking_total_population") {
            HeatMapLabel <- "Binge Drinking"
        }
        else if (input$VarSelectionHeatMap == "frequent_mental_distress_total_population") {
            HeatMapLabel <- "Frequent Mental Distress in Population"
        }
        else if (input$VarSelectionHeatMap == "frequent_physical_distress_total_population") {
            HeatMapLabel <- "Frequent Physical Distress in Population"
        }
        else if (input$VarSelectionHeatMap == "high_school_completion_total_population") {
            HeatMapLabel <- "High School Completion Rates"
        }
        else if (input$VarSelectionHeatMap == "housing_with_potential_lead_risk_total_population") {
            HeatMapLabel <- "Housing with Potential Lead Risk"
        }
        else if (input$VarSelectionHeatMap == "income_inequality_total_population") {
            HeatMapLabel <- "Income Inequality"
        }
        else if (input$VarSelectionHeatMap == "limited_access_to_healthy_foods_total_population") {
            HeatMapLabel <- "Limited Access to Healthy Foods"
        }
        else if (input$VarSelectionHeatMap == "obesity_total_population") {
            HeatMapLabel <- "Obesity Rate"
        }
        else if (input$VarSelectionHeatMap == "racialethnic_diversity_total_population") {
            HeatMapLabel <- "Racial/Ethnic Diversity in Population"
        }
        else if (input$VarSelectionHeatMap == "smoking_total_population") {
            HeatMapLabel <- "Smoking Rate"
        }
        else if (input$VarSelectionHeatMap == "unemployment_annual_neighborhood_level_total_population") {
            HeatMapLabel <- "Unemployment Rate"
        }
        else if (input$VarSelectionHeatMap == "uninsured_total_population") {
            HeatMapLabel <- "Uninsured Rate"
        }
        else if (input$VarSelectionHeatMap == "prenatal_care_total_population") {
            HeatMapLabel <- "Prenatal Care Use"
        }
        else if (input$VarSelectionHeatMap == "low_birthweight_total_population") {
            HeatMapLabel <- "Low Birthweight in Population"
        }
        
        #reactive coloring based on the variable selected
        tm_shape(census_tracts_subset_data_nyc) + tm_fill(col = input$VarSelectionHeatMap, colorNA = "light gray", 
                                                          palette = "Greens", title = "% of total population") + 
            tm_legend(outside = TRUE, main.title = sprintf("Prevalence of %s in NYC", HeatMapLabel))
    })
}



shinyApp(ui = ui, server = server)