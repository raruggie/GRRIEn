# Ryan Ruggiero
# Data Processing and visualiztion code
# 12/15/2022

# set working directory:
# the tif files came from the python notebook which exported
# the tifs to google drive, where they were downloaded to the local 
# machine. WSet the working directory to where those tif files are

setwd("C:/PhD/CEE609_Env_Data_Sci/Project")

# clean the memory:
  
rm(list=ls())

# load the required libraries: if not install use:

# install.library('raster')
# install.library('tidyverse')
# install.library('ggpubr')
  
library(raster)
library(tidyverse)
library(ggpubr)

# functions

# function to find non-numeric columns for when using mutate_all
# https://stackoverflow.com/questions/22772279/converting-multiple-columns-from-character-to-numeric-format-in-r

is_all_numeric <- function(x) {
  !any(is.na(suppressWarnings(as.numeric(na.omit(x))))) & is.character(x)
}


#### Data Processing ####

### read in data

temp = list.files(pattern="*.tif") # read in file names in the working directory
dfs = lapply(temp, stack) # apply stack function to the list of names
names(dfs) <- substr(temp,1,nchar(temp)-4) # add the names of the file names as the names of the dfs in the list, minus ".tif" (last 4 characters removed)
n = c('DC_2019', 'DC_2019', 'AHS_2020', 'AHS_2020', 'DC_2020', 'DC_2020'); p = rep(c('_pre', '_post'),3); file_names <- paste0(n,p) # get the order of file names you want
dfs <- dfs[order(file_names)] # reorder list

### create empty dataframes to append to in every loop

df1 <- data.frame(matrix(ncol = 14, nrow = 0)); colnames(df1) <- c('FieldxYear', 'Period', names(dfs[[1]])) # df for each spectral band mean
df2 <- data.frame(matrix(ncol = 7, nrow = 0)); colnames(df2) <- c('EOMI_1', 'EOMI_2', 'EOMI_3', 'EOMI_4', 'NBR2', 'FieldxYear', 'Period')

### loop through tif files to process

for (i in 1:6){
  
  # assign multi-band raster a variable
  
  r <- dfs[[i]]
  
  ### Step 1: perform band averages for a raster stack and append to dataframe
  
  t<-as.numeric(cellStats(r, 'mean'))/10000 # convert to reflectance %
  
  df1[i,] <- c(n[i], p[i], t)
  
  ### Step 2: Calculate EOMI indices
  
  EOMI_1 <- as.vector((r[[11]] - r[[9]])/(r[[11]] + r[[9]]))
  EOMI_2 <- as.vector((r[[12]] - r[[4]])/(r[[12]] + r[[4]]))
  EOMI_3 <- as.vector(((r[[11]] - r[[9]]) + (r[[12]] - r[[4]]))/(r[[11]] + r[[9]] + r[[12]] + r[[4]]))
  EOMI_4 <- as.vector((r[[11]] - r[[4]])/(r[[11]] + r[[4]]))
  NBR2 <- as.vector((r[[11]] - r[[12]])/(r[[11]] + r[[12]]))
  
  # create dataframe from above calcs and loop ID's
  t <- data.frame(EOMI_1, EOMI_2, EOMI_3, EOMI_4, NBR2) %>% # create a temporary raster stack for this loop
    na.omit() %>% # remove NA's
    mutate(FieldxYear = n[i], Period = p[i]) # add identifier columns
  
  # rbind to existing dataframe initialized outside loop
  df2 <- rbind(df2, t)
  
}

#### end ####

#### Plots, Tables ####

### make first plot - reflectance % against bands

# reformat dataframe

df1_p<-df1%>%
  pivot_longer(cols = -c(FieldxYear, Period), names_to = 'Band', values_to = 'Mean_Reflectance')%>%
  mutate(p_x = rep(c(1,2,3,4,5,6,7,8,9,10,11,12), 6))

# make plot

ggplot(df1_p, aes(x = p_x, y = round(as.numeric(Mean_Reflectance),2), color = FieldxYear, linetype = Period))+
  geom_line()+
  geom_point()+
  theme(axis.text.x=element_text(color = "black", size=11, angle=30, vjust=.8, hjust=0.8))+
  scale_x_continuous(breaks=1:12,labels= c("B1",  "B2",  "B3"  ,"B4"  ,"B5" , "B6" , "B7" , "B8" , "B8A" ,"B9",  "B11", "B12"))+
  xlab("S2 spectral bands")+
  ylab("Mean Reflectance (%)")+
  ggtitle('Mean Surface Reflectance of Fields')

### make a table of the differences in reflectance

# find differences between pre and post

df1_t<-df1%>% 
  mutate_at(3:14, as.numeric)%>%
  group_by(FieldxYear) %>% 
  summarise(-across(B1:B12, diff))

# find the bands with the min and max difference for each FieldxYear

mask <- colnames(df1_t)[startsWith(colnames(df1_t), 'B')] # find the columns in question
df1_t[c('min_diff', 'min_col')] <- t(apply(df1_t[mask], 1, function(x) { # add columns to df for min
  m <- which.min(x)
  (y <- c(x[m], mask[m]))
}))
df1_t[c('max_diff', 'max_col')] <- t(apply(df1_t[mask], 1, function(x) { # add columns to df for max
  m <- which.max(x)
  (y <- c(x[m], mask[m]))
}))

# clean up resulting dataframe

df1_t_c<-df1_t%>%
  select(-c(starts_with('B')))%>%
  mutate_if(is_all_numeric,as.numeric) %>%
  mutate(across(where(is.numeric), round, 3))

# just screen shotted this dataframe in r studio df viewer

### make second plot - boxplot

# rename factor levels and reorder pre and post levels

df<-df2
df$Period<-as.factor(df$Period)
levels(df$Period) <- c("Post", "Pre")
df$Period <- with(df, relevel(Period, "Pre"))

# make plots

p1<-ggplot(df, aes(x=FieldxYear, y=EOMI_1, fill=Period))+
  geom_boxplot()+ggtitle("EOMI_1")
p2<-ggplot(df, aes(x=FieldxYear, y=EOMI_2, fill=Period))+
  geom_boxplot()+ggtitle("EOMI_2")
p3<-ggplot(df, aes(x=FieldxYear, y=EOMI_3, fill=Period))+
  geom_boxplot()+ggtitle("EOMI_3")
p4<-ggplot(df, aes(x=FieldxYear, y=EOMI_4, fill=Period))+
  geom_boxplot()+ggtitle("EOMI_4")
p5<-ggplot(df, aes(x=FieldxYear, y=NBR2, fill=Period))+
  geom_boxplot()+ggtitle("NBR2")

# plot all plots together
ggarrange(p1, p2, p3, p4, p5, nrow=2, ncol = 3, common.legend = TRUE, legend="bottom")

### calcualte seperability index

# not sure how to do this so I just ra the analysis on all indices, see boxplots above

### Two tailed t-test

# run Wilcox test: http://www.sthda.com/english/wiki/unpaired-two-samples-wilcoxon-test-in-r

# reformat dataframe and run test in single pipe

df_w<-df%>%
  pivot_longer(1:5, names_to = 'Index', values_to = 'Value')%>%
  group_by(FieldxYear, Index)%>%
  do(w = wilcox.test(Value~Period, data=., paired=T, alternative = 'two.sided')) %>% 
  summarise(FieldxYear, Index, Wilcox = w$p.value)

# export dataframe to pdf for table
# this creates a pdf called 'mypdf.pdf' in the working directory
# I then just screenshotted it

pdf("mypdf.pdf", height=6, width=4)
grid.table(df_w)
dev.off()

#### end ####








