#!/bin/bash

echo "MySQL Optimization Tool - v1.0"
echo "=================================================="
echo "This script automatically optimizes MySQL/MariaDB"
echo "settings based on the server hardware."
echo ""
echo "If you want to change the parameters, edit the"
echo "EDITABLE PARAMETERS section at the top of the script."
echo "=================================================="

# MySQL/MariaDB Optimization Script
# This script automatically optimizes MySQL/MariaDB configuration
# based on server hardware

# Stop the script on error
set -e

##############################################################
### EDITABLE PARAMETERS - MODIFY AS NEEDED ###
##############################################################

# Path to the configuration file
CONFIG_FILE="/etc/mysql/my.cnf"

# Memory usage ratio for MySQL/MariaDB (percentage of total memory)
MYSQL_MEMORY_PERCENT=75

# Connection settings
max_connections=100              # Maximum number of connections
mem_per_connection=8            # Average memory per connection (MB)

# InnoDB settings
INNODB_BUFFER_POOL_PERCENT=75    # Percentage of MySQL memory for InnoDB buffer (after subtracting connections)
INNODB_LOG_FILE_SIZE_MB=256      # InnoDB log file size (MB)
INNODB_LOG_BUFFER_SIZE_MB=16     # InnoDB log buffer size (MB)

# Cache settings (percentage of remaining memory)
JOIN_BUFFER_PERCENT=10           # Percentage for Join buffer
READ_BUFFER_PERCENT=5            # Percentage for Read buffer
READ_RND_BUFFER_PERCENT=5        # Percentage for Random read buffer
SORT_BUFFER_PERCENT=5            # Percentage for Sort buffer
TMP_TABLE_PERCENT=15             # Percentage for Temporary tables
MAX_HEAP_TABLE_PERCENT=15        # Percentage for MEMORY tables

# Timeout values (seconds)
CONNECT_TIMEOUT=90
INTERACTIVE_TIMEOUT=90
WAIT_TIMEOUT=90

# Table cache settings
TABLE_OPEN_CACHE=2000            # Open table cache
TABLE_DEFINITION_CACHE_PERCENT=5 # Percentage of total MySQL memory
TABLE_CACHE_PERCENT=10           # Percentage of total MySQL memory

#############################################
### DO NOT EDIT BELOW THIS POINT ###
#############################################

# Convert values from bytes to MB or GB
format_size() {
    local size_mb=$1
    if [ "$size_mb" -ge 1024 ]; then
        echo "$((size_mb / 1024))G"
    else
        echo "${size_mb}M"
    fi
}

# Detect server resources
total_cores=$(nproc)
core_count=$((total_cores / 2))
total_memory=$(free -m | awk '/^Mem:/{print $2}')
total_memory_gb=$((total_memory / 1024))

# Memory limits (75% of total memory allocated for MySQL)
mysql_memory=$((total_memory * 75 / 100))

connections_memory=$((max_connections * mem_per_connection))

if [ "$connections_memory" -ge "$mysql_memory" ]; then
  echo "Warning: MAX_CONNECTIONS and MEMORY_PER_CONNECTION total exceed available MySQL RAM ($mysql_memory MB)!"
  echo "Please reduce MAX_CONNECTIONS or MEMORY_PER_CONNECTION."
  exit 1
fi

# Allocate remaining memory to InnoDB and other caches
remaining_memory=$((mysql_memory - connections_memory))
innodb_buffer_pool_size=$((remaining_memory * 75 / 100))  # 75% of remaining memory
innodb_buffer_pool_instances=$(( innodb_buffer_pool_size > 8192 ? 8 : (innodb_buffer_pool_size / 1024) ))
innodb_log_file_size_fmt=$(format_size "$INNODB_LOG_FILE_SIZE_MB")
innodb_log_buffer_size_fmt=$(format_size "$INNODB_LOG_BUFFER_SIZE_MB")

# If innodb_buffer_pool_instances is less than 1, set it to 1
if [ "$innodb_buffer_pool_instances" -lt 1 ]; then
    innodb_buffer_pool_instances=1
fi

remaining_other_buffers=$((remaining_memory - innodb_buffer_pool_size))

thread_cache_size=$((max_connections * 10 / 100)) # 10% of max connections
query_cache_size=$((mysql_memory * 10 / 100)) # 10% of MySQL memory

join_buffer_size=$((remaining_other_buffers * 10 / 100)) # 10%
read_buffer_size=$((remaining_other_buffers * 5 / 100)) # 5%
read_rnd_buffer_size=$((remaining_other_buffers * 5 / 100)) # 5%

sort_buffer_size=$((remaining_other_buffers * 5 / 100)) # 5%
tmp_table_size=$((remaining_other_buffers * 15 / 100)) # 15%
max_heap_table_size=$((remaining_other_buffers * 15 / 100)) # 15%

table_cache=$((mysql_memory / 10)) # 10%
table_definition_cache=$((mysql_memory / 20)) # 5%
table_open_cache=2000

# Timeout values
connect_timeout=90
interactive_timeout=90
wait_timeout=90

# Convert values to human-readable format
innodb_buffer_pool_size_fmt=$(format_size "$innodb_buffer_pool_size")
query_cache_size_fmt=$(format_size "$query_cache_size")
join_buffer_size_fmt=$(format_size "$join_buffer_size")
read_buffer_size_fmt=$(format_size "$read_buffer_size")
read_rnd_buffer_size_fmt=$(format_size "$read_rnd_buffer_size")
sort_buffer_size_fmt=$(format_size "$sort_buffer_size")
tmp_table_size_fmt=$(format_size "$tmp_table_size")
max_heap_table_size_fmt=$(format_size "$max_heap_table_size")

