<div align="justify">
  
# About this Repository ℹ️

This repository contains the project I did with two coursemates as a part of the coursework for ECS740P - Database Systems. <br>
Together, we designed and implemented database systems for the Collge Library Systems.

<br>

## Task ☑️
Design and implement an Oracle application that satisfies the requirements. This includes setting up a database schema and providing access methods to this in the form of queries and views. The steps for doing this include:

- Creating a conceptual schema in the form of an ER or UML diagram.
- Deriving a relational schema from the ER diagram.
- Normalising the relations.
- Implementing this schema by using SQL in Oracle.
- Populating the database with a set of typical data. The data should be significant but
manageable.
- Defining specialised views which are appropriate to various sub-groups of users.
- Defining SQL queries which could be used as canned queries for naive users.


<br>

## Requirements ❗️
### General Functionality
1. **Resource Management**:
- Track various resources, including physical books, eBooks, and electronic devices (e.g., laptops, tablets).
- Record details such as:
  - Class number (if applicable).
  - Number of copies available.
  - Physical location (floor number and shelf number, if applicable).
  - Digital access limits for eBooks.

2. **Member Management**:
- Maintain records of library members, including students and staff.
- Enforce borrowing limits:
  - Students: Maximum of 5 items at a time.
  - Staff: Maximum of 10 items at a time.
    
3. **Loan and Reservation Management**:
- Support different loan periods:
  - Standard: 3 weeks.
  - Short loan: 3 days.
  - Library-only resources.
-  Manage reservations:
  - Notify the earliest reservation holder when an item becomes available.
  - Handle unclaimed reservations and cancellation after three unsuccessful attempts.

4. **Fines and Suspensions**:
- Calculate overdue fines at a rate of £1 per day.
- Suspend members owing more than £10 in fines until all items are returned and fines are paid.

5. **Historical Records**:
- Maintain records of previous loans to identify popular resources.

6. **Suspension Tracking**:
- Maintain a list of members currently suspended due to overdue loans or unpaid fines.

<br>

### Specific Records to Be Maintained
- **Resources**: Details of all items in the library, including physical and digital resources.
- **Library Members**: Information on all students and staff who are members.
- **Reservations**: Current reservations and records of failed loan offers.
- **Loans**: Active and overdue loans, including overdue statuses.
- **Fines**: Amounts owed by members and suspension statuses.
- **Loan History**: Historical data on previously borrowed resources.

<br>

## Environment 👩🏻‍💻 

