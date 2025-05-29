--1
CREATE TABLE Borrower (
	bid INT,
	name VARCHAR(30),
	address VARCHAR(100),
	PRIMARY KEY(bid)
);

CREATE TABLE Lender (
	lid INT,
	name VARCHAR(30),
	address VARCHAR(100),
	PRIMARY KEY(lid)
);

CREATE TABLE loanRequest (
	rno INT,
	bid INT,
	reqdate DATE,
	totamount INT,
	description VARCHAR(100),
	deadline DATE,
	appdate DATE,
	PRIMARY KEY(rno),
	FOREIGN KEY (bid) REFERENCES Borrower(bid)
);

CREATE TABLE commitment (
	rno INT,
	lid INT,
	lamount INT,
	cdate DATE,
	PRIMARY KEY(rno, lid),
	FOREIGN KEY (rno) REFERENCES loanRequest,
	FOREIGN KEY (lid) REFERENCES Lender
);

CREATE TABLE repayment (
	rno INT,
	rdate DATE,
	lid INT,
	ramount INT,
	PRIMARY KEY(rno, rdate, lid),
	FOREIGN KEY(rno) REFERENCES loanRequest,
	FOREIGN KEY (lid) REFERENCES Lender
);

--2
CREATE OR REPLACE FUNCTION trigf1() RETURNS TRIGGER AS $$
BEGIN
    IF (
        CURRENT_DATE > (
            SELECT deadline 
            FROM loanRequest 
            WHERE rno = NEW.rno
        )
    ) THEN
        RAISE NOTICE 'The deadline for the loan has already passed';
        RETURN NULL;
    END IF;
    IF (
        (
            SELECT SUM(lamount) 
            FROM commitment 
            WHERE rno = NEW.rno
        ) + NEW.lamount >= (
            SELECT totamount 
            FROM loanRequest 
            WHERE rno = NEW.rno
        )
    ) THEN
        UPDATE loanRequest
        SET appdate = CURRENT_DATE
        WHERE rno = NEW.rno;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER T1
BEFORE INSERT ON commitment
FOR EACH ROW
EXECUTE PROCEDURE trigf1();


--3
INSERT INTO Borrower VALUES 
	(1, 'oded', '123 main st, anytown'),
	(2, 'carmel', '456 elm ave, somewhere'),
	(3, 'alex', '789 oak rd, elsewhere'),
	(4, 'agam', '321 pine ln, nowhere'),
	(5, 'matan', '654 maple dr, anyplace');

INSERT INTO Lender VALUES
	(2, 'carmel', '456 elm ave, somewhere'),
	(3, 'alex', '789 oak rd, elsewhere'),
	(6, 'doron', '111 first st, cityville'),
	(7, 'arbel', '222 second ave, townsburg'),
	(8, 'alex', '333 third rd, villageton');

INSERT INTO loanRequest VALUES
	(11, 1, '2024-06-15', 50000, 'home renovation', '2025-08-02', null),
	(22, 2, '2024-05-01', 3000, 'education expenses', '2025-12-17', null),
	(33, 3, '2024-06-01', 75000, 'small business startup', '2025-08-01', null),
	(44, 4, '2024-06-01', 200000, 'medical bills', '2025-08-01', null),
	(55, 5, '2024-05-15', 4000, 'kids education', '2025-10-15', null);

INSERT INTO commitment VALUES
	(11, 6, 49999, '2024-06-20'),
	(11, 7, 500000, '2024-07-31'),
	(22, 3, 3000, '2024-05-20'),
	(33, 8, 5000, '2024-07-05'),
	(44, 6, 10000, '2024-06-10'),
	(44, 7, 10000, '2024-08-01'),
	(55, 8, 4000, '2024-08-10');
	
INSERT INTO repayment VALUES
	(11, '2025-01-01', 6, 1500),
	(11, '2025-01-01', 7, 500),
	(22, '2025-01-01', 3, 1750),
	(33, '2025-01-01', 8, 1000),
	(44, '2025-01-01', 6, 2000),
	(44, '2025-01-01', 7, 200),
	(55, '2025-01-01', 8, 800);

