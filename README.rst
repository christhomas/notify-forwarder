====================================
 File system notification forwarder
====================================

A simple tool for forwarding file system notifications from one host to another, possibly remapping
the path in the process. Useful when running a reloading build system on one machine and editing
files on another, or over shared folders to a VM.

Supports Linux/inotify and Mac OS X/fsevents on the host side, and Linux, Mac OS X, and BSD on the
client side.


Downloading
===========

Either grab one of the pre-built binaries from the latest release (details
below), or build from source.

Building from source
====================

The project now ships with a multi-target ``Makefile`` that can produce macOS
and Linux binaries for both ``arm64`` and ``x86_64`` architectures.

.. code-block:: sh

   $ git clone git@github.com:mhallin/notify-forwarder.git
   $ cd notify-forwarder
   $ make all

Artifacts are emitted under ``_build/<TargetOS>_<TargetArch>/notify-forwarder``.
For example, ``_build/Darwin_arm64/notify-forwarder``. You can also build a
single target with:

.. code-block:: sh

   $ make darwin_arm64      # macOS arm64
   $ make darwin_x86_64     # macOS x86_64
   $ make linux_arm64       # Linux arm64 (requires Zig for cross-compilation)
   $ make linux_x86_64      # Linux x86_64 (requires Zig for cross-compilation)

On Linux hosts you will need ``zig`` available when building the cross
targets. The GitHub Actions workflow uses ``mlugg/setup-zig`` to install it
during automated builds.


Running
=======

To map the current directory to "/home/user/project" on a remote machine, run the following on the
host side:

.. code-block:: sh

   $ notify-forwarder watch -c <remote-ip> . /home/user/project
   # This maps the current directory "." to "/home/user/project". Add more pairs of paths
   # to watch more folders with different mappings.

And on the client side:

.. code-block:: sh

   $ notify-forwarder receive

The "host side" here being the file system that will send events, i.e. where you run the text
editor. The "client side" is where the auto reloading build system runs.



.. _notify-forwarder_osx_x64: https://github.com/mhallin/notify-forwarder/releases/download/release%2Fv0.1.0/notify-forwarder_osx_x64
.. _notify-forwarder_linux_x64: https://github.com/mhallin/notify-forwarder/releases/download/release%2Fv0.1.0/notify-forwarder_linux_x64
.. _notify-forwarder_freebsd_x64: https://github.com/mhallin/notify-forwarder/releases/download/release%2Fv0.1.0/notify-forwarder_freebsd_x64


Changelog
=========

This changelog highlights recent changes. Earlier versions did not track
changes here.

2025-09-26
----------

- Added a matrix-based GitHub Actions workflow that builds and packages
  binaries for ``darwin_arm64``, ``darwin_x86_64``, ``linux_arm64`` and
  ``linux_x86_64`` and attaches them to tagged releases.
- Refreshed the ``Makefile`` with per-target build rules and Zig-powered
  cross-compilation for Linux architectures.
- Updated the guest-side injector to perform lossless byte rewrites before
  timestamp updates so tools that rely on ``IN_CLOSE_WRITE`` (for example the
  Go Air hot reload tool) react to forwarded events.
- Documented the new build process and artifact layout in this README.