<div align="center">
  <img src="https://img.shields.io/badge/Oracle%20Live%20SQL-f1efec.svg?style=flat-square&logo=data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iX+ugiOydtOyWtF8xIiBkYXRhLW5hbWU9IuugiOydtOyWtCAxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNDUgNDUiPgogIDxpbWFnZSB3aWR0aD0iNDUiIGhlaWdodD0iNDUiIHhsaW5rOmhyZWY9ImRhdGE6aW1hZ2UvanBlZztiYXNlNjQsLzlqLzRBQVFTa1pKUmdBQkFRQUFBUUFCQUFELzRnSFlTVU5EWDFCU1QwWkpURVVBQVFFQUFBSElBQUFBQUFRd0FBQnRiblJ5VWtkQ0lGaFpXaUFINEFBQkFBRUFBQUFBQUFCaFkzTndBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBUUFBOXRZQUFRQUFBQURUTFFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQWxrWlhOakFBQUE4QUFBQUNSeVdGbGFBQUFCRkFBQUFCUm5XRmxhQUFBQktBQUFBQlJpV0ZsYUFBQUJQQUFBQUJSM2RIQjBBQUFCVUFBQUFCUnlWRkpEQUFBQlpBQUFBQ2huVkZKREFBQUJaQUFBQUNoaVZGSkRBQUFCWkFBQUFDaGpjSEowQUFBQmpBQUFBRHh0YkhWakFBQUFBQUFBQUFFQUFBQU1aVzVWVXdBQUFBZ0FBQUFjQUhNQVVnQkhBRUpZV1ZvZ0FBQUFBQUFBYjZJQUFEajFBQUFEa0ZoWldpQUFBQUFBQUFCaW1RQUF0NFVBQUJqYVdGbGFJQUFBQUFBQUFDU2dBQUFQaEFBQXRzOVlXVm9nQUFBQUFBQUE5dFlBQVFBQUFBRFRMWEJoY21FQUFBQUFBQVFBQUFBQ1ptWUFBUEtuQUFBTldRQUFFOUFBQUFwYkFBQUFBQUFBQUFCdGJIVmpBQUFBQUFBQUFBRUFBQUFNWlc1VlV3QUFBQ0FBQUFBY0FFY0Fid0J2QUdjQWJBQmxBQ0FBU1FCdUFHTUFMZ0FnQURJQU1BQXhBRGIvMndCREFBTUNBZ0lDQWdNQ0FnSURBd01EQkFZRUJBUUVCQWdHQmdVR0NRZ0tDZ2tJQ1FrS0RBOE1DZ3NPQ3drSkRSRU5EZzhRRUJFUUNnd1NFeElRRXc4UUVCRC8yd0JEQVFNREF3UURCQWdFQkFnUUN3a0xFQkFRRUJBUUVCQVFFQkFRRUJBUUVCQVFFQkFRRUJBUUVCQVFFQkFRRUJBUUVCQVFFQkFRRUJBUUVCQVFFQkFRRUJEL3dBQVJDQUF0QUMwREFTSUFBaEVCQXhFQi84UUFHd0FBQVFVQkFRQUFBQUFBQUFBQUFBQUFCZ0FFQlFjSUFRTC94QUE0RUFBQkF3SURBZ2tMQlFFQUFBQUFBQUFCQWdNRUFBVUdCeEVVSVFnU0V6RlRWRldTMFJjaUpEUlJWbUZ4ZEtMU0ZTTkJVck9CLzhRQUd3RUFBZ01BQXdBQUFBQUFBQUFBQUFBQUFBTUNCQWNGQmdqL3hBQXRFUUFDQVFNQ0F3UUxBQUFBQUFBQUFBQUJBZ01BQkJFaDBRVVNVVUZoa2FFR0J4WVhVbE5pY29HaXNmL2FBQXdEQVFBQ0VRTVJBRDhBQUlNR0hiWWJNQ0JHYmp4NDZBMjAwMm5SS0VqbUFGR3R1eXB4emVzRnJ4OVk3TXU1V2xoNXhtU1loNVYyTVVBRXFjYkhuQk9oMTQyaEdtdXVsQ05YSmtuWlhzTHhtODJMdG1xbkIxb2p5Rk1odUl2bHAxd1VqUWxwTWZtVWs2NkVyQlNPY2pUZldhMjhZbWt3L2prREhmcnBYcDdpVncxbGJoNFNBUVFBQ0NjL1NBdXVUMkVBNDZWVFpCQjBOS3JDenp6Qnd6bVpqdHpFbUZNTG9za1Baa1IxSkNVSlhLY1NwWkw3aVVBSkMxQlFCRy9jZ2I2cjJsU3FxT1ZVNUE3ZXRXcldXU2VGWkpVNUdJMVVuT083SXBWRTN2Q2VHOFNMYWN2MWxpVGxNQWhzdk5CUlNEcHFCcjhoVXRTcUtzeUhLbkJwc2tTVEx5U0FFZERxS05mSXRtcDdrWEx1anhyMDNrbG11NnJpTjRHdWFpRXFWb0VwNWdDU2VmMkExdXZabSt1TWZkNFU3dGtkQWtySWxzbjBlUU4zRzZKZndydGZzL0I4Ujh0cXg3M2tYL3lrL2Jlc0oyZktmTSswM09OY1hzdEhia2lPdmpxaVRHeVdYaC9WWVF0S3RQa29VY04yckh6cWlsdmd0NFFVUWtxMEVTYnpBYWsrdWV3R3RVN00zMXhqN3ZDblZ0am9FaFoydGsranZqZHh1aVY4S1luQkk0eGhYUGdOcXJUK250MWNIbWtoWDhGeC9HRlljeEpsam1aaUM2S3VVYktkTmxRcENVN0piV2xwWVRvT2NCeHhhdFQvQUQ1MVJma1d6VTl5TGwzUjQxdTNabSt1TWZkNFV0bWI2NHg5M2hVRHdDRmprc2ZMYW5wNnhiNk5RaXdwZ2Zkdlh2WTQvYXNYdXUvaFRxMlJXRXlWa1hLTXIwZDhhQkxuUkszNzBVQVpWWTFkekh5NHc1anQrM3BndVh5M016VnhrdWNvbHBTMGdsSVVRTlIveWphMWV0TCtta2Y0cnJucXp5dWJISDdWaTkxMzhLZFc2SXdtUXNpNXhsZnNQalFKYzZKVy9laW91bmRzOVpYOVBJL3lYUUtLNXNjZnRXTDNYZndwYkhIN1ZpOTEzOEthMW5qaFRjS2E1Y0hlNVlmdDl2d2RHdlg2MHhJZVd0NllwbmsrVFVnQUFCQ3RkZU9hQnJRZEsvL1oiLz4KPC9zdmc+">
