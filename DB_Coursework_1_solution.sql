----- Environment Used: Oracle Live SQL 
----- Oracle Live SQL has a limit on the number of statements that can be executed in a single run, particularly when there are too many lines of code. To ensure smooth execution, please follow these steps:
----- 1. Copy and paste the CREATE TABLE & TRIGGER commands first and hit run (IMPORTANT: Please ensure you copy TRIGGER together with CREATE TABLE commands as trigger will affect some attributes such as membership status, reservation status and related queries later on)
----- 2. After the tables and triggers have been created successfully, copy and paste the INSERT commands and hit run.


----------- CREATE TABLE COMMANDS -----------
DROP TABLE Member;
DROP TABLE Resources;
DROP TABLE Book;
DROP TABLE BookCopy;
DROP TABLE Device;
DROP TABLE Loan;
DROP TABLE Reservation;
DROP TABLE Offer;
DROP TABLE Course;
DROP TABLE BookCourseRecommendation;

CREATE TABLE Member (
	MemberId Number(10) PRIMARY KEY,
	MemberType VARCHAR2(10) NOT NULL CHECK (MemberType in ('Student', 'Staff')),
	FirstName VARCHAR2(30) NOT NULL,
	LastName VARCHAR2(30) NOT NULL,
	Email VARCHAR2(40) UNIQUE NOT NULL,
	Address VARCHAR2(255),
	JoinDate DATE DEFAULT SYSDATE NOT NULL,
	ExpiredDate DATE,
	MembershipStatus VARCHAR2(10) DEFAULT 'Active' CHECK (MembershipStatus in ('Active', 'Expired', 'Suspended')),
	OverdueFine NUMBER(5,0) DEFAULT 0,
	CONSTRAINT chk_membership_date CHECK (ExpiredDate > JoinDate)
);

CREATE TABLE Resources (
    ResourcesId Number(10) PRIMARY KEY,
    ResourcesType VARCHAR2(20) NOT NULL CHECK (ResourcesType IN ('Device', 'Book', 'eBook')),
    ResourcesStatus VARCHAR2(20) NOT NULL CHECK (ResourcesStatus IN ('Available', 'Unavailable')),
    FloorNumber NUMBER(2), -- floor number can be negative
    ShelfNumber NUMBER(5) CHECK (ShelfNumber > 0),
    LoanPeriod NUMBER(2) CHECK (LoanPeriod >= 0), -- loan period is 0 if resource can only be used in library (based on assumption)
    CONSTRAINT chk_location CHECK (
		(ResourcesType = 'eBook' AND ShelfNumber IS NULL AND FloorNumber IS NULL) OR
		(ResourcesType != 'eBook' AND ShelfNumber IS NOT NULL AND FloorNumber IS NOT NULL )
    )
);

CREATE TABLE Book (
	ISBN VARCHAR2(17) PRIMARY KEY,
	BookCategory VARCHAR2(50), 
	BookTitle VARCHAR2(150) NOT NULL,
	Author VARCHAR2(50),
	Publisher VARCHAR2(50)
);

CREATE TABLE BookCopy (
    ResourcesId Number(10) PRIMARY KEY,
    ISBN VARCHAR2(17) NOT NULL, 
    FOREIGN KEY (ISBN) REFERENCES Book(ISBN),
    FOREIGN KEY (ResourcesId) REFERENCES Resources(ResourcesId) ON DELETE CASCADE
);

CREATE TABLE Device (
    ResourcesId Number(10) PRIMARY KEY,
		DeviceCategory VARCHAR2(20) NOT NULL,
   	Brand VARCHAR2(50),
    Model VARCHAR2(50),
    FOREIGN KEY (ResourcesId) REFERENCES Resources(ResourcesId) ON DELETE CASCADE
);

CREATE TABLE Loan (
    LoanId Number(10) PRIMARY KEY,
    MemberId Number(10) NOT NULL,
    ResourcesId Number(10) NOT NULL,
    LoanDate DATE DEFAULT SYSDATE NOT NULL,
    ActualReturnDate DATE,
    LoanStatus VARCHAR2(20) DEFAULT 'Loaned' CHECK (LoanStatus IN ('Loaned', 'Returned', 'Overdue')),
    FOREIGN KEY (MemberId) REFERENCES Member(MemberId), --assume if member is deleted, the prior loan record is anonymized as it's important to keep previous loan records, hence we can't delete any record in loan table
    FOREIGN KEY (ResourcesId) REFERENCES Resources(ResourcesId),
    CONSTRAINT chk_loan_status CHECK ( 
	    (ActualReturnDate IS NULL AND LoanStatus = 'Loaned') OR
	    (ActualReturnDate IS NULL AND LoanStatus = 'Overdue') OR
	    (ActualReturnDate IS NOT NULL AND LoanStatus = 'Returned')
	   ),
	  CONSTRAINT chk_return_date CHECK (ActualReturnDate >= LoanDate)
);

