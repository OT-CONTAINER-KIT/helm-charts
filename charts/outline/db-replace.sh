#!/bin/bash
set -euo pipefail

# Run this directly on the Postgres server (192.168.8.39) as root or with sudo access.
# Make sure Outline is scaled to 0 replicas BEFORE you run this.

# if connection is persist
# Immediate fix (run on the PG server)                                                                                                                                                     
                                                                                                                                                                                              
# ```bash                                                                                                                                                                                      
#   sudo -u postgres psql -d postgres                                                                                                                                                          
# ```                                                                                                                                                                                          
                                                                                                                                                                                              
# ```sql                                                                                                                                                                                       
#   -- See who is connected                                                                                                                                                                    
#   SELECT pid, usename, application_name, state                                                                                                                                               
#   FROM pg_stat_activity                                                                                                                                                                      
#   WHERE datname = 'outline';                                                                                                                                                                 
                                                                                                                                                                                              
#   -- Kill them all                                                                                                                                                                           
#   SELECT pg_terminate_backend(pid)                                                                                                                                                           
#   FROM pg_stat_activity                                                                                                                                                                      
#   WHERE datname = 'outline' AND pid <> pg_backend_pid(); 

# cd to /tmp so sudo -u postgres never tries to chdir to /root or /home/vishal
cd /tmp

DB_NAME="outline"
DUMP_FILE="/tmp/outline_migration.sql"
DATE=$(date +%Y%m%d-%H%M%S)

if [ ! -f "$DUMP_FILE" ]; then
  echo "ERROR: Dump file not found at $DUMP_FILE"
  echo "Expected a PLAIN SQL dump (create it with: docker exec ... pg_dump -Fp ...)"
  exit 1
fi

echo "=== 1. Backup current database ==="
sudo -u postgres pg_dump -Fc "$DB_NAME" > "/tmp/outline-current-backup-${DATE}.dump"
echo "Backup saved to: /tmp/outline-current-backup-${DATE}.dump"

echo "=== 2. Drop old staging if it exists + create fresh ==="
sudo -u postgres psql -c "DROP DATABASE IF EXISTS outline_staging;"
sudo -u postgres psql -c "CREATE DATABASE outline_staging OWNER \"outline-db-user\";"

echo "=== 3. Restore dump into staging via psql ==="
# Plain SQL restore — works on ANY PostgreSQL version, no pg_restore needed
sudo -u postgres psql -d outline_staging -f "$DUMP_FILE"

echo "=== 4. Apply grants ==="
sudo -u postgres psql -d outline_staging -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"outline-db-user\";"
sudo -u postgres psql -d outline_staging -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"outline-db-user\";"
sudo -u postgres psql -d outline_staging -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO \"outline-db-user\";"
sudo -u postgres psql -d outline_staging -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO \"outline-db-user\";"

echo "=== 5. Swap databases ==="
# Do terminate + rename in ONE session so nothing reconnects between them
sudo -u postgres psql -d postgres <<EOF
  SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE datname IN ('$DB_NAME', 'outline_staging')
    AND pid <> pg_backend_pid();

  ALTER DATABASE $DB_NAME RENAME TO outline_old;
  ALTER DATABASE outline_staging RENAME TO $DB_NAME;
EOF

echo "=== 6. Verify the new database ==="
sudo -u postgres psql -d "$DB_NAME" -c "\dt"
sudo -u postgres psql -d "$DB_NAME" -c "SELECT COUNT(*) AS documents FROM documents;"
sudo -u postgres psql -d "$DB_NAME" -c "SELECT COUNT(*) AS users FROM users;"
sudo -u postgres psql -d "$DB_NAME" -c "SELECT COUNT(*) AS teams FROM teams;"

echo "=== 7. Drop old database ==="
sudo -u postgres psql -d postgres -c "DROP DATABASE IF EXISTS outline_old;"

echo "=== Done ==="
echo ""
echo "Current databases:"
sudo -u postgres psql -c "\l outline*"
echo ""
echo "Scale Outline back to 2 replicas when ready."
