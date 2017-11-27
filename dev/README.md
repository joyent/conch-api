Contains tools and scripts and what not to stand up a dev environment. DO NOT
USE THIS IN PROD!

No really, never use this in prod.

If you run `make`, the following "great for dev but HORRIBLE for prod things
will happen". (Seriously don't run this in prod.)

* If the node and perl dependencies in ../Conch have not be installed, they will
  be
* The database *will be silently blown away and recreated*
* A dummy admin user named `conch` will be created with the *ultra-secure*
  password of 'conch'