CREATE TABLE Reservation (
    ReservationId Number(10) PRIMARY KEY,
    MemberId Number(10) NOT NULL,
    ResourcesId Number(10) NOT NULL,
    ReservationDate DATE DEFAULT SYSDATE NOT NULL,
    ReservationStatus VARCHAR2(20) DEFAULT 'Reserved' CHECK (ReservationStatus IN ('Reserved', 'Completed', 'Cancelled')),
    FOREIGN KEY (MemberId) REFERENCES Member(MemberId), 
    FOREIGN KEY (ResourcesId) REFERENCES Resources(ResourcesId) 
);


CREATE TABLE Offer (
    ReservationId Number(10) NOT NULL,
    OfferDate DATE DEFAULT SYSDATE NOT NULL,
    ResponseDate DATE,
    OfferStatus VARCHAR2(20) DEFAULT 'Given' CHECK (OfferStatus IN ('Given', 'Accepted', 'Declined', 'Expired')),
    FOREIGN KEY (ReservationId) REFERENCES Reservation(ReservationId) ON DELETE CASCADE, --reservationId is auto-incremented and shouldn't be updated
    PRIMARY KEY (ReservationId, OfferDate),
    CONSTRAINT check_response_date CHECK (
			(ResponseDate >= OfferDate) AND -- ensure offer date must always be earlier or same as response date
		  (OfferStatus != 'Expired' OR ResponseDate > OfferDate + 3)
	    -- Assumption: If no response is received within 3 days from OfferDate, the offer is cancelled. 
	) 
);


CREATE TABLE Course (
    CourseId Number(10) PRIMARY KEY,
    CourseName VARCHAR2(100) NOT NULL
);

CREATE TABLE BookCourseRecommendation (
    ISBN VARCHAR2(17),
    CourseId Number(10) NOT NULL,
    FOREIGN KEY (ISBN) REFERENCES Book(ISBN) ON DELETE CASCADE, 
    FOREIGN KEY (CourseId) REFERENCES Course(CourseId) ON DELETE CASCADE,
    PRIMARY KEY (ISBN, CourseId)
);

COMMIT;

-- Trigger update overdue fine automatically
-- Based on requirement: For each day a resource is overdue the member is fined one pound.
CREATE OR REPLACE TRIGGER update_overdue_fine
AFTER INSERT OR UPDATE OF actualReturnDate ON Loan
FOR EACH ROW
DECLARE 
	maxloanDays Resources.loanPeriod%TYPE; -- Matches the data type of loan period from Resources table
	overdueDays NUMBER(2);
	currentFine Member.overdueFine%TYPE; -- Matches the data type of overdueFine in the Member table
BEGIN	
		SELECT loanPeriod INTO maxloanDays
		FROM Resources 
		WHERE resourcesId = :NEW.resourcesId;
		-- calculate overdue days
		IF (:NEW.actualReturnDate IS NOT NULL) 
		AND :NEW.actualReturnDate > maxLoanDays + :NEW.loanDate THEN
			overdueDays := :NEW.actualReturnDate - (maxLoanDays + :NEW.loanDate);
    ELSIF :NEW.actualReturnDate IS NULL 
    AND SYSDATE > maxLoanDays + :NEW.loanDate THEN
      overdueDays := SYSDATE - (maxLoanDays + :NEW.loanDate);
		-- fetch the current overdue fine for the member
		SELECT overdueFine INTO currentFine
		FROM Member
		WHERE memberId = :NEW.memberId;
		-- update new fine, 1 pound per overdue days
		UPDATE Member
		SET overdueFine = currentFine + overdueDays * 1
		WHERE memberId = :NEW.memberId;
		END IF;
END;
/
-- Trigger to update membership status to suspended if overdue fine is > 10
-- Based on requirement: When the amount owed in fines by a member is more than 10 pounds, that member is suspended until all resources have been returned and all fines paid in full.
CREATE OR REPLACE TRIGGER update_membership_status
FOR UPDATE OF OverdueFine ON Member
COMPOUND TRIGGER
    -- Declare a collection to store MemberIds that need status updates
    TYPE MemberIdList IS TABLE OF Member.MemberId%TYPE;
    member_ids MemberIdList := MemberIdList();
    BEFORE EACH ROW IS
    BEGIN
        -- Check if the condition is met and store the MemberId
        IF :NEW.OverdueFine > 10 THEN
            member_ids.EXTEND;
            member_ids(member_ids.COUNT) := :NEW.MemberId;
        END IF;
    END BEFORE EACH ROW;
    AFTER STATEMENT IS
    BEGIN
        -- Perform the update outside of the row-level operation
        FORALL i IN 1..member_ids.COUNT
            UPDATE Member
            SET MembershipStatus = 'Suspended'
            WHERE MemberId = member_ids(i);
    END AFTER STATEMENT;
END;
/
-- Trigger to ensure loan limit at a time
-- Based on requirement: the total number of resources student may borrow at a given time must never exceed 5, and staff is 10
CREATE OR REPLACE TRIGGER check_loan_limit
BEFORE INSERT ON Loan
FOR EACH ROW
DECLARE
    loanCount INT;
    loanLimit INT;
    memberType Member.MemberType%TYPE; -- Matches the data type of membertype from Member table
