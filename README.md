# BST260 Final Project: Trends in Breast Cancer Screening & Mortality

#### Authors: Anna Wuest, Colleen McGarth, Dougie Zubizarreta, Rowana Ahmed

Project Website: <>

### 1. Key Files in Repository

The summary file for the project is **project_overview** (html/.Rmd). This
file also has links to supplemental htmls, which includes more detailed 
analysis.

Supplemental Files (html/.Rmd):

* data_cleanup [primary location for data wrangling/aggregation]
* city_level_analysis [national level analysis across all U.S. cities]
* NYC_facilities [mapping visualization code for NYC facilities]

### 2. RShiny app

In addition to the analysis presented in the Project Overview file and the website, we have created an analytics tool to help users explore national and NYC level trends in breast cancer mortality & mammography usage. We hope this tool can help users delve deep into the data and explore various associations between metrics of interest. The Rshiny app can be launched by running the **app.R** file.

### 3. Data Sources:
There are two ways to access the source data used in this project:

  * Data is available in this repository if git LFS is installed on your   machine. (The git lfs pull command should allow you to access the component files of the data folder)
  
  * Otherwise, the data can also be accessed on Dropbox using this link: https://www.dropbox.com/sh/8qbku2qxk85f31x/AABfbUPHavzU_A4215AxAVqHa?dl=0

Raw data files include:

* mammography_facilities.csv
* 500_Cities__censustract.csv
* 500_Cities__City.csv
* CHDB_data_city_allv10_1.csv
* CHDB_data_tract_allv10.1.csv
* 2010 Census Tracts/2010 Census Tracts/geo_export_afcfe2e2-6376-4d66-b290-605e0ac77ee5.shp 

Cleaned data files include:
  
* city_total_data.xlsx
* census_tract_total_data.csv
* mammography_facilities_nyc_latlong.csv
  
