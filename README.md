# Inventory-Optimization
Case Study - Kaggle (https://www.kaggle.com/flenderson/sales-analysis)
Context

Attached is a set of products in which we are trying to determine which products we should continue to sell, and which products to remove from our inventory. The file contains BOTH historical sales data AND active inventory, which can be discerned with the column titled "File Type".

We suspect that data science applied to the set--such as a decision tree analysis or logistic regression, or some other machine learning model---can help us generate a value (i.e., probability score) for each product, that can be used as the main determinant evaluating the inventory. Each row in the file represents one product.

It is important to note that we have MANY products in our inventory, and very few of them tend to sell (only about 10% sell each year) and many of the products only have a single sale in the course of a year.
Content

The file contains historical sales data (identified with the column titled File_Type) along with current active inventory that is in need of evaluation (i.e., File Type = "Active"). The historical data shows sales for the past 6 months. The binary target (1 = sale, 0 = no sale in past six months) is likely the primary target that should drive the analysis.

The other columns contain numeric and categorical attributes that we deem relevant to sales.

Note that some of the historical sales SKUs are ALSO included in the active inventory.

A few comments about the attributes included, as we realize we may have some attributes that are unnecessary or may need to be explained.

    SKU_number: This is the unique identifier for each product.

    Order: Just a sequential counter. Can be ignored.

    SoldFlag: 1 = sold in past 6 mos. 0 = Not sold

    MarketingType = Two categories of how we market the product. This should probably be ignored, or better yet, each type should be considered independently.

    NewReleaseFlag = Any product that has had a future release (i.e., Release Number > 1)

Inspiration

(1) What is the best model to use that will provide us with a probability estimate of a sale for each SKU? We are mainly interested in a relative unit that we can continuously update based on these attributes (and others that we add, as we are able).

(2) Is it possible to provide a scored file (i.e., a probability score for each SKU in the file), and to provide an evaluation of the accuracy of the selected model?

(3) What are the next steps we should take?

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Step 1:
Loaded the data into R studio and created the datatable. Convert the data into proper format for further analysis.
Step 2:
Performed ABC analysis using Excel Pivot Tables and graphs.
Formed train and test datasets. Then performed exploratory analysis using Plots, heatmap, correlation matrix (ggplot2 lib). Identified the outliers and handled missing values in the dataset. Using Feature engineering to extract features required for constructing the model
Step 3:
To balanced the dataset using SMOTE in which over sampled the minority class data.
Step 4:
Built and executed various Regression models ( Linear, Logistic, SVM, Random Forest). Among all Random Forest performed the best with accuracy ~80%
Step 5:
Used the Random Forest Regression model to predict the sale probability of each SKU from the inventory.
Step 6:
Identified the demand function and computed the net contribution based on the sale probability and the demand.
