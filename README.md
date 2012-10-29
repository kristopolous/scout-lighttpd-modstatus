# Introduction

This is a scout-plugin for lighttpd's `mod_status` plugin. It supports at least basic authentication, probably more.

# Configuration

If you don't have it done already, go to (likely to be) `/etc/lighttpd/conf-enabled/` and then create a symbolic link
at least to `10-status.conf` in conf-available directory.  This may be the ticket:

    ln -s ../conf-available/10-status.conf .

You will probably need to edit the `10-status.conf` file too. Uncommenting the `status.status-url` is a great start! Don't forget to restart.

# Authentication

Some people are fans of this.  If you are too, maybe you want to add that. Try this:

    ln -s ../conf-available/05-auth.conf .

Look at that file, the top of it probably tells you where to go for documentation on that feature.  You can
peek there for more info.

# What this does

Well, by now, after exhaustive reading you've probably realized that the "auto" option for these pages look
unmistakeably similar to YAML.  In fact, as far as I can see, it's totally parsable YAML.  

That's really convenient!

Indeed. We can take it and then report the entire casserole back to scout, how wonderful. Life isn't always hard now, is it?
