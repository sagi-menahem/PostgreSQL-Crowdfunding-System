# PostgreSQL - Crowdfunding Database Management System

This repository contains the SQL code and assignment details for Maman 12, a database management assignment focused on a crowdfunding system.

Task #2 for the 20277 course of the Open University.

The full assignment (in Hebrew) is in the [Task 2.pdf](Task%202.pdf) file.

## Table of Contents

* [Project Description](#project-description)
* [Database Schema](#database-schema)
* [SQL Queries](#sql-queries)
* [Usage](#usage)
* [Author](#author)

## Project Description

The goal of this assignment was to design and implement a database system using PostgreSQL for managing a crowdfunding platform. This involved creating database tables, defining relationships, inserting data, and writing SQL queries to retrieve and manipulate information according to specific requirements.

The system manages data related to borrowers, lenders, loan requests, commitments, and repayments.

## Database Schema

The database schema consists of the following tables:

* **Borrower (bid, name, address):** Stores information about borrowers.
* **Lender (lid, name, address):** Stores information about lenders.
* **loanRequest (rno, bid, reqdate, totamount, description, deadline, appdate):** Stores information about loan requests.
* **commitment (rno, lid, lamount, cdate):** Stores information about lender commitments to loan requests.
* **repayment (rno, rdate, lid, ramount):** Stores information about loan repayments.

Key relationships between the tables:

* `loanRequest` references `Borrower` via `bid`.
* `commitment` references `loanRequest` via `rno` and `Lender` via `lid`.
* `repayment` references `commitment` via `rno` and `lid`.

## SQL Queries

The `Maman 12.sql` file includes SQL queries to perform the following tasks:

1.  Create the database tables with appropriate data types, primary keys, foreign keys, and constraints.
2.  Implement a trigger (`T1`) to enforce business rules on loan commitments.
3.  Populate the tables with initial data.
4.  Retrieve data based on various criteria, including:

    * Lenders who committed more than a certain amount to approved loans.
    * Loan requests that are past their deadline and not yet approved.
    * Loan requests with total requested amounts greater than a threshold.
    * Lenders who committed to a minimum number of loans and a minimum total amount.
    * Lenders who received at least 50% repayment on all their commitments.
    * The loan with the highest total requested amount for the borrower with the highest total requests.
    * The borrower with the highest total requested loan amount among those who have made repayments.

## Usage

To use the code in this repository:

1.  Ensure you have PostgreSQL installed and running.
2.  Execute the SQL code in [Task 2.sql](Task%202.sql) to create the database schema and populate it with data.
3.  You can then run the provided SQL queries to retrieve and analyze the data as needed.

## Author

Sagi Menahem.
