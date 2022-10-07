#### Exploratory Data Analysis (EDA) on a data frame related to CSR reports from companies.

install.packages("openxlsx")
library("openxlsx")
install.packages("xlsx")
library("xlsx")
install.packages(c("readxl","writexl")) 
library(readxl)
library(writexl)
install.packages("dplyr")
library(dplyr)
install.packages("tidyr")
library(tidyr)
install.packages("ggplot2")
library(ggplot2)


#The the file.choose() function in R to bring up a file explorer window that allows 
#you to interactively choose a file path to work with.

filedirectory <- file.choose()
data1<-openxlsx::read.xlsx(filedirectory)

#Create our primer Dataframe.
data1

#Trying to Pivot the data for to be able to create a Line chart 
Table1 <- data1%>%group_by(Publication.Year,Region)%>% summarize(
  Name = n()
)
#Use pivot function to create a wide range data.
Table2<- Table1 %>% pivot_wider(names_from = Region,values_from = Name)

#Fix Name space issues that might come up
names(Table2)<-gsub("\\s&","_",names(Table2))
colnames(Table2)[6] <- "Latin_America"
colnames(Table2)[4] <- "Northern_America"
Table2

#Turn NA values to 0
Table2[is.na(Table2)] <- 0
Table2<- Table2%>%
  rowwise()%>%
  mutate(Total = sum(c_across(where(is.numeric))))

#Remove the 2018 year as an outlier as there were too little data for that year
Table2<- Table2[!(Table2$Publication.Year ==2018),] 

#Create a Line Chart for the development of the Number of Reports 
#Historical development of CSR submitted files per region & total view of the trend.
ggplot(data=Table2,mapping = aes(x=Publication.Year))+
  geom_line(mapping = aes(y=Asia,group =1, color="Asia"))+
  geom_point(mapping = aes(y=Asia,group =1,color="Asia"))+
  geom_line(mapping = aes(y=Europe,group =1,color="Europe"))+
  geom_point(mapping = aes(y=Europe,group =1,color="Europe"))+
  geom_line(mapping = aes(y=Northern_America,group =1,color="Northern_America"))+
  geom_point(mapping = aes(y=Northern_America,group =1,color="Northern_America"))+
  geom_line(mapping = aes(y=Africa,group =1,color="Africa"))+
  geom_point(mapping = aes(y=Africa,group =1,color="Africa"))+
  geom_line(mapping = aes(y=Oceania,group =1,color="Oceania"))+
  geom_point(mapping = aes(y=Oceania,group =1,color="Oceania"))+
  geom_line(mapping = aes(y=Latin_America,group =1,color="Latin_America"))+
  geom_point(mapping = aes(y=Latin_America,group =1,color="Latin_America"))+
  geom_line(mapping = aes(y=Total,group =1,color="All Regions"))+
  geom_point(mapping = aes(y=Total,group =1,color="All Regions"))+
  theme_bw()+
  theme(legend.position = "bottom")+
  labs(x="Year",y="Number of Reports")

#### Creating a map plot with the amount of submitted files
#Map Plot of the the countries that have submitted CSR files through whole period.

install.packages("tidyverse")
#insert map data data frame so we can create the map plot
mapdata<- map_data("world")

Table3 <- data1%>%group_by(Country)%>% summarize(Name = n())

colnames(Table3)[colnames(Table3)=="Country"]<-"region"

#change the naming of some of the counties in our data frame to mach the map data data frame 
Table3$region <- replace(Table3$region, Table3$region=="United States of America", "USA")
Table3$region <- replace(Table3$region, Table3$region=="Mainland China", "China")
Table3$region <- replace(Table3$region, Table3$region=="Hong Kong", "China")
Table3$region <- replace(Table3$region, Table3$region=="United Kingdom of Great Britain and Northern Ireland", "UK")
Table3$region <- replace(Table3$region, Table3$region=="United Republic of Tanzania", "Tanzania")
Table3$region <- replace(Table3$region, Table3$region=="Syrian Arab Republic", "Syria")
Table3$region <- replace(Table3$region, Table3$region=="Korea, Republic of", "North Korea")
Table3$region <- replace(Table3$region, Table3$region=="Moldova, Republic of", "Moldova")
Table3$region <- replace(Table3$region, Table3$region=="Palestinian Territories", "Palestine")
Table3$region <- replace(Table3$region, Table3$region=="Russian Federation", "Russia")
Table3$region <- replace(Table3$region, Table3$region=="Slovak Republic", "Slovakia")

#Doing a table join of my table and the map data data frame.
mapdata <- left_join(mapdata,Table3, by = "region")
#Take away NA values
mapdata[is.na(mapdata)] <- 0
map1 <-ggplot(mapdata,aes(x=long, y=lat,group=group))+
  geom_polygon(aes(fill= Name),color = "black")+
  theme_bw()
map1
map2 <-map1+scale_fill_gradient(name="Total Nr. of Submissions", low = "white",high = "#03045e")+
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        rect = element_blank())+
  theme(legend.position = "bottom")+
  theme(legend.key.size = unit(1,'cm'))
map2

#Create a Bar Chart with the amount of report submitted per each region and Organization size
#Small Multiple Barchart of the CSR reports per Organization Size per Region.
ggplot(data1, aes(Size)) + 
  geom_bar(fill = "#0a9396") +
  theme(axis.text.x = element_text(angle = 40, vjust = 0.6, hjust=0.7, size = 6))+
  facet_wrap(~Region)+
  ggtitle("Number of reports by Region by Organization size ")+
  theme(plot.title = element_text(hjust = 0.5, size = 8))+
  theme(axis.text.x = element_text(margin = margin(t = 10), size = 8))+
  theme(axis.text.y = element_text(margin = margin(t = 10), size = 8))+
  xlab("Organization Size")+
  theme_bw()+
  ylab("No of Reports")


###Creating a Pie Chart for the amount of submission global based to organization size 
#Pie Chart of the Proportion of the Reports submitted based to Organization Size
#SME Small and medium-sized enterprises
#MNE Multinational Enteprise

Table4 <- data1%>%group_by(Size)%>% summarize(Name = n())
Table4$Per = Table4$Name/sum(Table4$Name) 
Table4$Per = Table4$Per*100
Table4$Per = round(Table4$Per,digits = 0)


ggplot(Table4, aes(x="", y=Per, fill=Size)) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  geom_text(aes(label = paste0(Per, "%")), position = position_stack(vjust=0.5)) +
  labs(x = FALSE, y = "Amount of Submission per Organization Size Worldwide") +
  theme_classic() +
  theme(axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  guides(fill=guide_legend(reverse = TRUE))+
  scale_fill_brewer(palette="Greens",name = "Organization Size")

#### Create bar chart based to country Status
#Barchart of the CSR report per Country status throw-out the years and worldwide.
ggplot(data1, aes(Country.Status)) + 
  geom_bar(fill = "#0a9396") +
  theme(axis.text.x = element_text(angle = 40, vjust = 0.6, hjust=0.7, size = 6))+
  ggtitle("Number of reports by Country Status")+
  theme(plot.title = element_text(hjust = 0.5, size = 8))+
  theme(axis.text.x = element_text(margin = margin(t = 10), size = 8))+
  theme(axis.text.y = element_text(margin = margin(t = 10), size = 8))+
  xlab("Country Status")+
  theme_bw()+
  ylab("No of Reports")




