# aupcmp.sh
bash script to compare two Audacity (old multi-file) projects

This script came to be because I had an on-going recording project with multiple multi-track Audacity projects, many of which were backed up on an external drive with a different disk format from the native operating system format, losing creation date.  Add to that some sloppy backup procedures, and I ended up with some projects in multiple places and no easy way to tell what was the latest edit, or which versions were identical.

This is implemented as a bash script, and makes use of <b>cmp</b> and <b>diff</b>.  First, the <i>.aup</i> files are compared, and if different, the user may elect to view the diff and/or proceed to compare the <i>_data</i> directory of <i>.au</i> files.  If the <i>.aup</i> files are identical, the <i>.au</i> files are compared without prompting. The number and names of the <i>.au</i> files also must match between the two data directories in order for a project to be considered identical.