BEGIN
    -- Get the MemberType from the Member table
    SELECT m.MemberType INTO MemberType
    FROM Member m WHERE m.MemberId = :NEW.MemberId;
    -- Set LoanLimit based on MemberType
    IF memberType = 'Student' THEN
        loanLimit := 5;
    ELSIF memberType = 'Staff' THEN
        loanLimit := 10;
    END IF;
    -- Count active loans for the MemberId being inserted
    SELECT COUNT(*) INTO LoanCount
    FROM Loan l
    WHERE l.MemberId = :NEW.MemberId AND l.loanStatus != 'Returned';
    -- Check if the loan count exceeds the loan limit
    IF loanCount > loanLimit THEN
        RAISE_APPLICATION_ERROR(-20001, 'Number of loans exceeded limit');
    END IF;
END;
/

-- Trigger to update reservation status
-- Based on requirement: If a member is unable to take up the offer of a loan 3 times for a given reservation, that reservation is cancelled. 
CREATE OR REPLACE TRIGGER update_reservation_status
FOR INSERT OR UPDATE ON Offer
COMPOUND TRIGGER
    --Declare global variable
    offerCount NUMBER;
    --After each row, count number of declined or expired offers & update reservation status
    BEFORE EACH ROW IS
    BEGIN
        SELECT Count(*) INTO offercount
        FROM Offer 
        WHERE ReservationId = :NEW.ReservationId
        AND offerStatus IN ('Declined', 'Expired');
    END BEFORE EACH ROW;
    AFTER EACH ROW IS
    BEGIN
        -- If offer is accepted, update reservation status to completed
        IF :NEW.OfferStatus = 'Accepted' THEN
            UPDATE Reservation 
            SET ReservationStatus = 'Completed'
            WHERE ReservationId = :NEW.ReservationId;
        -- If offer is not accepted, count total failed offers & update reservation status 
        ELSIF :NEW.offerStatus IN ('Declined', 'Expired') THEN 
            offerCount := offerCount + 1;
        END IF;
        IF offerCount = 3 THEN
            UPDATE Reservation
            SET reservationStatus = 'Cancelled'
            WHERE reservationId = :NEW.reservationId;
        END IF;
    END AFTER EACH ROW;
END update_reservation_status;
/
-- Trigger to ensure no more than 3 offer rows created per reservation Id
-- Based on requirement: If a member is unable to take up the offer of a loan 3 times for a given reservation, that reservation is cancelled
CREATE OR REPLACE TRIGGER check_offer_limit
BEFORE INSERT ON Offer
FOR EACH ROW
DECLARE offercount NUMBER;
BEGIN
	SELECT Count(*) INTO offercount
	FROM Offer
	WHERE reservationId = :NEW.reservationId;
    -- Check if there are more than 3 offer per reservation
	IF offercount > 3 THEN
		RAISE_APPLICATION_ERROR (-20002, 'No more than 3 offers are given for a reservation');
	END IF;
END;
/



-----------------------------------------------------------------------------------------------------



----------- INSERT TABLE COMMANDS -----------
CREATE SEQUENCE MemberId_Seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE ResourcesId_Seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE LoanId_Seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE ReservationId_Seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE CourseId_Seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

