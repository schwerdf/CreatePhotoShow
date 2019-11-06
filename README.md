### Description ###

"CreatePhotoShow" is a macOS application meant to assist in creating
photo shows.

It was designed for the use of a camera group hosting salon events to
which any attendee could bring photos to show on a walk-in basis.
Since attendance at the salons varied widely, the challenge became
how, within the space of a minute or two, to assemble a slideshow with
a sufficient but manageable number of photos, while ensuring that
everyone who came could show one.

The solution decided on was a sliding upper limit on the number of
photos people could show; if only three people brought photos, each
one could show 15, but if 30 people showed up, each person would be
limited to three or four.

This application was implemented to automate the process of photo
intake and arrangement for these slideshows. Its "Get Photos" dialog
allows quick copying of photos from different sources into one chosen
folder, prefixing the photographer's initials to each file to keep
tally.

Then, when all the photos are collected, one can view in a list all
the possible values for the sliding limit, with the resulting total
number of photos for each.

Once the limit _n_ is selected, the application will create a
subfolder _n_`per-Display` within the chosen folder, and populate it
with symbolic links to the first _n_ images (taken in alphabetical
filename order) from each photographer. The _n_`per-Display` folder
can then be opened in a slideshow application such as
[Phoenix Slides](http://blyt.net/phxslides/).
