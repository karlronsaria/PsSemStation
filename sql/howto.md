# howto: create new or reset user and schema

```powershell
$user = 'myroot'
$loginPath = 'sem-mydb'
cat .\new-user.mysql.sql | mysql -u root
mysql_config_editor.exe set --login-path=$loginPath --host=localhost --user=$user --password
cat .\new-db-mydb.mysql.sql | mysql -u $user -p
cat .\new-semantic-system-db.mysql.sql | mysql -u $user -p
cat .\function.mysql.sql | mysql -u $user -p
cat .\trigger.mysql.sql | mysql -u $user -p
```

See tables

```sql
select table_name from information_schema.tables where table_schema = 'mydb';
```

---

[← Go Back](<../readme.md>)