----------- MEMBER -----------
-- 1. Active Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Student', 'Alice', 'Kim', 'alice.kim@qmul.ac.uk', '2 Underwood Road, London E1 5AW', TO_DATE('2025-12-31', 'YYYY-MM-DD'));
-- 2. Active Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Student', 'Bob', 'Brown', 'bob.brown@qmul.ac.uk', '321 Oak St, Hamlet E1 9AW', TO_DATE('2025-12-20', 'YYYY-MM-DD'));
-- 3. Active Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Student', 'Mayu', 'Kishimoto', 'mayu.kishimoto@qmul.ac.uk', '156 West End Lane, London NW6 1FU', TO_DATE('2025-11-08', 'YYYY-MM-DD'));
-- 4. Active Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Student', 'Aisha', 'Gupta', 'aisha.gupta@qmul.ac.uk', '22 Cloudesley Road, London N1 0EQ', TO_DATE('2027-04-21', 'YYYY-MM-DD'));
-- 5. Active Status 
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Student', 'Diana', 'Johnson', 'diana.johnson@qmul.ac.uk', '4 Clarendon Road, London W5 1AB', TO_DATE('2027-04-21', 'YYYY-MM-DD')); 
-- 6. Active Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) 
VALUES (MemberId_Seq.NEXTVAL, 'Student', 'Ethan', 'Williams', 'ethan.williams@qmul.ac.uk', '15 Baker Street, London NW1 5LA', TO_DATE('2027-06-15', 'YYYY-MM-DD'));
-- 7. Active Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) 
VALUES (MemberId_Seq.NEXTVAL, 'Student', 'Sophia', 'Taylor', 'sophia.taylor@qmul.ac.uk', '8 Primrose Avenue, London SW1A 1AA', TO_DATE('2027-08-30', 'YYYY-MM-DD'));
-- 8. Active Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) 
VALUES (MemberId_Seq.NEXTVAL, 'Student', 'Liam', 'Brown', 'liam.brown@qmul.ac.uk', '34 Kensington Road, London W8 5NX', TO_DATE('2027-12-10', 'YYYY-MM-DD'));
-- 9 . Expired Student
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, JoinDate, ExpiredDate, MembershipStatus) VALUES 
(MemberId_Seq.NEXTVAL, 'Student', 'John', 'Smith', 'john.smith@qmul.ac.uk', '30A Cheshire Street, London E2 6BC',  TO_DATE('2022-10-15', 'YYYY-MM-DD'), TO_DATE('2023-10-15', 'YYYY-MM-DD'), 'Expired');
-- 10. Suspended Student 
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Student', 'Jane', 'Davis', 'jane.davis@qmul.ac.uk', '2 Bowes Road, London W3 7AA', TO_DATE('2026-05-15', 'YYYY-MM-DD'));
-- 11. Active Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Sam', 'White', 'sam.white@qmul.ac.uk', '75 Chancery Lane, London WC2A 1AA', TO_DATE('2025-08-31', 'YYYY-MM-DD'));
-- 12. Active Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Chris', 'Williams', 'chris.williams@qmul.ac.uk', '10A Connaught Avenue, London E4 7AA', TO_DATE('2026-06-30', 'YYYY-MM-DD'));
-- 13. Active Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Wiktoria', 'Østergård', 'wiktoria.ostergard@qmul.ac.uk', '4 Basil St, London SW3 1AJ', TO_DATE('2025-09-03', 'YYYY-MM-DD'));
-- 14. Active Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Johnathon', 'Ismoilov', 'johnathon.ismoilov@qmul.ac.uk', '37 Sterne St, London W12 8AB', TO_DATE('2026-10-26', 'YYYY-MM-DD'));
-- 15. Active Staff 
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Burgheard', 'Yilmaz', 'burgheard.yilmaz@qmul.ac.uk', '55B Crownfield Road, London E15 2AB', TO_DATE('2027-01-01', 'YYYY-MM-DD'));
-- 16. Active staff 
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Gretel', 'Guo', 'gretel.guo@qmul.ac.uk', '15 Kossuth St, London SE10 0AA', TO_DATE('2027-04-21', 'YYYY-MM-DD')); 
-- 17. Active Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Serafino', 'Planche', 'Serafino.Planche@qmul.ac.uk', '39 Westferry Circus, London E14 8RW', TO_DATE('2025-03-08', 'YYYY-MM-DD'));
-- 18. Active Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Micha', 'Alfaro', 'micha.alfaro@qmul.ac.uk', '1 Waterfront Drive, London SW10 0AA', TO_DATE('2026-01-01', 'YYYY-MM-DD'));
-- 19. Expired Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, JoinDate, ExpiredDate, MembershipStatus) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Khalid', 'Abdullah', 'khalid.abdullah@qmul.ac.uk', '42 Sherwood Road, London NW4 1AD', TO_DATE('2023-11-13', 'YYYY-MM-DD'), TO_DATE('2024-11-13', 'YYYY-MM-DD'), 'Expired');
-- 20. Suspended Staff
INSERT INTO Member (MemberId, MemberType, FirstName, LastName, Email, Address, ExpiredDate) VALUES 
(MemberId_Seq.NEXTVAL, 'Staff', 'Rosabella', 'Cunningham', 'rosabella.cunningham@qmul.ac.uk', '27 Leadenhall St, London EC3A 1AA', TO_DATE('2025-03-25', 'YYYY-MM-DD'));

----------- RESOURCES -----------
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Book', 2, 10, 7, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Book', 2, 11, 7, 'Unavailable');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Book', 2, 12, 7, 'Unavailable');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Book', 2, 13, 14, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Book', 2, 14, 14, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Book', 3, 10, 21, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Book', 3, 11, 21, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'eBook', NULL, NULL, 7, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'eBook', NULL, NULL, 7, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'eBook', NULL, NULL, 7, 'Unavailable');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'eBook', NULL, NULL, 14, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'eBook', NULL, NULL, 14, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'eBook', NULL, NULL, 14, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'eBook', NULL, NULL, 14, 'Unavailable');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Device', 1, 1, 0, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Device', 1, 2, 0, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Device', 1, 3, 5, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Device', 1, 4, 5, 'Available');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Device', 1, 5, 5, 'Unavailable');
INSERT INTO Resources (ResourcesId, ResourcesType, FloorNumber, ShelfNumber, LoanPeriod, ResourcesStatus) VALUES
(ResourcesId_Seq.NEXTVAL, 'Device', 1, 6, 3, 'Available');

