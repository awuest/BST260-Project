# config file for custom figure and table labels in Shiny app

map_labels <- function(var){
  
  case_when(
    var == "mammouse_adjprev" ~ c(
      BCLabel = "Mammography Use",
      BCCaption = "Mammography use among women aged 50-74 years (%)"
        ),
    var %in% c("breast_cancer_deaths_total_population",  "breast_cancer_deaths") ~ c(
      BCLabel ="Breast Cancer Deaths",
      BCCaption = "Breast Cancer Deaths in females (per 100,000)"
        ),
    var == "air_pollution_particulate_matter_total_population" ~ c(
      VarLabel = "Air Pollution Level",
      VarCaption = "Average daily concentration of fine particulate matter (PM2.5) per cubic meter (average)"
        ),
    var == "diabetes_total_population" ~ c(
      VarLabel = "Diabetes Rate",
      VarCaption <- "Diabetes among adults aged ≥18 years (%)"
        ),
    
    var %in% c("teen_births_total_population", "teen_births") ~ c( 
          VarLabel = "Teen Births",
          VarCaption = "Births to mothers aged 15-19 (per 1,000 females in that age group)"
        ),
    
    var == "binge_drinking_total_population"~ c( 
          VarLabel = "Binge Drinking",
          VarCaption = "Binge drinking among adults aged ≥ 18 years (%)"
        ),
    var == "walkability_total_population"~ c( 
          VarLabel = "Walkability",
          VarCaption = "Neighborhood amenities accessible by walking as calculated by Walk Score (index) "
        ),
    var == "frequent_mental_distress_total_population"~ c(
      VarLabel = "Frequent Mental Distress in Population",
      VarCaption = "Mental health not good for ≥14 days during the past 30 days among adults aged ≥18 years (%)"
       ),
    var == "frequent_physical_distress_total_population"~ c(
      VarLabel = "Frequent Physical Distress in Population",
      VarCaption = "Physical health not good for ≥14 days during the past 30 days among adults aged ≥18 years (%)" 
       ),
   var %in% c("high_school_completion_total_population",
              "high_school_completion") ~ c(
     VarLabel = "High School Completion Rates",
     VarCaption = "Residents aged ≥25 with high school diploma, or equivalent, or higher degree (%)"
      ),
  var == "housing_with_potential_lead_risk_total_population"~ c(
    VarLabel = "Housing with Potential Lead Risk",
    VarCaption = "Housing stock with potential elevated lead risk (%)"
     ),
  var == "income_inequality_total_population"~ c(
    VarLabel = "Income Inequality",
    VarCaption = "Households with income at the extremes of the national income distribution (the top 20% or bottom 20%) (index)"
    ),
  var %in% c("limited_access_to_healthy_foods_total_population",
             "limited_access_to_healthy_foods") ~ c(
    VarLabel = "Limited Access to Healthy Foods",
    VarCaption = "Population living more than ½ mile from the nearest supermarket, supercenter, or large grocery store (%)"
    ),
  var == "obesity_total_population"~ c(
    VarLabel = "Obesity Rate",
    VarCaption = "Obesity among adults aged ≥18 years (%)"
  ),
  var == "racialethnic_diversity_total_population"~ c(
    VarLabel = "Racial/Ethnic Diversity in Population",
    VarCaption = "Distribution of the population by race/ethnic group within a city or census tract (index)"
  ),
  var == "smoking_total_population"~ c(
    VarLabel = "Smoking Rate",
    VarCaption = "Current smoking among adults aged ≥18 years (%)"
  ),
  var %in% c("unemployment_annual_neighborhood_level_total_population",
             "unemployment_annual_neighborhood_level")~ c(
    VarLabel = "Unemployment",
    VarCaption = "Civilian labor force that is unemployed, by month (%)"
  ),
  var == "unemployment_annual_neighborhood_level_total_population"~ c(
    VarLabel = "Unemployment",
    VarCaption = "Civilian labor force that is unemployed, by month (%)"
  ),
  var %in% c("prenatal_care_total_population", "prenatal_care")~ c(
    VarLabel = "Prenatal Care Use",
    VarCaption = "Births for which prenatal care began in the first trimester (%)"
  ), 
  var %in% c("low_birthweight_total_population", "low_birthweight")~ c(
    VarLabel = "Low Birthweight",
    VarCaption = "Live births with low birthweight <2500 grams (%)"
  ),
  var == "uninsured" ~ c(
    VarLabel = "Uninsured Levels",
    VarCaption = "Current lack of health insurance among people aged 0-64 years (%)"
  )
)
  
}  
  

