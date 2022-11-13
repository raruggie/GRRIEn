This is the readme file for the data download and preprocess code

The data download and preprocess code is all in one juypter notebook. The code starts by imprting the necessary librarys and authnticfactions for google earth engine (ee). EE is used to collect image collections for S1 and S2 images over my fields. The first field, AHS, has manure application date data for years 2018, 2019, and 2020. There was no S2 imagery for 2018, so I started with 2019. The areas of interests (aoi) for AHS and the second field, DC, were sketched using the polygon tool on https://geojson.io/, and the geojson code that resulted was copied and pasted into the jupyter notebook. A larger rectangular aoi was also imported into the jupyter notebook as geojson code to use for filtering by Bounds before clipping to the field aois. 

For the S2 imagery, 4 bands were selected (B4, B8A, B11, and B12) and the image collection was filtered by date for the 15 days preceeding and proceeding the manure injection dates. The collections for pre- and post- manure injection were assigned to seperate variables. Given the temoral resolution of the collection, there were multiple images pre and post manure injection date. 

Concerning cloud issues with the S2 images, there was no way to filter the pre- and post- collections using the S2 'CLOUD COVER' metadata since all image tiles were labled for cloud cover percentages as low as less than 100%. The solution for this was to look at every image in the collections and determine if there were clouds over my aois. 

The image collections were translated into pandas dataframes (pdfs) using the workflow from https://developers.google.com/earth-engine/tutorials/community/detecting-changes-in-sentinel-1-imagery-pt-1.

Band ratio indices were calculated from the equations in Dodin et al. 2021 (see jupyternote book). The raster math could be completed using the pandas dataframe columns, which contained the pixel data for each band. 

This pandasdataframe is the final product for this step in the project. Moving forward, then next step is to aggregate the index data by data before inputting the data into the the histograms and running the t-tests. I don't have columns for predictor and predictand, rather the histograms of the pixel distributions of the pre- and post- pdfs will be tested for significant difference using hypthesis testing. 