----------- BOOK -----------
-- 1
INSERT INTO Book (ISBN, BookCategory, BookTitle, Author, Publisher) VALUES 
('978-0-74-327356-5', 'Literature', 'The Great Gatsby', 'F. Scott Fitzgerald', 'Scribner');
-- 2
INSERT INTO Book (ISBN, BookCategory, BookTitle, Author, Publisher) VALUES 
('978-0-68-480154-4', 'Literature', 'Tender is the night', 'F. Scott Fitzgerald', 'Pocket Books');
-- 3
INSERT INTO Book (ISBN, BookCategory, BookTitle, Author, Publisher) VALUES 
('978-0-07-802215-9', 'Computer Science', 'Database System Concepts - 7th Edition', 'Abraham Silberschatz', 'McGraw-Hill Education');
-- 4
INSERT INTO Book (ISBN, BookCategory, BookTitle, Author, Publisher) VALUES 
('978-1-43-024209-3', 'Computer Science', 'Beginning Database Design: From Novice to Professional - 2nd Edition', 'Clare Churcher', 'Apress');
-- 5 eBook multiple courses recommended this book
INSERT INTO Book (ISBN, BookCategory, BookTitle, Author, Publisher) VALUES 
('978-1-09-810293-7', 'Mathematics', 'Essential Math for Data Science: Take Control of Your Data with Fundamental Linear Algebra, Probability, and Statistics', 'Thomas Nield', 'O''Reilly Media');

----------- BOOKCOPY -----------
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (1, '978-0-74-327356-5');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (2, '978-0-74-327356-5');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (3, '978-0-74-327356-5');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (4, '978-0-68-480154-4');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (5, '978-0-68-480154-4');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (6, '978-0-07-802215-9');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (7, '978-0-07-802215-9');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (8, '978-1-43-024209-3');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (9, '978-1-43-024209-3');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (10, '978-1-43-024209-3');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (11, '978-1-09-810293-7');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (12, '978-1-09-810293-7');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (13, '978-1-09-810293-7');
INSERT INTO BookCopy (ResourcesId, ISBN) VALUES (14, '978-1-09-810293-7');

----------- DEVICE -----------
-- Resource 15
INSERT INTO Device (ResourcesId, DeviceCategory, Brand, Model) VALUES (15, 'Tablet', 'Apple', 'iPad Pro');
-- Resource 16
INSERT INTO Device (ResourcesId, DeviceCategory, Brand, Model) VALUES (16, 'Tablet PC', 'Samsung', 'Galaxy Tab S8');
-- Resource 17
INSERT INTO Device (ResourcesId, DeviceCategory, Brand, Model) VALUES (17, 'Laptop', 'Dell', 'XPS 13');
-- Resource 18
INSERT INTO Device (ResourcesId, DeviceCategory, Brand, Model) VALUES (18, 'Laptop', 'Apple', 'MacBook Air M1');
-- Resource 19
INSERT INTO Device (ResourcesId, DeviceCategory, Brand, Model) VALUES (19, 'Laptop', 'HP', 'Spectre x360');
-- Resource 20
INSERT INTO Device (ResourcesId, DeviceCategory, Brand, Model) VALUES (20, 'E-Reader', 'Amazon', 'Kindle Paperwhite');

