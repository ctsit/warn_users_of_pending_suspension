# REDCap Warn Users of Pending Suspension (WUPS)

A REDCap external module that will warn users of pending suspensions and provide an easy opportunity to extend the life of REDCap accounts.

## Prerequisites
- REDCap >= 8.0.3

## Easy Installation
- Obtain this module from the Consortium [REDCap Repo](https://redcap.vanderbilt.edu/consortium/modules/index.php) from the control center.

## Manual Installation
- Clone this repo into to `<redcap-root>/modules/warn_users_of_pending_suspension_v<version_number>`.
- Go to **Control Center > External Modules** and enable Warn Users of Pending Suspension.

## REDCap Requirements

WUPS is dependent upon REDCap's normal _Auto-suspend users after period of inactivity_ feature being enabled. WUPS does not suspend accounts it only _warns_ of pending suspending via emails.

## Configuration

The module is configurable at the system level to allow the sending account, subject line, and body of the message to be customized. The message body supports parameter substitution like REDCap's data piping to allow messages to be customized with fields like `[username]`, `[user_firstname]`, `[user_lastname]`, `[login_link]`, `[days_until_suspension]` and `[suspension_date]`. The `[login_link]` is the REDCap login page.

If upgrading from version 2.0.2 or lower, you may wish to set **Sender Email** to match the value set for "Email Address of REDCap Administrator" under Control Center > General Configuration.

### Email Configuration Example

- Email Subject:

        Warning of Account Suspension

- Email Body:

        Dear [user_firstname] [user_lastname], <br><br>

        Your account will be suspended in [days_until_suspension] days on [suspension_date].
        If you want to avoid account suspension, please log in to
        <a href="[login_link]">your REDCap account</a>. <br><br>

        Regards,<br>
        REDCap Support Team.

- Days Before Suspension:

        10, 12, 20



## How to Implement WUPS and Account Suspensions

Implementing WUPS and/or activating REDCap account suspensions can require some careful planning to avoid annoying your users who have not logged in recently.  If you have never used account suspension on your REDCap host, activating it will cause all accounts that have not logged in within the _Period of inactivity_ to be suspended within 24 hours. If those people want their accounts reenabled they will have to ask the REDCap admin to reenable them.  That generates the kind of help desk workload WUPS was designed to _prevent_.

To avoid the chaos of hundreds of accounts getting prematurely suspended, you can run a few SQL queries to adjust the last login dates and last activity dates for your REDCap users.  Done correctly, you can use WUPS to warn these users of the pending suspension, allow interested REDCap users to renew their account, and let the rest suspend normally.

The first step is to configure WUPS' _Days Before Suspension_.  In this example, we'll use `30, 15, 7, 3, 1`, but only the highest number affects our work. We've also set _Period of inactivity_ to 180 days. We want everyone who is approaching their date of suspension to receive every warning WUPS is configured to provide. To achieve that, _no one_ is allowed to be within 30 days of suspension when WUPS is turned on. This requires some accounts have their date of last login and last activity changed.

To change the last login and last activity dates, we first need to identify who needs the change.  This query will return all the usernames of accounts that will expire within the next 30 days when _Period of inactivity_ is set to 180 days:

    create temporary table old_users as (
    select * from (
         select username,
         (case
              when user_lastactivity is not null and user_lastlogin is not null then greatest(user_lastlogin, user_lastactivity)
              when user_lastactivity is not null then user_lastactivity
              when user_lastlogin is not null then user_lastlogin
              when user_creation is not null then user_creation
              end) as user_last_date
         from redcap_user_information
         where user_suspended_time is null
         ) as my_user_info
    where DATEDIFF(NOW(), user_last_date) > (180 - 30)
    );

With that temporary table created, it is a simple matter to change `user_lastactivity` and `user_lastlogin` to a random date between 120 and 150 days.

    update redcap_user_information
    set user_lastactivity = date_add(now(), INTERVAL FLOOR(-RAND() * 30  - 120) DAY),
        user_lastlogin = date_add(now(), INTERVAL FLOOR(-RAND() * 30  - 120) DAY)
    where username in ( select username from old_users);

This will make the WUPS warnings start in 0-30 days. If the warnings are unheeded, account suspensions will happen in 30-60 days.


## Developer testing techniques

To test WUPS, you need to turn on a few REDCap features it interacts with.  You need to turn on "Auto-suspend users after period of inactivity" in Control Center, User Settings.  For our tests we also set "Period of inactivity" to 30 days.  A lazy developer might just want to run this SQL to make that happen:

    update redcap_config set value="all" where field_name = "suspend_users_inactive_type";
    update redcap_config set value="1" where field_name = "suspend_users_inactive_send_email";
    update redcap_config set value="30" where field_name = "suspend_users_inactive_days";

As this tool sends email, make sure the **Sender Email** address is configured correctly in your module configuration.

You'll also need some test users.  To revise the set of test users `alice`, `bob`, `dan`, and `carol` to receive messages based on the above configuration, change their `user_lastlogin` and `user_lastactivity` dates as follows:

    update redcap_user_information set user_lastlogin = date_add(now(), interval -22 day), user_lastactivity = date_add(now(), interval -10 day) where username='alice';
    update redcap_user_information set user_lastlogin = date_add(now(), interval -18 day), user_lastactivity = NULL where username='bob';
    update redcap_user_information set user_lastlogin = date_add(now(), interval -10 day), user_lastactivity = date_add(now(), interval -25 day) where username='carol';
    update redcap_user_information set user_lastlogin = null, user_lastactivity = date_add(now(), interval -20 day) where username='dan';

    update redcap_user_information set user_email = 'you@example.org' where username in ("alice", "bob", "carol", "dan");

When tested, each of the aforementioned users should get a message. FYI, the above set of test users can be created via the SQL file at [https://github.com/ctsit/redcap_deployment/blob/master/deploy/files/test\_with\_table\_based\_authentication.sql](https://github.com/ctsit/redcap_deployment/blob/master/deploy/files/test_with_table_based_authentication.sql). That SQL file works great for users of the redcap_deployment project. Other users might want to be cautious as the SQL makes some assumptions.

The final step to facilitate testing is to turn the frequency of the cron job up.  You'll need to change `cron_frequency` and `cron_max_run_time` so that the cron job runs more often. Here's the lazy developer's SQL method to do that:

    update redcap_crons set cron_frequency = 60, cron_max_run_time = 10 where cron_name = "warn_users_account_suspension_cron";

Revert the setting to the defaults with this SQL when you are done with testing:

    update redcap_crons set cron_frequency = 86400, cron_max_run_time = 1200 where cron_name = "warn_users_account_suspension_cron";
