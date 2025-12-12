# Change Log
All notable changes to the REDCap Warn Users of Pending Suspension project will be documented in this file.

# warn_users_of_pending_suspension 2.0.5 (released 2025-12-12)
- Add VERSION (@pbchase)
- Do not log the event (@pbchase, #24)
- Never set user_lastactivity (@pbchase, #23, #24)
- Add DOI to README (@pbchase, #22)

## [2.0.4] - 2020-02-03
### Changed
- Revise the developer testing instructions (Philip Chase)
- Stop calling ExternalModules class directly to address an issue reported in REDCap 9.6.3 (Kyle Chesney)

### Added
- Add AUTHORS.md (Philip Chase)


## [2.0.3] - 2019-10-01
### Changed
- Ensure project_contact_email is from global scope (Kyle Chesney)
- Correct wording. (Marly Cormar)

### Added
- Allow users to set a custom sender email, defaulting to the admin email (Kyle Chesney)


## [2.0.2] - 2019-08-26
### Added
- Check that the user clicked the homepage. (Marly Cormar)
- log initial login page and myprojects page (Kyle Chesney)


## [2.0.1] - 2019-08-11
### Added
- change the email body to rich text to preview HTML (Kyle Chesney)


## [2.0.0] - 2019-06-24
### Added
- User last login and last activity updated upon visiting homepage (Kyle Chesney)

### Removed
- Removed activation_link and its target (Kyle Chesney)

### Changed
- Add 'REDCap Requirements' and 'How to Implement WUPS and Account Suspensions' to README (Philip Chase)


## [1.0.1] - 2018-06-07
### Changed
- Replace php7 syntax with php5.3 syntax. (Philip Chase)

## [1.0.0] - 2018-06-07
### Summary
 - This is the first release of REDCap Warn Users of Pending Suspension