----------- LOAN -----------
-- Current overdue loan (> 10 days for suspended members) and return date is null
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 10, 14, TO_DATE('02/11/2024', 'DD/MM/YYYY'), 'Overdue');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 20, 19, TO_DATE('11/11/2024', 'DD/MM/YYYY'), 'Overdue');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 5, 2, TO_DATE('12/11/2024', 'DD/MM/YYYY'), 'Overdue'); 
-- Current Loan with loandate default sysdate and return date is null
INSERT INTO Loan (LoanId, MemberId, ResourcesId) VALUES 
(LoanId_Seq.NEXTVAL, 5, 4);
INSERT INTO Loan (LoanId, MemberId, ResourcesId) VALUES 
(LoanId_Seq.NEXTVAL, 5, 6);
INSERT INTO Loan (LoanId, MemberId, ResourcesId) VALUES 
(LoanId_Seq.NEXTVAL, 5, 8);
INSERT INTO Loan (LoanId, MemberId, ResourcesId) VALUES 
(LoanId_Seq.NEXTVAL, 5, 11);
INSERT INTO Loan (LoanId, MemberId, ResourcesId) VALUES 
(LoanId_Seq.NEXTVAL, 2, 17);
-- Prior Loan
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 4, 3, TO_DATE('15/01/2024', 'DD/MM/YYYY'), TO_DATE('25/01/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 4, 10, TO_DATE('01/02/2024', 'DD/MM/YYYY'), TO_DATE('10/02/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 2, 2, TO_DATE('15/01/2024', 'DD/MM/YYYY'), TO_DATE('21/01/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 2, 2, TO_DATE('01/02/2024', 'DD/MM/YYYY'), TO_DATE('07/02/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 2, 2, TO_DATE('15/03/2024', 'DD/MM/YYYY'), TO_DATE('20/03/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 3, 5, TO_DATE('01/03/2025', 'DD/MM/YYYY'), TO_DATE('13/03/2025', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 4, 5, TO_DATE('01/04/2024', 'DD/MM/YYYY'), TO_DATE('15/04/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 1, 7, TO_DATE('12/05/2024', 'DD/MM/YYYY'), TO_DATE('01/06/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 6, 7, TO_DATE('01/06/2024', 'DD/MM/YYYY'), TO_DATE('21/06/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 7, 7, TO_DATE('01/07/2024', 'DD/MM/YYYY'), TO_DATE('21/07/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 8, 7, TO_DATE('12/08/2024', 'DD/MM/YYYY'), TO_DATE('01/09/2024', 'DD/MM/YYYY'), 'Returned');
INSERT INTO Loan (LoanId, MemberId, ResourcesId, LoanDate, ActualReturnDate, LoanStatus) VALUES 
(LoanId_Seq.NEXTVAL, 12, 9, TO_DATE('01/09/2024', 'DD/MM/YYYY'), TO_DATE('07/09/2024', 'DD/MM/YYYY'), 'Returned');

----------- RESERVATION -----------
-- Current reservations with SYSDATE for ReservationDate
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 2, 14);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 3, 4);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 2, 8);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 4, 8);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 5, 8);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 5, 14);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 6, 17);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 6, 2);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 6, 19);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 7, 6);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 7, 11);
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId) VALUES 
(ReservationId_Seq.NEXTVAL, 7, 19);
-- Prior reservations
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId, ReservationDate) VALUES 
(ReservationId_Seq.NEXTVAL, 8, 5, TO_DATE('16/01/2024', 'DD/MM/YYYY'));
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId, ReservationDate) VALUES 
(ReservationId_Seq.NEXTVAL, 9, 5, TO_DATE('17/01/2024', 'DD/MM/YYYY'));
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId, ReservationDate) VALUES 
(ReservationId_Seq.NEXTVAL, 13, 5, TO_DATE('18/01/2024', 'DD/MM/YYYY')); 
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId, ReservationDate) VALUES 
(ReservationId_Seq.NEXTVAL, 12, 5, TO_DATE('06/02/2024', 'DD/MM/YYYY'));
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId, ReservationDate) VALUES 
(ReservationId_Seq.NEXTVAL, 12, 14, TO_DATE('02/05/2024', 'DD/MM/YYYY'));
INSERT INTO Reservation (ReservationId, MemberId, ResourcesId, ReservationDate) VALUES 
(ReservationId_Seq.NEXTVAL, 15, 14, TO_DATE('03/05/2024', 'DD/MM/YYYY'));

----------- OFFER -----------
-- Current Offers with default offerdate as sysdate
INSERT INTO Offer (ReservationId) VALUES (1);
INSERT INTO Offer (ReservationId) VALUES (3);
INSERT INTO Offer (ReservationId) VALUES (6);
INSERT INTO Offer (ReservationId) VALUES (7);
INSERT INTO Offer (ReservationId) VALUES (8);
INSERT INTO Offer (ReservationId) VALUES (9);
INSERT INTO Offer (ReservationId) VALUES (10);
INSERT INTO Offer (ReservationId) VALUES (11);
INSERT INTO Offer (ReservationId) VALUES (12);

-- Prior offers
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(13, TO_DATE('17/01/2024', 'DD/MM/YYYY'), TO_DATE('18/01/2024', 'DD/MM/YYYY'), 'Declined');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(13, TO_DATE('02/02/2024', 'DD/MM/YYYY'), TO_DATE('04/02/2024', 'DD/MM/YYYY'), 'Declined');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(13, TO_DATE('05/02/2024', 'DD/MM/YYYY'), NULL, 'Expired');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(14, TO_DATE('18/01/2024', 'DD/MM/YYYY'), TO_DATE('19/01/2024', 'DD/MM/YYYY'), 'Accepted');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(15, TO_DATE('02/02/2024', 'DD/MM/YYYY'), NULL, 'Expired');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(15, TO_DATE('06/02/2024', 'DD/MM/YYYY'), TO_DATE('07/02/2024', 'DD/MM/YYYY'), 'Declined');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(15, TO_DATE('22/02/2024', 'DD/MM/YYYY'), TO_DATE('22/02/2024', 'DD/MM/YYYY'), 'Accepted');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(16, TO_DATE('08/02/2024', 'DD/MM/YYYY'), TO_DATE('08/02/2024', 'DD/MM/YYYY'), 'Accepted');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(17, TO_DATE('03/05/2024', 'DD/MM/YYYY'), NULL, 'Expired');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(17, TO_DATE('21/05/2024', 'DD/MM/YYYY'), TO_DATE('21/05/2024', 'DD/MM/YYYY'), 'Accepted');
INSERT INTO Offer (ReservationId, OfferDate, ResponseDate, OfferStatus) VALUES 
(18, TO_DATE('07/05/2024', 'DD/MM/YYYY'), TO_DATE('07/05/2024', 'DD/MM/YYYY'), 'Accepted');

