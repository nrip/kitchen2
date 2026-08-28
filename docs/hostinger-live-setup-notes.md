# Hostinger Live Setup Notes

Hostinger's official support workflow reviewed on 2026-08-27 recommends opening the created database in phpMyAdmin from hPanel, confirming the target database, selecting **Import**, choosing a `.sql` or `.sql.zip` file, and clicking **Go** without changing other import settings. It recommends importing into an empty database and notes that larger databases may require SSH.

The user's confirmed FTP target is the Hostinger `public_html` directory. FTP control-port access from the sandbox is reachable, but FTP data-channel operations time out from the sandbox, so the user uploaded the application package manually. No FTP file upload was completed by the agent.

The live application must be configured with the actual Hostinger database hostname as shown in hPanel. Do not assume `localhost` if hPanel provides a different database host. Database credentials and integration secrets must remain outside the public web root and must not be recorded in this file.

The current deployment work is pending user-side schema import and a secure server-side `config/local.php` configuration or hosting environment variables.