# Display calculated values
echo "Calculated optimization values for MySQL/MariaDB:"
echo "------------------------------------------------"
echo "Total RAM: $total_memory MB ($total_memory_gb GB)"
echo "Memory allocated for MySQL: $mysql_memory MB"
echo "CPU cores: $total_cores (Active cores: $core_count)"
echo "------------------------------------------------"
echo "max_connections: $max_connections"
echo "Memory per connection: $mem_per_connection MB"
echo "Total memory for all connections: $connections_memory MB"
echo "Memory left for InnoDB and caches: $remaining_memory MB"
echo "innodb_buffer_pool_size: $innodb_buffer_pool_size_fmt"
echo "innodb_buffer_pool_instances: $innodb_buffer_pool_instances"
echo "thread_cache_size: $thread_cache_size"
echo "thread_concurrency: $thread_concurrency"
echo "Memory left for other caches: $remaining_other_buffers"
echo "query_cache_size: $query_cache_size_fmt"
echo "join_buffer_size: $join_buffer_size_fmt"
echo "read_buffer_size: $read_buffer_size_fmt"
echo "read_rnd_buffer_size: $read_rnd_buffer_size_fmt"
echo "sort_buffer_size: $sort_buffer_size_fmt"
echo "tmp_table_size: $tmp_table_size_fmt"
echo "max_heap_table_size: $max_heap_table_size_fmt"
echo "table_cache: $table_cache"
echo "table_definition_cache: $table_definition_cache"
echo "table_open_cache: $table_open_cache"
echo "connect_timeout: $connect_timeout"
echo "interactive_timeout: $interactive_timeout"
echo "wait_timeout: $wait_timeout"
echo "------------------------------------------------"

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "WARNING: $CONFIG_FILE not found!"
    echo "Creating a new configuration file..."
    
    # Split the file path
    CONFIG_DIR=$(dirname "$CONFIG_FILE")
    
    # Create directory if it does not exist
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "Directory $CONFIG_DIR not found, creating..."
        mkdir -p "$CONFIG_DIR"
    fi
    
    # Create a basic configuration file
    echo "[mysqld]" > "$CONFIG_FILE"
    echo "# MySQL/MariaDB configuration" >> "$CONFIG_FILE"
    echo "# Created on: $(date)" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    
    # Check file creation permissions
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERROR: Could not create configuration file! Check your write permissions."
        echo "Try running the script with sudo: sudo $0"
        exit 1
    fi
    
    echo "New configuration file created: $CONFIG_FILE"
else
    # Backup the existing configuration file
    backup_file="${CONFIG_FILE}.$(date +%Y%m%d_%H%M%S).bak"
    echo "Backing up existing configuration file: $backup_file"
    cp "$CONFIG_FILE" "$backup_file"
fi

# Function to update configuration parameters
update_config() {
    local param=$1
    local value=$2
    
    if grep -q "^$param\s*=" "$CONFIG_FILE"; then
        # If parameter exists, update it
        sed -i "s/^$param\s*=.*$/$param = $value/" "$CONFIG_FILE"
    else
        # If parameter does not exist, add it under [mysqld]
        if grep -q "\[mysqld\]" "$CONFIG_FILE"; then
            # Add parameter after [mysqld] section
            sed -i "/\[mysqld\]/a $param = $value" "$CONFIG_FILE"
        else
            # If no [mysqld] section, create it and add parameter
            echo -e "\n[mysqld]\n$param = $value" >> "$CONFIG_FILE"
        fi
    fi
}

echo "Updating MySQL/MariaDB configuration..."

# Update all parameters
update_config "table_open_cache" "$TABLE_OPEN_CACHE"
update_config "table_definition_cache" "$table_definition_cache"
update_config "table_cache" "$table_cache"
update_config "max_heap_table_size" "$max_heap_table_size_fmt"
update_config "tmp_table_size" "$tmp_table_size_fmt"
update_config "sort_buffer_size" "$sort_buffer_size_fmt"
update_config "read_rnd_buffer_size" "$read_rnd_buffer_size_fmt"
update_config "read_buffer_size" "$read_buffer_size_fmt"
update_config "join_buffer_size" "$join_buffer_size_fmt"
update_config "thread_cache_size" "$thread_cache_size"
update_config "innodb_log_buffer_size" "$innodb_log_buffer_size_fmt"
update_config "innodb_log_file_size" "$innodb_log_file_size_fmt"
update_config "innodb_buffer_pool_instances" "$innodb_buffer_pool_instances"
update_config "innodb_buffer_pool_size" "$innodb_buffer_pool_size_fmt"
update_config "max_connections" "$max_connections"
update_config "wait_timeout" "$WAIT_TIMEOUT"
update_config "interactive_timeout" "$INTERACTIVE_TIMEOUT"
update_config "connect_timeout" "$CONNECT_TIMEOUT"
update_config "long_query_time" "5"
update_config "slow-query-log-file" "/var/log/mysql/mysql-slow.log"
update_config "slow-query-log" "0"
update_config "back_log" "100"
update_config "max_binlog_size" "100M"
update_config "expire_logs_days" "10"
update_config "skip-external-locking" "1"
update_config "skip-name-resolve" "1"
update_config "log-queries-not-using-indexes" "1"
update_config "innodb_file_per_table" "ON"
update_config "innodb_stats_on_metadata" "OFF"
update_config "performance_schema" "ON"
update_config "collation-server" "utf8mb4_general_ci"
update_config "character-set-server" "utf8mb4"

echo "Configuration successfully updated."
echo "You need to restart the MySQL/MariaDB service:"
echo "sudo systemctl restart mysql"
# or
echo "sudo systemctl restart mariadb"

exit 0
