# U.S. Trends in Breast Cancer Screening & Mortality

#### BST260 Final Project 
#### Authors: Anna Wuest, Colleen McGrath, Dougie Zubizarreta, Rowana Ahmed


We are motivated by the well-documented racial/ethnic and socioeconomic disparities in breast cancer screening, treatment, and outcomes. We are interested in identifying specific subgroups and geographic areas that may experience barriers to breast cancer screening and disparities in breast cancer mortality. 



The goals of our project are the following: 

* At the city level for all 500 cities featured in the 500 Cities Project, we are interested in conducting an in-depth exploration of mammography use and breast cancer mortality rates as well as facilities offering mammography services.

* At the national and census tract level (within the city of New York), we are interested in examining potential social and structural determinants of mammography use by examining its relationship with factors such as obesity, diabetes, insurance status, income inequality, racial/ethnic diversity, % high school completion and so on. 

Additional info can be found on our [website](https://sites.google.com/view/bst260project-group1/home) or by viewing our [screencast](https://www.youtube.com/watch?v=vy-moLAHpOY&feature=emb_logo).

### 1. Key Files in Repository

The summary file for the project is **project_overview** (html/.Rmd). This
file also has links to supplemental htmls, which includes more detailed 
analysis.

Supplemental Files (html/.Rmd):

* data_cleanup [primary location for data wrangling/aggregation]
* city_level_analysis [national level analysis across all U.S. cities]
* nyc_level_analysis [NYC focused analysis at census tract level]
* NYC_facilities [mapping visualization code for NYC facilities]

### 2. RShiny app

In addition to the analysis presented in the Project Overview file and the website, we have created an analytics tool to help users explore national and NYC level trends in breast cancer mortality & mammography usage. We hope this tool can help users delve deep into the data and explore various associations between metrics of interest. The RShiny app can be launched by running the **app.R** file.

The RShiny app depends on the map_plot_labels.R file to map the units & axes/table
labels. Please refer to Section 3 if you're unable to access the data needed to launch the app.

### 3. Data Sources:
There are two ways to access the source data used in this project:

  * Data is available in this repository in the ./data directory 
if git LFS is installed on your machine. (The < git lfs pull > command should allow you to access the files housed in the data folder)
  
  * Otherwise, the data can also be accessed on Dropbox using this link: https://www.dropbox.com/sh/8qbku2qxk85f31x/AABfbUPHavzU_A4215AxAVqHa?dl=0.
You will need to copy the data folder (replacing the existing one) into the directory for this repository to
run the Shiny app and execute the RMD files. 

Raw data files include:

* mammography_facilities.csv
* 500_Cities__censustract.csv
* 500_Cities__City.csv
* CHDB_data_city_allv10_1.csv
* CHDB_data_tract_allv10.1.csv

Cleaned data files include:
  
* city_total_data.xlsx
* census_tract_total_data.csv
* mammography_facilities_nyc_latlong.csv

GIS files for mapping visuals include:

* 2010 Census Tracts/2010 Census Tracts/geo_export_afcfe2e2-6376-4d66-b290-605e0ac77ee5.shp 
* cb_2018_36_tract_500k/cb_2018_36_tract_500k.shp  
