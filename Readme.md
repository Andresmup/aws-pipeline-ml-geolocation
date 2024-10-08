# AWS PIPELINE GEOLOCATION DATA

![SCHEMA](pictures/aws-ml-architecture-geolocation-light.png)

## ABSTRACT
This work aims to explain the solution developed for the proposed problem, where the company's need to ingest and store data for training a Machine Learning model requires the design of a cloud architecture with specific requirements.

## DESCRIPTION
The company aims to implement a Machine Learning model. To achieve this, it must have the necessary data available, along with the ability to increase the amount of data as more is generated. In addition to the main idea, certain design aspects must be considered based on the outlined requirements.
To address this, the decision was made to design an architecture in AWS that meets the company's needs, considering the points mentioned in the requirements, best practices, fault tolerance, process control, and simplicity.

PROBLEM
The company wants to leverage data to generate value-added products. To do this, it plans to use data generated by mobile devices. This data must be made available to the data science team for training a Machine Learning model. Before this, the data needs to be collected, processed, verified, and meet certain characteristics.

Key aspects to consider include:
- The type of data to be processed is mobile device geolocation, with each record consisting of a timestamp along with latitude and longitude values.
- The dataset size is 10TB, so the solution must have the capacity to store this amount of data.
- The loaded records may contain repeated information from up to 3 previous days, requiring a preventive measure to ensure that the information is not duplicated.
- The stored records must be in .parquet format.
- Insights need to be generated regarding the number of mobile devices per day and month.

## ARCHITECTURE SUMMARY
The designed architecture consists of four separate areas, each divided based on the specific needs they fulfill.

The "ingestion area" is responsible for receiving information from mobile devices and entering it into the data flow. Next, the "data engineering area" is tasked with extracting, transforming, and loading each mobile record, making the data ready and available in an S3 Bucket. In the "machine learning area," the model training will be conducted using the provided Bucket as the data source. Finally, the generation of an automated record of the number of devices will take place in the "analytics area."

### INGESTION AREA
This area is responsible for receiving information sent by mobile devices. The service used for streaming data is Kinesis Data Stream, which allows real-time data ingestion through topics.

Although the requirement does not specify how the mobile devices should be integrated with the architecture, one possible approach is to use API Gateway. This would allow a REST API to receive POST requests with the locations, enabling easy integration with the existing mobile application and sending the data to Kinesis Data Stream for real-time ingestion.

### DATA ENGINEERING AREA
The data engineering area is responsible for consuming data in real-time to feed an ETL (Extract, Transform, Load) process, with the goal of cleaning the data for storage and consumption by various processes that aim to add value.

The data received from Kinesis Data Stream in real-time is passed to the Kinesis Firehose service, which has an S3 Bucket as its destination, where the raw data is temporarily stored. Kinesis Firehose also handles the transformation of messages into .parquet format. To achieve this, it uses an associated Lambda function that also partitions the records by date, adding this information as metadata to each object.

To store the records in .parquet format, their schema is saved in Glue Catalog, where the data type of each column is defined. Once the raw data has reached the S3 Bucket labeled "Raw data," the loading process begins. For this, the Airflow orchestrator is used, with the purpose of verifying that the data is not duplicated, and if it is not, loading it into the destination Bucket, "Storage data." Airflow can execute this task either on a scheduled basis (e.g., load all new records at the end of the day) or whenever a new object is loaded into the "Raw data" Bucket.

The use of S3 Buckets to temporarily store objects and for the storage of loaded data is chosen due to its low cost, unlimited growth potential, and great capacity for handling intensive workloads.

One part of the requirement specified that the records could be repeated events from up to 3 days prior, which necessitates adding some logic to verify whether an event has already been recorded, and therefore should not be loaded into the destination Bucket; if it is new, proceed with the loading. A low-cost solution that does not impact or slow down the object loading process is the use of DynamoDB. In DynamoDB, all events loaded during the last 4 days will be stored. When Airflow reads an object from the Bucket, it queries the database; if this query returns an item, it means that a record with the same timestamp, longitude, and latitude has already been loaded, and therefore, this record should not be stored in the destination Bucket. If the query returns nothing, then the record is new, so it is stored in the destination Bucket and loaded into DynamoDB to prevent duplicates of it from being processed again.

DynamoDB, being a NoSQL database, allows for easy querying of this information without incurring high costs, with great speed. Additionally, by defining a 4-day TTL (time to live), only records loaded within the last 4 days will be stored, maintaining a reduced database size.

Another key aspect indicated in the requirement is the ability to have an alert system that monitors the stored information based on defined specifications. For this, the Glue Data Quality Rules service is used, which allows for customized rules to analyze the data stored in S3. If any of the rules are not met, a CloudWatch Alarm can be triggered, which, through SNS, can send a notification (e.g., email, SMS, or Slack notification) alerting of the issue.

### ML AREA
The data science team will be responsible for consuming and utilizing the clean, stored data in the Storage Layer Bucket, with access to the files partitioned by day. They will use SageMaker to build the models.

### ANALYTICS AREA
One of the advantages of storing clean data in S3 is the ability to integrate and automate certain processes that consume this information. In this area, a Glue Job that runs periodically allows a script to be used to calculate the number of records for each month and each day, storing these results in .csv format in a destination Bucket.


## SECURITY
A fundamental aspect of any system is its security, as well as the security of the data. In AWS, this can be achieved by defining IAM roles and users with policies that grant the minimum necessary access. In this way, both cloud resources and the data stored in them can only be accessed by those with the appropriate privileges.

It is important to ensure that Buckets containing information are never publicly accessible. Additionally, server-side encryption for the objects should be enabled.

## DATA BACKUP
A recommendation and optional addition to the requirement is to use Cross-Region Replication for S3 Buckets. This allows for a copy of the data stored in the Storage Layer to be kept in another region. In the event of an undesirable occurrence affecting the availability of the AWS region, the most critical element— the data—will remain uncompromised.

## DEPLOYMENT AND VERSIONING
An important aspect of working with cloud infrastructure is the ability to version and control the deployed services. A good practice for this is to use Infrastructure as Code (e.g., Terraform).

Another feature is the ability to implement CI/CD tools where their use is beneficial. In this case, since the Amazon Managed Airflow service allows using DAGs stored in an S3 Bucket, it is possible to deploy the code used by Airflow from the GitHub repository using GitHub Actions.

## DESIGN AND SERVICE LEVELS
In the proposed design, several important aspects were considered when selecting technologies.

The design and selection of AWS services aimed to use "serverless services" and "managed services" to ensure that the development team's time is spent utilizing data rather than configuring or managing servers, instances, or clusters. Additionally, this approach allows for scaling down to zero consumption if no activities are running.

The use of S3 Buckets for storage is chosen because they can store an indefinite number of objects with no total size restriction, as the only limit for S3 is 5TB per object. This limit is well beyond the needs since individual objects (records) will be very small when storing .parquet files partitioned by date. Furthermore, each partition in S3 allows for 3,500 writes and 5,500 reads of objects per second.

Using Airflow for the ETL process between the reception Bucket and the storage Bucket allows for adjusting the load of records, using continuous streaming or batch ingestion.

API Gateway can handle 10,000 requests per second, ensuring that HTTP POST requests are always received.

In Kinesis Data Stream, each sequence of records, known as a Shard, supports writing 1MB/s and 1,000 records per second. If the data flow exceeds this limit, additional Shards can be used to handle records in parallel.

The Lambda function responsible for converting records into .parquet files allows for adjusting the buffer size between 64 and 128 MiB and the interval in seconds (between 60 and 900), to speed up or slow down the rate of writing to the ingress Bucket.
