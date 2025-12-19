# Developer testing techniques

To test WUPS, you need to turn on a few REDCap features it interacts with.  You need to turn on "Auto-suspend users after period of inactivity" in Control Center, User Settings.  For our tests we also set "Period of inactivity" to 30 days. A lazy developer might just want to run this SQL to make that happen:

    update redcap_config set value="all" where field_name = "suspend_users_inactive_type";
    update redcap_config set value="1" where field_name = "suspend_users_inactive_send_email";
    update redcap_config set value="30" where field_name = "suspend_users_inactive_days";

This module has to be configured before you can do anything with it. The instructions that follow assume the module has been configured as described in _Email Configuration Example_ above. The _Days Before Suspension_ setting of `10, 12, 20` is especially important. As this tool sends emails, also make sure the field that will be used for the **Sender Email** address is configured correctly in your module configuration.

You'll need some test users. Assuming you have a set of test users `alice`, `bob`, `carol`, and `dan` you can configure them to receive alerts _today_ by adjusting their `user_lastlogin` date as follows:

    update redcap_user_information set user_lastlogin = date_add(now(), interval -10 day) where username='alice';
    update redcap_user_information set user_lastlogin = date_add(now(), interval -18 day) where username='bob';
    update redcap_user_information set user_lastlogin = date_add(now(), interval -10 day) where username='carol';
    update redcap_user_information set user_lastlogin = date_add(now(), interval -20 day) where username='dan';

If you are testing REDCap under [redcap-docker-compose](https://github.com/123andy/redcap-docker-compose), the automatic table-based user creation tools can make these users for you. If you are testing under a [redcap_deployment](https://github.com/ctsit/redcap_deployment) Vagrant VM, the above set of test users can be created via the SQL file at [https://github.com/ctsit/redcap_deployment/blob/master/deploy/files/test\_with\_table\_based\_authentication.sql](https://github.com/ctsit/redcap_deployment/blob/master/deploy/files/test_with_table_based_authentication.sql). People testing in other environments will need to design their own set of test cases.

To get the alerts from these test users, you'll want to update their email addresses with _your_ email address. e.g.,

    update redcap_user_information set user_email = 'you@example.org' where username in ("alice", "bob", "carol", "dan");

The final step to facilitate testing is to adjust the frequency of the cron job. The external module framework monitors the cron configuration settings in a module's `config.json`. If you change the cron frequency in that file to 60 seconds, the EM framework will, shortly thereafter, do the same to the module's cron job:

    "cron_frequency": "60",

Turn that value back down to `86400` (that's the number of seconds in one day) when you are done to get back to the normal configuration.

All of these SQL commands and more are rolled up in [developer_testing_commands.sql](developer_testing_commands.sql). Open this file in your favorite SQL tool and run the commands one section at a time to see the relevant database state.
