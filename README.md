# AutoTune MySQL/MariaDB Config Generator

This Bash script automatically generates optimized MySQL/MariaDB configuration parameters based on the system's available memory and architecture. It is ideal for sysadmins, DevOps engineers, and anyone looking to deploy database servers efficiently without manually tuning performance settings.

## Features

- Detects total system memory and architecture (32-bit / 64-bit)
- Calculates and sets critical MySQL/MariaDB parameters:
  - `innodb_buffer_pool_size`
  - `query_cache_size`
  - `max_connections`
  - `table_open_cache`
  - `key_buffer_size`
  - And more
- Outputs configuration as a ready-to-use `my.cnf` snippet
- Lightweight and dependency-free (pure Bash)

## Why Use This?

Manual tuning of MySQL/MariaDB can be time-consuming and error-prone, especially across environments with different specs. This script simplifies the process by generating optimized configurations tailored to the specific server’s RAM, ensuring improved performance and stability.

## Usage
bash optimizer-mycnf.sh


## Compatibility
Linux distributions (Debian, Ubuntu, CentOS, etc.)

MySQL and MariaDB (any major versions)
Works on virtual machines, bare-metal servers, and containers

## Requirements
Bash shell
free, awk, and grep commands (default in most distros)

## Customization
You can easily extend the script by modifying the parameter logic or adding new tunables. It's written in modular Bash for easy maintenance.

## Contributing
Contributions are welcome! If you have improvements, fixes, or additional parameter suggestions, feel free to submit a pull request or open an issue.

## Contact
For questions or feedback, please open an issue in this repository.
