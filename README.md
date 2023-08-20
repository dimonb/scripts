# Misc bash AI generated scripts

## monit_temperature.sh
Monitors temperature and fan speed
should be executed from `/etc/monit/monitrc`
```sql
check program sensors with path "/usr/local/sbin/monit_temperature.sh"
    if status != 0 then alert
```
## watchdog_helper.sh
Run from watchdog. if some ip is not pinged, reboot server in 15 minutes. Not rebooted if uptime less then hour
should be configured in `/etc/watchdog.conf`
```sql
test-binary             = /usr/local/sbin/watchdog_helper.sh
```