----------- COURSE -----------
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'American Literature');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Database Systems');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Computer Programming');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Behavioral Psychology');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Corporate Strategy');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Organizational Behavior');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'International Law');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Applied Mathematics');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Big Data Analytics');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Introduction to AI/ML');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Screenwriting: The Mechanics of Story');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Media and Communication Capstone');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Professional Practice in Media Production');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Introduction to Music Production with Ableton Live');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'History of Technology');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Introduction to Genetics');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Introduction to Pharmacology');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Conceptual Physics');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'Philosophy of Religion');
INSERT INTO Course (CourseId, CourseName) VALUES (CourseId_Seq.NEXTVAL, 'The Jazz Age in Film and Literature'); 

----------- BCR -----------
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-0-74-327356-5', 1);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-0-68-480154-4', 1);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-0-07-802215-9', 2);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-1-43-024209-3', 2);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-0-07-802215-9', 3);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-1-09-810293-7', 2);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-1-09-810293-7', 8);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-1-09-810293-7', 9);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-1-09-810293-7', 10);
INSERT INTO BookCourseRecommendation (ISBN, CourseId) VALUES ('978-0-74-327356-5', 20);



-----------------------------------------------------------------------------------------------------



----------- VIEWS -----------
-- VIEW 1: View all pending overdue loans, including the member’s details,  the resource information and overdue days
CREATE VIEW PendingOverdueLoans AS 
SELECT l.LoanId, l.LoanDate, l.ActualReturnDate, l.LoanStatus, m.MemberId, 	
m.FirstName || ' ' || m.LastName AS FullName, m.Email, r.ResourcesId, r.ResourcesType, 	
trunc(SYSDATE - (l.LoanDate + r.LoanPeriod)) AS OverdueDays 
FROM Loan l 
JOIN Member m ON l.MemberId = m.MemberId 
JOIN Resources r ON l.ResourcesId = r.ResourcesId 
WHERE l.LoanStatus = 'Overdue' AND l.ActualReturnDate IS NULL;

-- VIEW 2: View members who are on the waiting list for resource loan by each resource
CREATE VIEW ReservationList AS SELECT m.FirstName, m.LastName, m.email, r.ResourcesId, r.ReservationId 
FROM Reservation r 
JOIN Member m ON r.MemberId = m.MemberId 
WHERE r.ReservationStatus = 'Reserved' 
ORDER BY r.ResourcesId, r.ReservationId;

-- VIEW 3: View popular resources by its ranking
CREATE VIEW PopularResourcesRanking AS SELECT r.ResourcesType, 
CASE WHEN r.ResourcesType IN ('Book', 'eBook') THEN b.ISBN || ' ' || b.BookTitle 	
WHEN r.ResourcesType = 'Device' THEN d.DeviceCategory || ' ' || d.Model 	
END AS ResourcesName, COUNT(l.loanId) AS LoanCount 
FROM Resources r 
JOIN Loan l ON r.ResourcesId = l.ResourcesId 
LEFT JOIN BookCopy bc ON R.ResourcesId = bc.ResourcesId 
LEFT JOIN Book b ON b.ISBN = bc.ISBN 
LEFT JOIN Device d ON r.ResourcesId = d.ResourcesId 
GROUP BY r.ResourcesType, 
CASE WHEN r.ResourcesType IN ('Book', 'eBook') THEN b.ISBN || ' ' || b.BookTitle 	
WHEN r.ResourcesType = 'Device' THEN d.DeviceCategory || ' ' || d.Model 	END 
ORDER BY LoanCount DESC;

-- VIEW 4: View each resource, with its course name (if available), and where these are located in the library
CREATE VIEW ResourcesDetails AS 
SELECT r.*, 
CASE WHEN r.ResourcesType IN ('Book', 'eBook') THEN b.BookTitle 
WHEN r.ResourcesType = 'Device' THEN d.Brand || ' ' || d.Model 
END AS ResourcesName, c.CourseName 
FROM Resources r 
LEFT JOIN Device d ON r.resourcesId = d.resourcesId 
LEFT JOIN BookCopy bc ON r.resourcesId = bc.resourcesId 
LEFT JOIN Book b ON bc.ISBN = b.ISBN 
LEFT JOIN BookCourseRecommendation bcr ON b.ISBN = bcr.ISBN 
LEFT JOIN Course c ON bcr.CourseId = c.CourseId;



-----------------------------------------------------------------------------------------------------



----------- QUERIES -----------
----------- SIMPLE QUERIES -----------
-- QUERY 1: List all books that are related to ‘database’. 
SELECT ISBN, BookTitle, Author, Publisher FROM Book WHERE LOWER(BookTitle) LIKE '%database%';

-- QUERY 2: Find resources that can only be used within the library.
SELECT ResourcesId, ResourcesType, ShelfNumber, FloorNumber 
FROM Resources WHERE loanPeriod = 0; 
-- assumption that resources that can only be used within library has 0 day loan period

-- Query 3: Find all members whose membership status is Suspended. 
SELECT MemberId, MemberType, FirstName, LastName, OverdueFine, MembershipStatus FROM Member 
WHERE MembershipStatus = 'Suspended';

-- QUERY 4: Find all available resources of device type 
SELECT ResourcesId, ResourcesType, ResourcesStatus, LoanPeriod FROM Resources 
WHERE ResourcesType = 'Device' AND ResourcesStatus = 'Available';

