This folder should normally remain empty, but just in case there's a hot fix for a major vulnerability the hotfix can be applied in the folder

run-parts will be executed to apply any hotfixes in the folder so hotfixes should be in the form of a shellscript named after the relevant cve with no extension.
IE the recent log4j would have a shell script named `cve-2021-44228` containing the fix. Then to verify the hotfix applied before launching you could also add a md5sum
file with the name `cve-2021-44228-validate.md5sum`. The docker-entrypoint.sh will not let execution proceed without those md5sums passing.