--4
SELECT 
    Borrower.name AS borrower_name,
	loanRequest.description AS loan_description,
    Lender.name AS lender_name,
	Lender.lid AS lender_id
FROM 
    loanRequest
JOIN 
    Borrower ON loanRequest.bid = Borrower.bid
JOIN 
    commitment ON loanRequest.rno = commitment.rno
JOIN 
    Lender ON commitment.lid = Lender.lid
WHERE
	commitment.lamount > 5000
	AND loanRequest.appdate IS NOT NULL;

--5
SELECT 
    loanRequest.rno AS loan_number, 
    Borrower.bid AS borrower_id
FROM 
    loanRequest
JOIN 
    Borrower ON loanRequest.bid = Borrower.bid
WHERE 
    loanRequest.description LIKE '%education%'
    AND loanRequest.deadline < CURRENT_DATE
    AND loanRequest.appdate IS NULL;

--6
SELECT 
    loanRequest.rno AS loan_id,
    loanRequest.totamount AS loan_amount,
    SUM(commitment.lamount) AS committed_amount,
    COUNT(commitment.lid) AS number_of_lenders
FROM 
    loanRequest, commitment
WHERE 
    loanRequest.rno = commitment.rno
    AND loanRequest.totamount > 50000
GROUP BY 
    loanRequest.rno, loanRequest.totamount;

--7
SELECT 
    Lender.lid AS lender_id,
    Lender.name AS lender_name
FROM 
    Lender
JOIN 
    commitment ON Lender.lid = commitment.lid
GROUP BY 
    Lender.lid, Lender.name
HAVING 
    COUNT(commitment.rno) >= 3
    AND SUM(commitment.lamount) > 5000;

--8
SELECT 
    commitment.lid AS lender_id
FROM 
    commitment
WHERE 
    commitment.lid NOT IN (
        SELECT
			commitment.lid
        FROM 
            commitment, repayment
        WHERE
			commitment.rno = repayment.rno
			AND
			commitment.lid = repayment.lid
        GROUP BY 
            commitment.lid, commitment.rno, commitment.lamount
        HAVING 
            commitment.lamount / SUM(repayment.ramount) > 2
    )
GROUP BY 
    commitment.lid;

--9
SELECT 
    loanRequest.rno AS loan_id,
    loanRequest.totamount AS total_loan_amount,
    commitment.lamount AS doron_commitment_amount
FROM 
    loanRequest
JOIN 
    Borrower ON loanRequest.bid = Borrower.bid
JOIN 
    commitment ON loanRequest.rno = commitment.rno
JOIN 
    Lender ON commitment.lid = Lender.lid
WHERE 
    Borrower.bid = (
        SELECT 
            bid
        FROM (
            SELECT 
                bid,
                SUM(totamount) AS total_sum
            FROM 
                loanRequest
            GROUP BY 
                bid
        ) AS total_loans
        WHERE 
            total_sum = (
                SELECT 
                    MAX(total_sum)
                FROM (
                    SELECT 
                        bid,
                        SUM(totamount) AS total_sum
                    FROM 
                        loanRequest
                    GROUP BY 
                        bid
                ) AS total_loans_max
            )
    )
    AND loanRequest.appdate IS NOT NULL
    AND Lender.name = 'doron'
    AND commitment.lamount > 10000;


--10
WITH total_loans_per_borrower AS (
    SELECT 
        bid,
        SUM(totamount) AS total_sum
    FROM 
        loanRequest
    GROUP BY 
        bid
)
SELECT 
    loanRequest.bid AS borrower_id,
    SUM(loanRequest.totamount) AS total_requested_amount
FROM 
    loanRequest
JOIN 
    total_loans_per_borrower ON loanRequest.bid = total_loans_per_borrower.bid
WHERE 
    total_loans_per_borrower.total_sum = (
        SELECT 
            MAX(total_sum)
        FROM 
            total_loans_per_borrower
    )
GROUP BY 
    loanRequest.bid;