Backup - 

Restore -

Extension Installation- To use an extension, install it. Run the CREATE EXTENSION command on the PostgreSQL node where you want the extension to be available e.g. CREATE EXTENSION hstore SCHEMA demo; https://docs.percona.com/postgresql/13/extensions.html

PGbouncer- We are exposing the cluster through PgBouncer, which is enabled by default. It acts as DB proxy. It can be disabled by setting proxy.pgBouncer.replicas to 0. https://docs.percona.com/percona-operator-for-postgresql/2.0/expose.html

Patroni Template - It is a template for configuring a highly available PostgreSQL cluster. https://docs.percona.com/postgresql/16/solutions/high-availability.html

LLVM (for JIT Compilation)- Percona Operator is based on CrunchyData’s PostgreSQL Operator which includes LLVM (for JIT compilation). JIT compilation is the process of turning some form of interpreted program evaluation into a native program, and doing so at run time. For example, instead of using general-purpose code that can evaluate arbitrary SQL expressions to evaluate a particular SQL predicate like WHERE a.col = 3, it is possible to generate a function that is specific to that expression and can be natively executed by the CPU, yielding a speedup. https://www.postgresql.org/docs/current/jit-reason.html

DR - To achieve a production grade PostgreSQL disaster recovery solution, we need something that can take full or incremental database backups from a running instance, and restore from those backups at any point in time. Percona Distribution for PostgreSQL is supplied with pgBackRest: a reliable, open-source backup and recovery solution for PostgreSQL. 

pgBackRest supports remote repository hosting and can even use cloud-based services like AWS S3, Google Cloud Services Cloud Storage, Azure Blob Storage for saving backup files.
https://docs.percona.com/postgresql/14/solutions/backup-recovery.html

Switch Over- In Percona Operator, the primary instance election can be controlled by the patroni.switchover section of the Custom Resource manifest. It allows to enable switchover targeting a specific PostgreSQL instance as the new primary, or just running a failover if PostgreSQL cluster has entered a bad state. https://docs.percona.com/percona-operator-for-postgresql/2.0/change-primary.html

User and DB creation- We can create the users and DB by providing values in the 'users' section in values.yaml. https://docs.percona.com/percona-operator-for-postgresql/2.0/users.html

Monitoring- 