# Financial Services Cloud Profile

This is a profile for PostgreSQL that meets FS Cloud requirements.
It has been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and meets all applicable goals with the following exception:
- 3000225: Check whether Databases for PostgreSQL network access is restricted to a specific IP range.
    - This is ignored because the CBR locks this down and CRA does not check this

## Note: If no Context Based Restriction(CBR) rules are not passed, you must configure Context Based Restrictions externally to be compliant.