</div>

<br>
  
## Stack 🛠️

<div align="center">
   <img src="https://img.shields.io/badge/SQL-0a7dd7.svg?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAC0AAAAtCAYAAAA6GuKaAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAFFUlEQVRYhe3Z7Y9dVRUG8N+eOTN3OsxLS7XFWgtoqSgBjdqU4EsiSkiMfvU/4J/yLzB+xphADAZfAxprFSGGYtS21jrY0jLtDLf3HD+stb1nbnpbqOklJHclO2fOmX32efaznvXsNZnSdZ2PWix82ADuJuagZxVz0LOKOehZxRz0rGIOelbxkQW9hmN4Di/iHXS3GP/Bj/ClfPdj+D6ex/Up79TR4ip+iGcxQOm67kTbtj9o27argd38zrfQTAP9CZzE1/AoNqZs8EBe38MKHsOT+CL23YGcgnU8jq/i4dzM1VLKdimlP3c5x9T2s8FxfDd3ti5YqTtuex/9PV7GRRzGM3gaD+S8gmGOer+QABbz/pP4HrawXUoZ4ixe77ruOJZwHn/F5WnAG8HssQSykGMLb+ICtnOxM/gddvA5nMCRBCTnXchNXe6tfRSHsCqk+BnB9jUhuYewr5RS62uUoxJ2S9CLCaqvn3/ipWT2XznnbfxbyOMgNu2VxRZ+jVfxVv7uML4upDfIddaFrPYLnR8V0qugax1MjUakczsnVnHtCNZew7neYjXlu6JgdwR7BLtn8FO8ns8PC7YfF2zXrBzJjbdJ2HLv26X381TQg9x9f+Kn8OXczLmcd15I5no+20rwNYZ4N8HLd9/J68he9hpTnCFj0S3suOs6bdtqRLqv5Qcrkxv4hijSK4KN0/gJXsGNfG90mw9zB8amRIebObr+37Bt2+q6ToNL+KOwsQXB/AHhCg+KFDZ5PxKS2MD9uZkaC8ap7t/357xf0LuClK6CrVFK0eAvOeEX+XwgNPis8OAK4iFhcftzE4/hvt7HbuaGruf9SEjjhjtnZBL0ja7rtk0wXaMR7nDZWENLQirH8Wlx8hG6fyLBF1FoK721loWjHErwS/i4yFq/0Aj97+ZmloydpWLaFJmtBtEKYnfRNcKa7jcuxiY/PLC3eBZybgU6WeWbwru3cr0V4RIncu2+pV3CP5KcQ+KEXMv1VpKsk7npkiScz/FukxOeFAfGQu74UH5s1d64nR0dxKkE+nYyuCEyc8DYLUaiqF8Q7nIy563kO2tCnuvCBFaTiFdEb3S2wWfxHeEW1T3q8TtZRDvGNlZENjZy4U18PjdbNVyMD65hgjgrmqznc94mvm2c1X1J5DEhi1Uh36O5zqtNslC11z9gJmMo0nNa+HURunvCOCvVLfqnWklwl5KtX4oD6GJ+c00UdNU0NKWUvo9vdl33FcH+o02ytzsBeNS7r+MCfoUfC4ssycaVZOcRY91OymgkDqSXBcNv5vNBjn7c7K2hlFJPzf1d153Cgw3+ht/a67HDfGnRuEP7k9Dhz4TjED1GLebLeR0KxznSW69NMKNca9W46C/iD3ldFpZZO01oSynLWO+67gHsVtAviXZwOdmqmqyAW1Htr4kmp8YO/mx8Yg4SyCmR9mqXS6I1+KZI8W/yvSv5847Q9pJxa8vY7prc6EFcb0RHd1U0OxVkX48V9HbOG/ZAd/h7Pq99cyOqfQ1fELpvRPP0lCj8A7neGbyRLC8lYZNdXpVpIxxm1Ag99xufDxpD0bJOxnoCeyoBD/J6WGTt5wmynprvO27Xaf0/cU44xDWR1qeN9d2Pu2mo7hno90RPfVUwfp9wmkXh828ICX2QnuR/ca9AE3VQba6IjnEgXOZ0/u7mtJdvF/cSNFFEbwnNbohi2xHH/Ja7BF3m/yiaUcxBzyrmoGcVc9Cziv8C9Qp9a29Fk3oAAAAASUVORK5CYII=">
