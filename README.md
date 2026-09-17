# pharmacy-inventory
Full-stack pharmacy inventory system with FEFO dispensing and expiry tracking
# Pharmacy Inventory Management System

A full-stack pharmacy inventory application that manages medicines and batches using First Expiry, First Out (FEFO) dispensing.

The system is designed around the core pharmacy requirement:

> Always dispense the eligible batch with the earliest expiry date first, and never dispense an expired batch.

## Tech Stack

### Frontend

- React
- Vite
- Tailwind CSS

### Backend

- Node.js
- Express.js
- REST APIs

### Database

- SQLite
- better-sqlite3

### Authentication

- JWT
- HttpOnly cookies
- bcryptjs

### Development Environment

- GitHub Codespaces
- GitHub

---

# Features

## Core Inventory

- Medicine management
- Batch management
- Batch expiry tracking
- Sellable stock calculation
- FEFO dispensing
- Transaction-safe dispensing
- Expired batch protection

## Authentication

- User registration
- User login
- Authentication using HttpOnly cookies
- Protected inventory APIs
- Logout
- Current-user endpoint

## Search and Inventory Management

- Medicine search
- Pagination
- Sorting
- Batch listing
- Sellable stock visibility

## Expiry Management

- Expiring-soon identification
- Expired batch identification
- 30-day expiry alerts
- Separate handling of expired batches

## Automation

- Daily inventory clock endpoint
- 7-day expiry processing
- Automatic quarantine of expired batches
- Automation result counts

## Messy Data Import

The system supports JSON batch imports containing:

- Null values
- Quantities such as `"10 units"`
- ISO dates
- `dd/mm/yyyy` dates
- Duplicate rows
- Invalid records

The import produces:

```text
imported
deduped
rejected