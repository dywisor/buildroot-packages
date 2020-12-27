.. _buildroot:
   http://buildroot.org/

====================
 buildroot-packages
====================

A buildroot addon repository containing packages of *experimental quality*.

Rather than cloning the buildroot_ repo and adding packages to that specific
copy - and maintaining the newly formed *fork* -,
only the actual packages are distributed and need to be attached to a
*buildroot source directory* by means of symlinking.


Setup Instructions
==================

Get a copy of both this repo and a buildroot tree::

   mkdir -p -- ~/src

   git clone git://git.buildroot.net/buildroot ~/src/buildroot
   # or clone any custom tree

   git clone git://github.com/dywisor/buildroot-packages ~/src/buildroot-packages


Now, simply install *buildroot-packages* to the *buildroot source directory*::

   make -C ~/src/buildroot-packages BR=~/src/buildroot install


This sets up symlinks and adds a single line to ``$BR/package/Config.in``
that sources *buildroot-packages'* ``Config.in`` file.

The packages can then be found in::

   +- Target Packages  --->
   |  +- dywi/buildroot-packages [external repo]  --->


When updating the *buildroot source* tree,
it might be necessary to undo the installation.

Either remove the ``source .../Config.in`` line
from ``$BR/package/Config.in``::

   make -C ~/src/buildroot-packages BR=~/src/buildroot unregister-config

or remove *buildroot-packages* completely::

   make -C ~/src/buildroot-packages BR=~/src/buildroot uninstall

and readd it (-> ``register-config`` or ``install``) afterwards.


Design Overview
===============

*buildroot-packages*::

   +- buildroot-packages/
   |  +- GNUmakefile
   |  +- br_pkg_repo/
   |     +- br_pkg_repo.mk
   |     +- br_pkg_repo_gen.mk
   |     +- GNUmakefile.skel
   |  +- package/
   |     +- Config.in
   |     +- @null/ [NOT IMPLEMENTED]
   |        +- Config.in [empty]
   |        +- @null.mk [empty] (??)
   |     +- <package>/
   |        +- <package>.mk
   |        +- Config.in
   |        +- README or PKG_NOTES (optional)
   |        +- ...
   |     +- ...


* the ``GNUmakefile`` takes care of attaching the repo to and removing it from
  a *buildroot source dir*

* ``br_pkg_repo/`` provides the necessary logic for that

* ``package/`` contains an arbitrary number of ``<package>`` subdirectories,
  as if they were put in the *buildroot source dir's* ``package/`` dir directly

* ``package/@null`` is a special package that can be used to hide packages
  in the *buildroot source dir* without having to edit ``Config.in``.
  -- **not implemented** --


* ``package/Config.in`` is responsible for loading
  ``package/<package>/Config.in`` files into the repository's config menu

  .. code:: text

     menu "<human readable repo identifier> [external repo]"

        source package/<package-0>/Config.in
        ...
        source package/<package-N>/Config.in

     endmenu

  which then appears in buildroot's config as

  .. code:: text

     +- Target Packages  --->
     |  +- <humand readable repo identifier> [external repo]  --->


  The *human readable repo identifier* can be chosen freely,
  this repo uses ``<nickname>/<gitrepo name>``.


When installed to a *buildroot source dir*::

   +- buildroot-src/
   |  +- package/
   |  +- Config.in [edited]
   |  +- <repo ident>/   -> buildroot-packages/package (symlink to abspath)
   |  +- <repo package>/ -> <repo ident>/<package>     (symlink to relpath)

* ``repo ident`` must be a unique filename (must not contain ``/``),
  e.g. ``<nickname>__<gitrepo name>``

* ``buildroot-src/package/<repo ident>`` is an *absolute* symlink
  pointing to ``buildroot-packages``

* each ``<package>`` is added to the ``buildroot-src/package`` dir as
  *relative* symlink and points to either ``<repo ident>/<package>``
  or ``<repo ident>/@null`` (hidden package)

* ``package/Config.in`` loads the repo-specific config menu
  (``<repo ident>/Config.in``)

* the ``buildroot-packages`` directory is readonly for ``buildroot-src``


Note that ``<repo ident>/Config.in`` sources ``package/<package>/Config.in``
and not ``package/<repo ident>/<package>/Config.in``.
This allows to handle collisions if a package is provided by the upstream tree
or another repo and to hide packages by linking them to the ``@null`` package.
-- collision handling is **not implemented** --


To create a custom repository based on this design::

   mkdir -p ~/src/my-br-pkg/package
   cd ~/src/my-br-pkg

   # Import package repo files
   cp -R ~/src/buildroot-packages/br_pkg_repo ./br_pkg_repo

   # Start with default makefile and set REPO_NAME
   cp ./br_pkg_repo/GNUmakefile.skel ./GNUmakefile
   $EDITOR ./GNUmakefile

   # skip cp: NOT IMPLEMENTED
   #cp -R ~/src/buildroot-packages/package/@null ./package/@null

   # Create Config.in
   $EDITOR ./package/Config.in

   # Alternatively, enable "br_pkg_repo_gen.mk" in GNUmakefile
   # and use "make repo-update-config"
