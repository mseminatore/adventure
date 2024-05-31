# /usr/bin/bash

# clone, build and install dsktools
cd ..
git clone https://github.com/mseminatore/dsktools.git
cd dsktools
make
make install

# clone, build and install as09
cd ..
git clone https://github.com/mseminatore/as09.git
cd as09
make
make install

# build adventure
cd ..
cd adventure
make new
make package
make
