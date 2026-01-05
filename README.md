# REDCap Warn Users of Pending Suspension (WUPS)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3561122.svg)](https://doi.org/10.5281/zenodo.3561122)

A REDCap external module that will warn users of pending suspensions and provide an easy opportunity to extend the life of REDCap accounts.

## Installation
- Obtain this module from the Consortium [REDCap Repo](https://redcap.vumc.org/consortium/modules/index.php) from the REDCap Control Center.

## REDCap Requirements

Warn Users of Pending Suspension (WUPS) is dependent upon REDCap's normal _Auto-suspend users after period of inactivity_ feature being enabled. WUPS does not suspend accounts it only _warns_ of pending suspending via emails.

## Breaking Change in Version 3.0.0

If your system uses a single signon configuration that bypasses the REDCap Login page, you might need to turn on `Update user_lastlogin on main REDCap pages` in the WUPS system configuration after you upgrade to Version 3.x. See the [Updating user_lastlogin](#updating-user_lastlogin) section below.

## Configuration

The module is configurable at the system level to allow the sending account, subject line, and body of the message to be customized. The message body supports parameter substitution like REDCap's data piping to allow messages to be customized with fields like `[username]`, `[user_firstname]`, `[user_lastname]`, `[login_link]`, `[days_until_suspension]` and `[suspension_date]`. The `[login_link]` is the REDCap login page.

If you do not check **Use Custom Email Sender**, the module will use the email set at "Email Address of REDCap Administrator" under Control Center > General Configuration.

If the email address is blank in either case, emails will not be sent and the cron job will return an error message.

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

## Updating user_lastlogin

As of version 3.0.0, WUPS no longer sets the `user_lastlogin` column in the `redcap_user_information` table by default. Sites using single signon systems that bypass the REDCap Login page, might need to set `Update user_lastlogin on main REDCap pages` in the WUPS system configuration. This option will update the `user_lastlogin` column in the `redcap_user_information` table any time a user accesses the _Home_ page or the _My Projects_ page. To determine if your system needs this feature, upgrade to WUPS 3.x, logout of REDCap, login, then run this SQL query:

```sql
select username, user_lastlogin
from redcap_user_information 
order by user_lastlogin desc;
```

Your username should be near the top of the list, `user_lastlogin` should reflect to precise time of your login. If `user_lastlogin` is not updating, access the system configuration of the WUPS module and check `Update user_lastlogin on main REDCap pages`. 

## How to Implement WUPS

Implementing WUPS and/or activating REDCap account suspensions can require some careful planning to avoid annoying your users who have not logged in recently.  If you have never used account suspension on your REDCap host, activating it will cause all accounts that have not logged in within the _Period of inactivity_ to be suspended within 24 hours. If those people want their accounts reenabled they will have to ask the REDCap admin to reenable them.  That generates the kind of help desk workload WUPS was designed to _prevent_.

To avoid the chaos of hundreds of accounts getting prematurely suspended, you can run a few SQL queries to adjust the last login dates for your REDCap users.  Done correctly, you can use WUPS to warn these users of the pending suspension, allow interested REDCap users to renew their account, and let the rest suspend normally.

The first step is to configure WUPS' _Days Before Suspension_.  In this example, we'll use `30, 15, 7, 3, 1`, but only the highest number affects our work. We've also set _Period of inactivity_ to 180 days. We want everyone who is approaching their date of suspension to receive every warning WUPS is configured to provide. To achieve that, _no one_ is allowed to be within 30 days of suspension when WUPS is turned on. This requires some accounts have their date of last login changed.

To change the last login date, we first need to identify who needs the change.  This query will return all the usernames of accounts that will expire within the next 30 days when _Period of inactivity_ is set to 180 days:

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

With that temporary table created, it is a simple matter to change `user_lastlogin` to a random date between 120 and 150 days.

    update redcap_user_information
    set user_lastlogin = date_add(now(), INTERVAL FLOOR(-RAND() * 30  - 120) DAY)
    where username in ( select username from old_users);

This will make the WUPS warnings start in 0-30 days. If the warnings are unheeded, account suspensions will happen in 30-60 days.

## Contributing

Software developers who want to contribute to WUPS should read [Developer testing techniques](./developer_testing.md)