</div>

<br>

## Repository Structure 🌲

```bash
.
├── DB_Coursework_1_solution.pdf 
├── DB_Coursework_1_solution.sql 
└── README.md
```

<br>

`DB_Coursework_1_solution.pdf` includes:
- A list of all assumptions that were made during the design
- The conceptual schema (ER diagram) with an explanation of how the model was derived
- The relational database schema for the chosen application to show how the ER diagram was translated into the relational schema, identifying all primary and foreign keys in the design
- The normalised design for the application with the explanation of why it is in 3rd Normal Form
- A set of 4 view definitions with CREATE view commands and listings of the obtained output 
- 12 meaningful and distinct SQL queries with a listing of the output generated

<br>

`DB_Coursework_1_solution.sql` includes:
- A listing of all the CREATE table commands that were used to set up the database with declarative constraints in the statements to establish primary and foreign keys and perform validation checks on data to be entered
- Triggers to:
  - update overdue fine automatically
  - update membership status to suspend members if their overdue fine is greater than £10
  - ensure loan limit at a time
  - update reservation status
  - ensure no more than 3 offer rows created per reservation Id
- The sample test data
- A set of four CREATE view commands

<br>

## Reflection 🪞
  
<p>Working on the College Library System project was an exciting and rewarding experience, especially since it was my first time designing and implementing a database. I learned a lot about translating complex requirements into a functional database design and used Oracle Live SQL to bring it to life. It wasn’t without its challenges—figuring out how to create a clear and efficient schema took some trial and error, but careful planning and paying attention to details really made a difference. Collaborating with two teammates also helped refine the design and solve problems as they came up. My contributions included assisting with drawing the conceptual and relational diagrams, generating mock data, and creating views and queries to enable key functionalities. Looking ahead, the system can be further improved by adding a user-friendly interface and automating some of the processes to make it even better.</p>

<br>
  
</div>




