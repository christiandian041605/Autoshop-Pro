# AutoShop Pro

AutoShop Pro is a premium, web-based management system designed for automotive repair shops and service centers.

## Project Deliverables

This repository has been initialized with the core design documentation and database schema:

1.  **[blueprint.md](file:///Applications/XAMPP/xamppfiles/htdocs/Autoshop-Pro/blueprint.md)** - Explains the architecture, folder structure, business workflows, user permissions, and implementation timeline.
2.  **[database.sql](file:///Applications/XAMPP/xamppfiles/htdocs/Autoshop-Pro/database.sql)** - Ready-to-import MySQL database schema complete with tables, indices, generated columns, constraints, and default seed data.
3.  **[.gitignore](file:///Applications/XAMPP/xamppfiles/htdocs/Autoshop-Pro/.gitignore)** - Excludes system configurations, log/cache outputs, vendor dependencies, and local uploads from version control.

## Setup Instructions

### 1. Database Setup
Ensure you have MySQL/MariaDB server running (such as via XAMPP).
Import the schema:
```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS autoshop_pro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p autoshop_pro < database.sql
```
*Alternatively, you can import `database.sql` directly using phpMyAdmin.*

### 2. Accessing the Default Administrator Account
*   **Username:** `admin`
*   **Password:** `AdminPassword123` *(Note: The database seeds this account with a secure bcrypt-hashed password)*

## Project Timeline
*   **Phase 1 (Weeks 1-4):** Core Operations (Customer & Vehicle registry, Job Order tracking, Invoicing & Receipts, basic reporting).
*   **Phase 2 (Weeks 5-8):** Extended Operations (Scheduler/Calendars, Inventory & Suppliers, SMS/Email Alerts, Management analytics dashboard).
