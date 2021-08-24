# Auto mark issues as stale
This is an Action that labels expired issues based on the provided label, based on [bdougie/close-issues-based-on-label](https://github.com/bdougie/close-issues-based-on-label).

## Usage

This action takes four parameters via environment variables.

* `LABEL` (string, default = `stale`): The name of a label for stale issues.
* `EXPIRE_DAYS` (integer, default = `0`): The number of days waiting to mark issues after the last comment done by the reporter.
* `EXTEND_DAYS_BY_COMMENTED` (integer, default = same to `EXPIRE_DAYS`): The number of days waiting to mark issues after last commented by someone.
* `CANDIDATE_LABELS` (commma separated strings): Names of labels which filter issues to be marked as stale.
* `GITHUB_TOKEN (string): This must be `${{ secrets.GITHUB_TOKEN }}`.

For example:

```yml
on:
  schedule:
  - cron: 0 5 * * 3 
name: Weekly Expired Issue Closure
jobs:
  cycle-weekly-close:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: mark "help wanted" issues as stale
      uses: piroor/auto-mark-as-stale-issues
      env:
        LABEL: stale
        CANDIDATE_LABELS: help wanted
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        EXPIRE_DAYS: 30
        EXTEND_DAYS_BY_COMMENTED: 7
        COMMENT: This issue has been labeled as "stale" due to no response by the reporter within 30 days (and 7 days after the last commented by someone).
```
