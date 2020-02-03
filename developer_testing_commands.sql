-- Execute these SQL commands to (re)configure and test WUPS

-- configure
update redcap_config set value="all" where field_name = "suspend_users_inactive_type";
update redcap_config set value="1" where field_name = "suspend_users_inactive_send_email";
update redcap_config set value="30" where field_name = "suspend_users_inactive_days";

update redcap_user_information set user_lastlogin = date_add(now(), interval -22 day), user_lastactivity = date_add(now(), interval -10 day) where username='alice';
update redcap_user_information set user_lastlogin = date_add(now(), interval -18 day), user_lastactivity = NULL where username='bob';
update redcap_user_information set user_lastlogin = date_add(now(), interval -10 day), user_lastactivity = date_add(now(), interval -25 day) where username='carol';
update redcap_user_information set user_lastlogin = null, user_lastactivity = date_add(now(), interval -20 day) where username='dan';

update redcap_user_information set user_email = 'pbc@ufl.edu' where username in ("admin","alice", "bob", "carol", "dan");

update redcap_crons set cron_frequency = 60, cron_max_run_time = 10 where cron_name = "warn_users_account_suspension_cron";

-- Adjust the cron frequency now!
update redcap_crons set cron_frequency = 60 where cron_id > 34;

-- reset everyone's last login and last activity dates
update redcap_user_information set user_lastlogin = date_add(now(), interval -22 day), user_lastactivity = date_add(now(), interval -10 day) where username='alice';
update redcap_user_information set user_lastlogin = date_add(now(), interval -18 day), user_lastactivity = NULL where username='bob';
update redcap_user_information set user_lastlogin = date_add(now(), interval -10 day), user_lastactivity = date_add(now(), interval -25 day) where username='carol';
update redcap_user_information set user_lastlogin = null, user_lastactivity = date_add(now(), interval -20 day) where username='dan';

-- Verify the above query worked
select * from (
select username, user_email, user_sponsor, user_firstname, user_lastname, user_lastactivity, user_lastlogin,
(case
when user_lastactivity is not null and user_lastlogin is not null then greatest(user_lastlogin, user_lastactivity)
when user_lastactivity is not null then user_lastactivity
when user_lastlogin is not null then user_lastlogin
when user_creation is not null then user_creation
end) as user_last_date
from redcap_user_information
where user_suspended_time is null
) as my_user_info
where 30 - DATEDIFF(NOW(), user_last_date) in (10,12,20);

-- verify the module has a cron job
SELECT * FROM `redcap_crons`
WHERE cron_id > 34
order by cron_id desc;

-- verify the module's config
select * from redcap_external_module_settings
where external_module_id in (
SELECT external_module_id FROM `redcap_external_modules` 
where directory_prefix = 'warn_users_of_pending_suspension');

-- verify the cron history
SELECT * FROM `redcap_crons_history` as ch
inner join redcap_crons as c on (ch.cron_id = c.cron_id)
WHERE c.cron_name = 'warn_users_account_suspension_cron'
order by ch_id desc;
