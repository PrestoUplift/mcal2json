# mcal2json

Output a day of your Mac calendar to the command line in JSON.

# Synopsis

mcal2json [integer of days]

# Description

mcal2json is a simple program which reads your local EKEventStore calendar events, organizes them a bit, and outputs them in delicious JSON. At present it only handles a single day at a time, but you can go forward or backwards in time to display any day.

I wrote this program for myself for integration with [Logseq](https://logseq.com). I wanted to get out of having to type in all of my meetings manually into my Journal and any corresponding boilerplate. The approach of pulling things out of the local calendar was appealing as I didn't have to worry about authing to an exchange server. From the output of this I use some Ruby scripts to manage the markdown for Logseq. I went with JSON because it is easy to work with, and if I had wanted to deal with iCal format I could have just rifled around on the filesystem for what I was looking for. With any luck this program solves some other problems for you!

This is the first, and likely only, thing I’ve written in Swift so forgive any noobness. When there was an option between ease of writing vs efficiency, I went with the former - this program probably gets called once a day for most users. I will do my best to accept pull requests, just keep in mind I’m not really interested in being a Swift master so if you wouldn’t mind opting for readability over cleverness I’d be very appreciative.

# Installing

```
make && make install
```

# Wishlist

I don't really have any intention of doing any of the following, but wanted some place to write them down.

[ ] How's about some unit tests?
[ ] Arbitrary Start/End times.
[ ] Less hacky commandline arg parsing
[ ] Properly package for ease of installation and pull in dependencies
[ ] Brew formula?

# Inspiration

Initially I found [iCalBuddy](https://hasseg.org/icalBuddy/) but found the output lacking and the code base way too ancient. The [mcal](https://github.com/0ihsan/mcal) program didn't do what I wanted but I found it useful as a starting point.

# License

MIT

