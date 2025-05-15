MySQL/MariaDB Auto-Tuning Script for Linux Servers
Automatically optimize MySQL or MariaDB configuration (my.cnf) based on available system resources (CPU cores and RAM).
This Bash script calculates and applies the best-fit settings for InnoDB, buffers, caches, timeouts, and connection limits, aiming for maximum performance and reliability — without manual tuning.

Features:

Auto-detects total RAM and CPU cores

Allocates memory dynamically (e.g., InnoDB buffer, query cache, temp tables)

Updates or creates my.cnf with safe, calculated defaults

Suitable for fresh installs or existing deployments

No dependencies – pure Bash script
