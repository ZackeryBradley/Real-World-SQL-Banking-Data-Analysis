# 📊 Banking Data Analysis (Databricks SQL)

## 🚀 Overview
This project showcases SQL-based analytics using a banking dataset in Databricks.  
The goal is to answer business-driven questions around **customer risk, account distribution, loan trends, and financial segmentation**.

---

## 🛠️ Tech Stack
- Databricks Notebook  
- SQL (Spark SQL)  
- Python (Pandas for exploration)

---

## 📂 Dataset
The dataset includes:
- Customers (credit score, city, name)
- Accounts (balances, account types)
- Loans (loan amount, interest rates)
- Cards (debit/credit types)

---
## 🔎 Data Exploration Script
A Python script is used to:
- Loop through all tables
- Extract schema (columns + data types)
- Generate sample values for each column

This helps quickly understand the dataset structure before analysis.

<img width="1122" height="517" alt="img1" src="https://github.com/user-attachments/assets/d9e9f806-c0f9-42f9-bf16-8cfff6a50775" />
---


## 📈 SQL Queries & Explanations

### 🔹 Q1: High-Risk Borrowers
Identifies customers with:
- Credit score < 500
- Loan amount > $100,000

**Purpose:** Detect high-risk individuals with large financial exposure.
```sql
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
order by loan_amount desc
```

**Explanation:** Identifies customers with low credit scores and high loan exposure.

<img width="655" height="497" alt="img2" src="https://github.com/user-attachments/assets/c4787606-ed29-4fbc-b573-6515519aaf5a" />


---

### 🔹 Q2: Account Distribution
Calculates:
- Number of accounts per type
- Percentage of total accounts

**Purpose:** Understand product usage and popularity.
```sql
select   
account_type  
,format_number(count(*),'#,###') as num_accounts  
,round(count(*)*100.0/(select count(*) from kaggle.bank.accounts),2) as pct_accounts  
from kaggle.bank.accounts  
group by account_type  
order by pct_accounts desc
```

**Explanation:** Calculates total accounts and percentage share by account type.

<img width="521" height="171" alt="img3" src="https://github.com/user-attachments/assets/07338837-a0ee-4647-a2ff-e83dea40a532" />


---

### 🔹 Q3: Multi-Product Customers
Finds accounts that have BOTH:
- Debit cards
- Credit cards

**Purpose:** Identify highly engaged customers for cross-selling.

```sql
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
```

**Explanation:** Finds accounts that own both debit and credit cards.

<img width="467" height="497" alt="img4" src="https://github.com/user-attachments/assets/8788f2b8-bdce-47a3-99fb-6b5215047f65" />

---

### 🔹 Q4: Monthly Loan Trends (2025)
Calculates per month:
- Number of loans issued per month in 2025
- Total loan value for those loans

**Purpose:** Analyze lending trends over time.

```sql
select   
cast(date_trunc('month', start_date) as date) as month  
,count(*) as num_loans  
,format_number(sum(loan_amount),'$#,###.##') as total_amount  
from kaggle.bank.loans  
where year(start_date) = 2025  
group by month  
order by month
```

**Explanation:** Tracks number and total value of loans issued monthly.

<img width="437" height="377" alt="img5" src="https://github.com/user-attachments/assets/e6ad43af-e411-4bae-a449-7fb378afe6f7" />


---

### 🔹 Q5: Top Customers by City
Ranks customers by balance within each city and returns top 3.

**Purpose:** Identify high-value customers regionally.

```sql
select  
a.account_id  
,a.balance_usd  
,city  
,dense_rank() over(partition by c.city order by a.balance_usd desc) as rank  
from kaggle.bank.accounts a  
join kaggle.bank.customers c  
on a.customer_id = c.customer_id  
qualify rank <=3
```

**Explanation:** Ranks customers by balance within each city.

<img width="521" height="495" alt="img6" src="https://github.com/user-attachments/assets/9b9b379f-fdad-431f-b2b8-7bfe11f6b967" />


---

### 🔹 Q6: High-Value, High-Risk Segmentation
Filters customers who:
- Have balances > $150,000
- Loans > $100,000
- Credit score < 650

Then segments them into:
- High Value - High Risk
- Stable High Value

**Purpose:** Real-world risk and revenue segmentation.


```sql
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
```

**Explanation:** Performs advanced segmentation of customers based on balance, loans, and risk.

<img width="1052" height="445" alt="img7" src="https://github.com/user-attachments/assets/0a45c681-fea2-4b91-bc7c-6d5600c40a56" />


---

## 📊 Key Insights
- High-risk customers often carry large loan balances
- Product usage varies across account types
- Multi-product users are more engaged
- Loan activity shows monthly trends

---

## 💡 Skills Demonstrated
- SQL joins and aggregations
- Window functions (DENSE_RANK)
- CTEs for modular analysis
- Business-driven analytics

---
