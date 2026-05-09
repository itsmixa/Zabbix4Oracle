# Zabbix template for Oracle Database and Golden Gate


These templates were created because standard Zabbix templates cannot correctly calculate space, contain many useless performance metrics, and do not allow monitoring many important database and instance metrics.

The Oracle Database template monitors:
1. Space in tablespaces.
2. Backups.
3. alert.log
4. Archive destinations state and errors.
5. Number of active sessions.
6. Locks.
7. Data Guard state and lag.

The Oracle Golden Gate template monitors:
1. Processes state.
2. Lag.
3. TSC.

