-- Databricks notebook source
-- DBTITLE 1,mini dc build
-- MAGIC %python
-- MAGIC #THIS SCRIPT IS INTENDED TO GENERATED 3 DATA SAMPLES FOR EACH COLUMN IN YOUR SCHEMA
-- MAGIC import os
-- MAGIC import pandas as pd
-- MAGIC
-- MAGIC DATABASE_NAME = "kaggle.bank"
-- MAGIC
-- MAGIC cls = []
-- MAGIC spark.sql("USE " + DATABASE_NAME)
-- MAGIC
-- MAGIC tables = spark.sql("SHOW TABLES").collect()
-- MAGIC for table in tables:
-- MAGIC     tableName = table['tableName']
-- MAGIC     columns = spark.sql(f"DESCRIBE {tableName}").collect()
-- MAGIC     for column in columns:
-- MAGIC         data_samples = spark.sql(f"SELECT DISTINCT {column['col_name']} FROM {DATABASE_NAME}.{tableName} LIMIT 3").collect()
-- MAGIC         data_samples_str = "; ".join([str(row[0]) for row in data_samples])
-- MAGIC         cls.append({
-- MAGIC         "Database_Name": DATABASE_NAME,
-- MAGIC         "Table": tableName,
-- MAGIC         "Column": column['col_name'],
-- MAGIC         "Data_Type": column['data_type'],
-- MAGIC         "Data_Samples": data_samples_str
-- MAGIC         })
-- MAGIC
-- MAGIC df = pd.DataFrame(cls)
-- MAGIC display(df)

-- COMMAND ----------

show tables in kaggle.bank

-- COMMAND ----------

-- DBTITLE 1,Q1_Solved
-- Q1: find customers with a credit score of < 500 and a loan amount of 100k
select
cs.customer_id
,concat(cs.first_name,' ',cs.last_name) as customer
,cs.credit_score
,format_number(l.loan_amount, '#,###.##') as loan_amount_formatted
from kaggle.bank.customers cs
join
(select 
customer_id
,loan_amount
from kaggle.bank.loans 
where loan_amount > 100000
) l
on cs.customer_id = l.customer_id
where cs.credit_score < 500






-- COMMAND ----------

-- DBTITLE 1,Q2_Solved
-- Q2: find the % of accounts by type
select 
account_type
,format_number(count(*),'#,###') as num_accounts
,round(count(*)*100.0/(select count(*) from kaggle.bank.accounts),2) as pct_accounts
from kaggle.bank.accounts
group by account_type
order by pct_accounts desc

-- COMMAND ----------

-- DBTITLE 1,Q3_Solved
-- Q3: find accounts that have both debit and credit cards
select * from
(
select 
a.account_id
,collect_set(c.card_type) as cards
from kaggle.bank.cards c
join kaggle.bank.accounts a
on c.account_id = a.account_id
group by a.account_id
)
where array_contains(cards, 'Debit') 
and array_contains(cards, 'Credit')

-- COMMAND ----------

-- DBTITLE 1,Q4_Solved
-- Q4: find how many loans are issued and the total amount of loans issued for each month for 2025
select 
cast(date_trunc('month', start_date) as date) as month
,count(*) as num_loans
,format_number(sum(loan_amount),'$#,###.##') as total_amount
from kaggle.bank.loans
where year(start_date) = 2025
group by month
order by month

-- COMMAND ----------

-- DBTITLE 1,Q5_Solved
-- Q5: rank customers by balance within each city

select
a.account_id
,a.balance_usd
,city
,dense_rank() over(partition by c.city order by a.balance_usd desc) as rank
from kaggle.bank.accounts a
join kaggle.bank.customers c
on a.customer_id = c.customer_id
qualify rank <=3


-- COMMAND ----------

-- DBTITLE 1,Q6_Solved
-- Q6: Find the top 20 customers who:

-- Have total account balances > $150,000
-- AND total loan exposure > $100,000
-- AND credit score < 650 (higher risk)

-- For each of these customers, return:

-- Customer info (name, city, credit score)
-- Total account balance
-- Number of accounts
-- Total loan amount
-- Average interest rate on their loans

-- Customer segment:

-- "High Value - High Risk" if loan > balance
-- "Stable High Value" otherwise

with account_aggregation as (
select
customer_id
,count(distinct account_id) as num_accounts
,sum(balance_usd) as total_balance
from kaggle.bank.accounts
where balance_usd > 150000
group by customer_id
),

loan_aggregation as(
select
customer_id
,round(sum(loan_amount),2) as total_loan_amount
,round(avg(interest_rate),2) as avg_interest_rate
from kaggle.bank.loans
where loan_amount > 100000
group by customer_id
)

select
concat(cs.first_name, ' ', cs.last_name) as customer_full_name
,cs.city
,cs.credit_score
,a.num_accounts
,l.total_loan_amount
,l.avg_interest_rate
,case when l.total_loan_amount > a.total_balance then 'high value/high risk' else 'stable high value' end as customer_segment

from kaggle.bank.customers cs
join account_aggregation a
on a.customer_id = cs.customer_id
join loan_aggregation l
on cs.customer_id = l.customer_id
where cs.credit_score < 650
order by num_accounts desc







