# Reasoning and Design Decisions

## 1. Problem Understanding

The pharmacy stores medicines in multiple batches. Each batch can have a different expiry date and quantity.

The main inventory rule is FEFO (First Expiry, First Out). When a medicine is dispensed, the system must:

1. Ignore expired batches.
2. Consider only batches with sellable stock.
3. Select the batch with the earliest expiry date first.
4. Continue to the next earliest batch if more quantity is required.
5. Reject the entire request if the total sellable stock is insufficient.
6. Never allow the frontend to decide which batch is used.

This keeps inventory allocation as a backend responsibility.

---

## 2. Architecture Decision

I chose a modular monolith instead of microservices.

The backend follows this flow:

Routes → Controllers → Services → SQLite Database

### Routes

Routes define the HTTP endpoints and apply middleware such as authentication.

### Controllers

Controllers handle HTTP-specific responsibilities such as reading request data and returning responses.

### Services

Services contain the actual business logic. For example, the dispensing service is responsible for FEFO allocation and inventory validation.

### Database

SQLite is used as the persistent database because the assessment requires real database persistence while keeping the project simple to run locally and inside GitHub Codespaces.

I intentionally avoided unnecessary infrastructure such as Redis, Kubernetes, Elasticsearch, or a separate repository layer because they are not required for this assessment.

---

## 3. Database Design

The database contains separate tables for the main business entities.

### Users

Stores registered users and password hashes.

### Medicines

Stores medicine information and the reorder threshold.

### Batches

Stores individual medicine batches, including:

- Batch number
- Initial quantity
- Current quantity
- Expiry date
- Status

A medicine can have multiple batches.

The combination of `medicine_id` and `batch_number` is unique so that the same batch cannot accidentally be inserted twice.

### Dispensations

Stores each successful dispensing operation.

### Dispensation Items

Stores which batches were consumed and how much quantity was taken from each batch.

This allows a single dispensing request to consume stock from multiple batches while preserving an audit trail.

### Import Tables

Tables were added for the planned messy-import functionality so imported records can be tracked and reported.

### Outbox

An outbox table is included for notification events such as reorder alerts.

---

## 4. FEFO Implementation

The dispensing logic queries eligible batches using:

- Matching medicine
- `ACTIVE` status
- Quantity greater than zero
- Expiry date greater than or equal to the business date

The results are ordered by:

1. Earliest expiry date
2. Batch ID as a deterministic tie-breaker

This means the backend naturally selects the batch that expires first.

For example, if the available batches are:

| Batch | Expiry | Quantity |
|---|---|---:|
| B001 | 2026-12-31 | 100 |
| B002 | 2026-09-17 | 50 |

and 70 units are requested, the system allocates:

- B002 → 50 units
- B001 → 20 units

The frontend does not send a batch ID for dispensing.

---

## 5. Expiry Rules

A batch is considered sellable when:

`expiry_date >= business_date`

Therefore, a medicine expiring on the current business date is still sellable.

A batch is expired when:

`expiry_date < business_date`

Expired batches are not included in sellable stock and cannot be dispensed.

The persistent batch status is limited to:

- `ACTIVE`
- `QUARANTINED`

Expiry-related states are derived from the expiry date rather than stored as permanent statuses. This avoids stale states when the date changes.

---

## 6. Transaction Safety

Dispensing changes multiple database records:

1. Create the dispensation record.
2. Reduce quantities from one or more batches.
3. Create dispensation item records.

These operations are performed inside a SQLite database transaction.

If any operation fails, the transaction is rolled back.

This prevents situations where stock is reduced but the corresponding dispensing record is missing.

The system also checks that the requested quantity is available before modifying inventory.

There is no partial fulfillment when sellable stock is insufficient.

---

## 7. Business Date Handling

I avoided scattering direct date calculations throughout the business logic.

A business date is resolved once for each request and attached to the request as:

`req.businessDate`

The date utilities also support explicit dates in `YYYY-MM-DD` format.

This makes expiry-related behavior deterministic and makes date-based testing easier.

For example, the same API behavior can be tested against a fixed date instead of depending on the machine's current date.

---

## 8. Authentication Decision

Authentication uses JWT stored in an HttpOnly cookie.

The flow is:

1. User registers.
2. Password is hashed using bcrypt.
3. User logs in.
4. The server creates a JWT.
5. The JWT is stored in an HttpOnly cookie.
6. Protected routes verify the cookie before allowing access.

Passwords are never stored in plain text.

The authentication middleware extracts the authenticated user's ID and makes it available to protected controllers.

---

## 9. Validation and Error Handling

Input validation is performed on the backend because the frontend cannot be trusted to enforce business rules.

Examples of validated values include:

- Required medicine name
- Reorder threshold
- Positive batch quantity
- Valid expiry date
- Positive dispensing quantity
- Valid business dates
- Unique medicine names
- Unique medicine + batch combinations

Errors use HTTP status codes and structured JSON responses.

Examples include:

- `400` for invalid input
- `401` for unauthenticated requests
- `404` for missing resources
- `409` for conflicts such as duplicate records
- `500` for unexpected server errors

---

## 10. Testing and Debugging

I tested the backend incrementally instead of building everything first and testing at the end.

### Database Testing

I verified that:

- SQLite connects successfully.
- The schema is created.
- Required tables exist.
- Foreign keys are enabled.
- The database can store medicine and batch data.

### Authentication Testing

I tested:

- Successful registration
- Duplicate registration
- Successful login
- Access to the authenticated `/me` endpoint
- Access without authentication
- Incorrect password
- Logout followed by an authenticated request

### Medicine and Batch Testing

I tested:

- Creating medicines
- Preventing duplicate medicine names
- Creating batches
- Preventing duplicate medicine/batch combinations
- Expired batch handling
- Batch ordering by expiry date

### Dispensing Testing

I tested the FEFO scenario where a request must consume stock from the earliest-expiring batch before using a later-expiring batch.

I also verified that expired batches are excluded from dispensing.

---

## 11. Debugging Approach

When an issue occurred, I isolated the problem by testing the affected layer separately.

For backend problems, I checked:

1. The request URL and HTTP method.
2. Request body.
3. Authentication state.
4. Controller behavior.
5. Service/business logic.
6. SQL query.
7. Database contents.
8. Returned HTTP response.

This made it easier to identify whether an issue was caused by routing, authentication, validation, business logic, or the database.

---

## 12. Current Implementation Status

The current implementation includes the core backend foundation, SQLite persistence, authentication, medicine and batch management, and FEFO dispensing logic.

Some assessment requirements remain to be implemented, including the complete frontend workflow, search/pagination/sorting, notification/outbox workflow, daily automation, messy JSON import handling, and the remaining API endpoints.

These are intentionally documented as remaining work rather than being represented as completed functionality.

---

## 13. Design Priorities

The implementation prioritizes:

- Correct business rules
- Backend-enforced inventory allocation
- Transaction-safe stock updates
- Persistent database storage
- Deterministic date handling
- Clear separation between HTTP handling and business logic
- Simple architecture suitable for the assessment
- Testability and debuggability