----------- INTERMEDIATE QUERIES -----------
-- Query 5: List all active overdue loans, along with a due date for return 
SELECT l.LoanId, l.MemberId, r.ResourcesType, l.LoanDate, l.ActualReturnDate,
l.LoanDate + r.LoanPeriod AS DueDate, l.LoanStatus 
FROM Loan l 
JOIN Resources r ON l.ResourcesId = r.ResourcesId WHERE l.LoanStatus = 'Overdue';

-- Query 6: Find all physical book copies of 'Literature' category
SELECT r.ResourcesId, r.ResourcesType, b.BookTitle, b.BookCategory, r.ResourcesStatus, r.ShelfNumber, r.FloorNumber
FROM Resources r
JOIN BookCopy bc ON r.ResourcesId = bc.ResourcesId
JOIN Book b ON bc.ISBN = b.ISBN
WHERE r.ResourcesType = 'Book' AND b.BookCategory = 'Literature';


-- Query 7: Show all active reservations made by a specific member
SELECT res.ReservationId, res.ReservationDate, res.MemberId, 
m.FirstName || ' ' || m.LastName AS MemberName, r.ResourcesId, r.ResourcesType, 
CASE WHEN r.ResourcesType IN ('Book', 'eBook') THEN b.BookTitle 
WHEN r.ResourcesType = 'Device' THEN d.deviceCategory || ' ' || d.Model 
END AS ResourcesName, res.ReservationStatus 
FROM Reservation res 
JOIN Resources r ON res.ResourcesId = r.ResourcesId 
LEFT JOIN BookCopy bc ON r.ResourcesId = bc.ResourcesId 
LEFT JOIN Book b ON bc.ISBN = b.ISBN 
LEFT JOIN Device d ON r.ResourcesId = d.ResourcesId 
JOIN Member m ON res.MemberId = m.MemberId 
WHERE res.MemberId = 2 AND res.ReservationStatus = 'Reserved';  

-- Query 8: Find available recommended book copies for a specific course
SELECT c.CourseName, r.ResourcesId, r.ResourcesType, b.BookTitle, b.Author, r.floorNumber, r.shelfNumber, r.loanPeriod 
FROM BookCourseRecommendation bcr 
JOIN Course c ON bcr.CourseId = c.CourseId 
JOIN Book b ON bcr.ISBN = b.ISBN 
JOIN BookCopy bc ON b.ISBN = bc.ISBN 
JOIN Resources r ON bc.ResourcesId = r.ResourcesId 
WHERE LOWER(c.CourseName) LIKE '%data%' AND r.ResourcesStatus = 'Available';

----------- ADVANCED QUERIES -----------
-- Query 9: Count the number of resources currently borrowed by each member
SELECT m.MemberType, m.MemberId, m.FirstName || ' ' || m.LastName AS FullName, 
COUNT(l.LoanId) AS ActiveLoanCount 
FROM Loan l 
JOIN Member m ON l.MemberId = m.MemberId 
WHERE l.LoanStatus IN ('Loaned', 'Overdue') 
GROUP BY m.MemberType, m.MemberId, m.FirstName || ' ' || m.LastName 
ORDER BY m.MemberType, ActiveLoanCount DESC;

-- Query 10: Find the popular loaned books for the current month 
SELECT r.ResourcesType, b.BookTitle, TO_CHAR(l.LoanDate, 'YYYY-MM') AS LoanMonth, COUNT(l.LoanId) AS LoanCount
FROM Resources r JOIN Loan l ON r.ResourcesId = l.ResourcesId 
JOIN BookCopy bc ON r.ResourcesId = bc.ResourcesId 
JOIN Book b ON bc.ISBN = b.ISBN 
WHERE TO_CHAR(l.LoanDate, 'YYYY-MM') = TO_CHAR(SYSDATE, 'YYYY-MM') 
GROUP BY r.ResourcesType, b.BookTitle, TO_CHAR(l.LoanDate, 'YYYY-MM') 
ORDER BY LoanCount DESC FETCH FIRST 5 ROWS ONLY; 

-- Query 11: Find the top 3 members who have borrowed the most resources
SELECT m.MemberId, m.FirstName || ' ' || m.LastName AS FullName, m.MemberType, 
COUNT(l.LoanId) AS TotalLoans 
FROM Loan l 
JOIN Member m ON l.MemberId = m.MemberId 
GROUP BY m.MemberId, m.FirstName, m.LastName, m.MemberType 
ORDER BY TotalLoans DESC 
FETCH FIRST 3 ROWS ONLY;

-- Query 12: Find number of book copies per recommended book per course
SELECT c.CourseName, b.BookTitle, COUNT(bc.ResourcesId) AS CopiesCount 
FROM BookCourseRecommendation bcr 
JOIN Course c ON bcr.CourseId = c.CourseId 
JOIN Book b ON bcr.ISBN = b.ISBN 
JOIN BookCopy bc ON b.ISBN = bc.ISBN 
GROUP BY c.CourseName, b.BookTitle 
ORDER BY c.CourseName;
